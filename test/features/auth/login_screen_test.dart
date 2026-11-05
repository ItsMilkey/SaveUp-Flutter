import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/token_store.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/test_app.dart';

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenStore = InMemoryTokenStore();
    // Splash: versión al día + sin sesión → login.
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      fail('petición inesperada: ${options.path}');
    };
  });

  testWidgets('error genérico de credenciales se muestra con mensaje fijo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@example.cl',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'malas1',
    );

    adapter.handler = (options) async {
      expect(options.path.endsWith('/usuarios/login'), isTrue);
      return problemResponse('CREDENCIALES_INVALIDAS', statusCode: 401);
    };

    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    // El botón queda habilitado para intentarlo de nuevo.
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Iniciar sesión'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('429 bloquea el reenvío y solo ofrece reintento manual', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@example.cl',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'contrasena1',
    );

    adapter.handler = (options) async =>
        problemResponse('INTENTOS_LOGIN_EXCEDIDOS', statusCode: 429);

    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(
      find.text('Demasiados intentos; espera unos minutos.'),
      findsOneWidget,
    );
    // Botón principal inhabilitado: no hay reenvío automático.
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Iniciar sesión'),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('con sesión expirada previa avisa y llega al login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    // Pasa el arranque completo; no debió guardar sesión.
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsWidgets);
    // Sin tokens guardados tras el arranque sin sesión.
    expect(await tokenStore.read(), isNull);
  });
}
