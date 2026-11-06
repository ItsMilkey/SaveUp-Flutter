import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/token_store.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/test_app.dart';

/// Handler del arranque: versión al día y sin sesión → login.
Future<ResponseBody> Function(RequestOptions)
comienzoSinSesion() => (RequestOptions options) async {
  if (options.path.endsWith('/app/version')) {
    return versionResponse();
  }
  fail('petición inesperada: ${options.path}');
};

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenStore = InMemoryTokenStore();
  });

  /// Arranca en login y navega a la solicitud de recuperación.
  Future<void> abrirSolicitud(WidgetTester tester) async {
    adapter.handler = comienzoSinSesion();
    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el aviso del envío pendiente desde login', (
    WidgetTester tester,
  ) async {
    await abrirSolicitud(tester);

    expect(
      find.textContaining('pendiente de activación en el servidor'),
      findsOneWidget,
    );
  });

  testWidgets('correo inválido no envía petición', (
    WidgetTester tester,
  ) async {
    await abrirSolicitud(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'no-es-un-correo',
    );
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    expect(
      adapter.requests.where(
        (RequestOptions r) => r.path.endsWith('/auth/recuperar-contrasena'),
      ),
      isEmpty,
    );
  });

  testWidgets('solicitud 200 → formulario del token con mensaje genérico', (
    WidgetTester tester,
  ) async {
    await abrirSolicitud(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@example.cl',
    );
    // Respuesta genérica: anti-enumeración, no se sabe si el correo existe.
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/auth/recuperar-contrasena')) {
        return jsonResponse(
          <String, Object?>{'message': 'Si el correo está registrado.'},
        );
      }
      fail('petición inesperada: ${options.path}');
    };

    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    // Estamos en el formulario del token, con instrucciones claras.
    expect(
      find.textContaining('Si la cuenta existe, se generó la instrucción'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Token'), findsOneWidget);
  });

  testWidgets('restablecimiento exitoso: 200 → login con aviso y tokens borrados', (
    WidgetTester tester,
  ) async {
    await abrirSolicitud(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@example.cl',
    );
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/auth/recuperar-contrasena')) {
        return jsonResponse(<String, Object?>{'message': 'ok'});
      }
      if (options.path.endsWith('/auth/restablecer-contrasena')) {
        expect(jsonBodyOf(options), <String, Object?>{
          'token': 'token-de-correo',
          'nuevaContrasena': 'contrasena2',
        });
        return jsonResponse(<String, Object?>{'message': 'ok'});
      }
      fail('petición inesperada: ${options.path}');
    };
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Token'),
      'token-de-correo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'contrasena2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      'contrasena2',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restablecer contraseña'));
    await tester.pumpAndSettle();

    // Login con el aviso precargado y el correo del paso 1.
    expect(
      find.text('Contraseña restablecida con éxito. Ingresa con tu nueva clave.'),
      findsOneWidget,
    );
    expect(find.text('ana@example.cl'), findsOneWidget);
    // El token store no tenía nada y sigue vacío.
    expect(await tokenStore.read(), isNull);
  });

  testWidgets('token inválido va inline al campo y ofrece re-solicitar', (
    WidgetTester tester,
  ) async {
    await abrirSolicitud(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@example.cl',
    );
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/auth/recuperar-contrasena')) {
        return jsonResponse(<String, Object?>{'message': 'ok'});
      }
      if (options.path.endsWith('/auth/restablecer-contrasena')) {
        return problemResponse('TOKEN_VERIFICACION_INVALIDO', statusCode: 400);
      }
      fail('petición inesperada: ${options.path}');
    };
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Token'),
      'token-vencido',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'contrasena2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      'contrasena2',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restablecer contraseña'));
    await tester.pumpAndSettle();

    // Error inline sobre el campo token (no un banner global)…
    expect(
      find.text('El token no es válido o ya expiró. Solicita uno nuevo.'),
      findsOneWidget,
    );
    // …y vía de regreso al paso 1.
    expect(find.text('Solicitar uno nuevo'), findsOneWidget);
    await tester.tap(find.text('Solicitar uno nuevo'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar solicitud'), findsOneWidget);
  });

  testWidgets('contraseñas nuevas distintas no envían petición', (
    WidgetTester tester,
  ) async {
    await abrirSolicitud(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@example.cl',
    );
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      if (options.path.endsWith('/auth/recuperar-contrasena')) {
        return jsonResponse(<String, Object?>{'message': 'ok'});
      }
      fail('petición inesperada: ${options.path}');
    };
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Token'),
      'token-de-correo',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña nueva'),
      'contrasena2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repite la contraseña nueva'),
      'contrasena3',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restablecer contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(
      adapter.requests.where(
        (RequestOptions r) => r.path.endsWith('/auth/restablecer-contrasena'),
      ),
      isEmpty,
    );
  });
}
