import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/session_events.dart';
import 'package:saveup_app/core/network/token_store.dart';

import '../support/fake_http_adapter.dart';
import '../support/test_app.dart';

Map<String, Object?> meBody() => <String, Object?>{
  'rut': '12345678-5',
  'nombre': 'Ana',
  'apellido': 'Primerahija',
  'email': 'ana@example.cl',
  'fechaRegistro': '2026-01-15T10:30:00.000Z',
};

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenStore = InMemoryTokenStore();
  });

  testWidgets('sin sesión: splash → login', (WidgetTester tester) async {
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsWidgets);
  });

  testWidgets('actualización obligatoria bloquea el acceso', (
    WidgetTester tester,
  ) async {
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return jsonResponse(<String, Object?>{
          'actualizacionObligatoria': true,
          'actualizacionSugerida': false,
          'mensaje': 'Tu versión está desactualizada.',
          'urlTienda': 'https://play.google.com/apps',
          'versionTerminos': 'v1.2',
          'versionPrivacidad': 'v1',
        });
      }
      fail('con bloqueo no debió pedirse: ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();

    expect(find.text('Actualización requerida'), findsOneWidget);
    expect(find.text('Tu versión está desactualizada.'), findsOneWidget);
    // Ninguna llamada de casos de uso: solo la consulta de versión.
    expect(
      adapter.requests.where(
        (RequestOptions r) => !r.path.endsWith('/app/version'),
      ),
      isEmpty,
    );
  });

  testWidgets('actualización sugerida muestra aviso descartable en login', (
    WidgetTester tester,
  ) async {
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return jsonResponse(<String, Object?>{
          'actualizacionObligatoria': false,
          'actualizacionSugerida': true,
          'mensaje': 'Hay una versión nueva.',
          'urlTienda': 'https://play.google.com/apps',
          'versionTerminos': 'v1.2',
          'versionPrivacidad': 'v1',
        });
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();

    expect(find.text('Hay una versión nueva.'), findsOneWidget);
    expect(find.text('Más tarde'), findsOneWidget);
  });

  testWidgets('con sesión válida: splash → home con saldo', (
    WidgetTester tester,
  ) async {
    await tokenStore.save(token: 'jwt.abc', refreshToken: 'refresh.xyz');
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/saldos/me')) {
        return saldoResponse();
      }
      if (options.path.endsWith('/movimientos/paginados/me')) {
        return paginaVaciaResponse();
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();

    // El home real muestra la tarjeta de saldo y el listado (vacío aquí).
    expect(find.text('Saldo disponible'), findsOneWidget);
    expect(find.text('No hay movimientos para estos filtros.'), findsOneWidget);
  });

  testWidgets('evento "sesión expirada" va al login con aviso', (
    WidgetTester tester,
  ) async {
    final SessionEvents events = SessionEvents();
    await tokenStore.save(token: 'jwt.abc', refreshToken: 'refresh.xyz');
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/saldos/me')) {
        return saldoResponse();
      }
      if (options.path.endsWith('/movimientos/paginados/me')) {
        return paginaVaciaResponse();
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.pumpWidget(
      testApp(adapter: adapter, tokenStore: tokenStore, sessionEvents: events),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saldo disponible'), findsOneWidget);

    // El interceptor avisó: venció la sesión.
    events.emitExpired();
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsWidgets);
    expect(
      find.text('Tu sesión expiró. Inicia sesión nuevamente.'),
      findsOneWidget,
    );
  });

  testWidgets('ruta privada sin sesión no es accesible directamente', (
    WidgetTester tester,
  ) async {
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();

    // La ruta de login es la única accesible sin sesión.
    expect(find.text('Inicia sesión'), findsWidgets);
    expect(find.text('Saldo disponible'), findsNothing);
  });

  testWidgets('login exitoso: /usuarios/login → home', (
    WidgetTester tester,
  ) async {
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/login')) {
        return jsonResponse(<String, Object?>{
          'token': 'jwt.nuevo',
          'refreshToken': 'refresh.nuevo',
          'expiraEn': '2026-11-06T15:00:00.000Z',
        });
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/saldos/me')) {
        return saldoResponse();
      }
      if (options.path.endsWith('/movimientos/paginados/me')) {
        return paginaVaciaResponse();
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    expect(find.text('Inicia sesión'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@example.cl',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'contrasena1',
    );
    final Finder boton = find.widgetWithText(FilledButton, 'Iniciar sesión');
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();

    // El router debe reaccionar a la sesión autenticada y llevar a home.
    expect(find.text('Saldo disponible'), findsOneWidget);
    // Los tokens quedaron guardados para la próxima sesión.
    final AuthTokens? tokens = await tokenStore.read();
    expect(tokens?.refreshToken, 'refresh.nuevo');
  });
}
