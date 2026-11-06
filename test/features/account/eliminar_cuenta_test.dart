import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/token_store.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/test_app.dart';

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
    tokenStore.save(token: 'jwt.vigente', refreshToken: 'refresh.vigente');
  });

  /// Arranca autenticado y abre el diálogo (paso 1: advertencia).
  Future<void> abrirDialogo(WidgetTester tester) async {
    adapter.handler = (RequestOptions options) async {
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
    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();
  }

  /// Pasa del paso 1 (advertencia) al 2 (confirmación por contraseña).
  Future<void> irAPasoConfirmacion(WidgetTester tester) async {
    expect(
      find.textContaining('se eliminarán de forma permanente'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Eliminar mi cuenta definitivamente'),
      findsOneWidget,
    );
  }

  testWidgets('diálogo en dos pasos: advertencia y confirmación', (
    WidgetTester tester,
  ) async {
    await abrirDialogo(tester);
    await irAPasoConfirmacion(tester);
    // Aún no hay petición: la confirmación por contraseña es obligatoria.
    expect(
      adapter.requests.where(
        (RequestOptions r) => r.path.endsWith('/usuarios/me'),
      ),
      hasLength(1), // solo GET /usuarios/me del arranque
    );
  });

  testWidgets('cancelar cierra el diálogo sin enviar nada', (
    WidgetTester tester,
  ) async {
    await abrirDialogo(tester);
    await irAPasoConfirmacion(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'contrasena1',
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // De vuelta al home, con el diálogo cerrado.
    expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
    expect(find.text('Saldo disponible'), findsOneWidget);
    expect(
      adapter.requests.where(
        (RequestOptions r) =>
            r.method == 'DELETE' && r.path.endsWith('/usuarios/me'),
      ),
      isEmpty,
    );
    expect(await tokenStore.read(), isNotNull);
  });

  testWidgets('CREDENCIALES_INVALIDAS: inline en el campo y diálogo abierto', (
    WidgetTester tester,
  ) async {
    await abrirDialogo(tester);
    await irAPasoConfirmacion(tester);
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me') && options.method == 'GET') {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/usuarios/me') && options.method == 'DELETE') {
        return problemResponse('CREDENCIALES_INVALIDAS', statusCode: 401);
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'otra-clave',
    );
    await tester.tap(find.text('Eliminar mi cuenta definitivamente'));
    await tester.pumpAndSettle();

    // Error inline sobre el input, dentro del diálogo abierto.
    expect(find.text('La contraseña no es correcta.'), findsOneWidget);
    expect(find.text('Eliminar mi cuenta definitivamente'), findsOneWidget);

    // Reintentar desde el mismo botón: sigue viendo el error y la sesión
    // no se tocó.
    await tester.tap(find.text('Eliminar mi cuenta definitivamente'));
    await tester.pumpAndSettle();
    expect(find.text('La contraseña no es correcta.'), findsOneWidget);
    expect(await tokenStore.read(), isNotNull);
  });

  testWidgets('éxito 204: tokens borrados, diálogo cerrado y aviso en /login', (
    WidgetTester tester,
  ) async {
    await abrirDialogo(tester);
    await irAPasoConfirmacion(tester);
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me') && options.method == 'GET') {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/usuarios/me') && options.method == 'DELETE') {
        expect(jsonBodyOf(options), <String, Object?>{
          'contrasena': 'contrasena1',
        });
        return ResponseBody.fromString('', 204);
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'contrasena1',
    );
    await tester.tap(find.text('Eliminar mi cuenta definitivamente'));
    await tester.pumpAndSettle();

    // El diálogo se cerró y el router llevó a /login con el aviso.
    expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
    expect(
      find.text('Tu cuenta ha sido eliminada permanentemente.'),
      findsOneWidget,
    );
    expect(find.text('ana@example.cl'), findsOneWidget);
    expect(await tokenStore.read(), isNull);
  });
}
