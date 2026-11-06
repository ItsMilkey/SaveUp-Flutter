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

  /// Arranca la app ya autenticada y navega al formulario de cambio.
  Future<void> abrirFormulario(WidgetTester tester) async {
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    // Home con sesión: entrada al formulario de cambio.
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();
    expect(find.text('Contraseña actual'), findsOneWidget);
  }

  Future<void> completarFormulario(
    WidgetTester tester, {
    String actual = 'contrasena1',
    String nueva = 'contrasena2',
    String repetida = 'contrasena2',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña actual'),
      actual,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      nueva,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      repetida,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('flujo completo: 200 → tokens borrados y aviso en /login', (
    WidgetTester tester,
  ) async {
    await abrirFormulario(tester);
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/usuarios/me/contrasena')) {
        // El backend revoca todas las sesiones y responde 200 {message}.
        expect(jsonBodyOf(options), <String, Object?>{
          'contrasenaActual': 'contrasena1',
          'nuevaContrasena': 'contrasena2',
        });
        return jsonResponse(
          <String, Object?>{'message': 'Contraseña actualizada.'},
        );
      }
      fail('petición inesperada: ${options.path}');
    };

    await completarFormulario(tester);
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pumpAndSettle();

    // Volvió al login con el aviso precargado y el correo precargado.
    expect(find.text('Contraseña actualizada correctamente. Por seguridad, '
            'inicia sesión nuevamente.'),
        findsOneWidget);
    expect(find.text('ana@example.cl'), findsOneWidget);
    expect(find.text('Inicia sesión'), findsWidgets);

    // La sesión local se cerró: TokenStore vacío.
    expect(await tokenStore.read(), isNull);
  });

  testWidgets('CREDENCIALES_INVALIDAS marca el campo actual y no cierra sesión', (
    WidgetTester tester,
  ) async {
    await abrirFormulario(tester);
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/usuarios/me/contrasena')) {
        return problemResponse('CREDENCIALES_INVALIDAS', statusCode: 401);
      }
      fail('petición inesperada: ${options.path}');
    };

    await completarFormulario(tester);
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pumpAndSettle();

    // Error inline sobre el campo "Contraseña actual".
    expect(find.text('La contraseña actual no es correcta.'), findsOneWidget);
    // La sesión sigue: el TokenStore conserva los tokens.
    expect(await tokenStore.read(), isNotNull);
  });

  testWidgets('VALIDACION_FALLIDA reparte errores por campo', (
    WidgetTester tester,
  ) async {
    await abrirFormulario(tester);
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/usuarios/me')) {
        return jsonResponse(meBody());
      }
      if (options.path.endsWith('/usuarios/me/contrasena')) {
        return problemResponse(
          'VALIDACION_FALLIDA',
          errores: <Map<String, String>>[
            <String, String>{
              'campo': 'nuevaContrasena',
              'mensaje': 'la nueva contraseña no cumple la política',
            },
          ],
        );
      }
      fail('petición inesperada: ${options.path}');
    };

    await completarFormulario(tester);
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pumpAndSettle();

    expect(
      find.text('la nueva contraseña no cumple la política'),
      findsOneWidget,
    );
    expect(await tokenStore.read(), isNotNull);
  });

  testWidgets('contraseñas nuevas distintas no envían petición', (
    WidgetTester tester,
  ) async {
    await abrirFormulario(tester);

    await completarFormulario(
      tester,
      nueva: 'contrasena2',
      repetida: 'contrasena3',
    );
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(
      adapter.requests.where(
        (RequestOptions r) => r.path.endsWith('/usuarios/me/contrasena'),
      ),
      isEmpty,
    );
  });

  testWidgets('nueva contraseña inválida (sin número) no envía petición', (
    WidgetTester tester,
  ) async {
    await abrirFormulario(tester);

    await completarFormulario(tester, nueva: 'contrasenaviva', repetida: 'contrasenaviva');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar nueva contraseña'));
    await tester.pumpAndSettle();

    expect(
      find.text('La contraseña debe incluir al menos una letra y un número.'),
      findsOneWidget,
    );
    expect(
      adapter.requests.where(
        (RequestOptions r) => r.path.endsWith('/usuarios/me/contrasena'),
      ),
      isEmpty,
    );
  });
}
