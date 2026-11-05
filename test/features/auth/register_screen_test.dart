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
    adapter.handler = (options) async {
      if (options.path.endsWith('/app/version')) {
        return versionResponse();
      }
      fail('petición inesperada: ${options.path}');
    };
  });

  Future<void> abrirRegistro(WidgetTester tester) async {
    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¿No tienes cuenta? Crea una aquí'));
    await tester.pumpAndSettle();

    // formulario completo
    await tester.enterText(
      find.widgetWithText(TextFormField, 'RUT'),
      '12345678-5',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Ana');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Apellido'),
      'Primerahija',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@example.cl',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'contrasena1',
    );
  }

  testWidgets('VALIDACION_FALLIDA muestra el error junto a cada campo', (
    WidgetTester tester,
  ) async {
    await abrirRegistro(tester);

    adapter.handler = (options) async {
      expect(options.path.endsWith('/usuarios/register'), isTrue);
      return problemResponse(
        'VALIDACION_FALLIDA',
        errores: <Map<String, String>>[
          <String, String>{'campo': 'email', 'mensaje': 'el correo no vale'},
          <String, String>{
            'campo': 'contrasena',
            'mensaje': 'la contraseña no cumple',
          },
        ],
      );
    };

    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('el correo no vale'), findsOneWidget);
    expect(find.text('la contraseña no cumple'), findsOneWidget);
    // El registro no guarda tokens: la persona debe hacer login.
    expect(await tokenStore.read(), isNull);
  });

  testWidgets('USUARIO_YA_REGISTRADO sugiere ir al login', (
    WidgetTester tester,
  ) async {
    await abrirRegistro(tester);

    adapter.handler = (options) async =>
        problemResponse('USUARIO_YA_REGISTRADO', statusCode: 409);

    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Ya existe una cuenta con esos datos'),
      findsOneWidget,
    );
    expect(find.text('Ya tengo cuenta'), findsOneWidget);
  });

  testWidgets('éxito precarga el correo y llega al login con aviso', (
    WidgetTester tester,
  ) async {
    await abrirRegistro(tester);

    adapter.handler = (options) async =>
        jsonResponse(<String, Object?>{'message': 'Cuenta creada'});

    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cuenta creada'), findsOneWidget);
    expect(find.text('ana@example.cl'), findsOneWidget);
    expect(await tokenStore.read(), isNull);
  });
}
