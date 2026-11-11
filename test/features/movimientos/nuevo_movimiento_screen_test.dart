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

Map<String, Object?> categoriaJson(
  int id,
  String codigo,
  String nombre, {
  String? tipo,
}) => <String, Object?>{
  'id': id,
  'codigo': codigo,
  'nombre': nombre,
  'tipoPresupuesto': ?tipo,
};

ResponseBody categoriasResponse() => jsonResponse(<Object?>[
  categoriaJson(
    1,
    'ALIMENTACION_BASE',
    'Alimentación Básica',
    tipo: 'NECESIDAD',
  ),
  categoriaJson(2, 'OCIO_RECREACION', 'Ocio y Recreación', tipo: 'DESEO'),
  categoriaJson(3, 'SUELDO', 'Sueldo', tipo: 'OTROS'),
  categoriaJson(4, 'AHORRO', 'Ahorro y Fondo de Reserva', tipo: 'AHORRO'),
  categoriaJson(5, 'OTROS', 'Otros', tipo: 'OTROS'),
  categoriaJson(
    17,
    'REGALOS_CELEBRACIONES',
    'Regalos y Celebraciones',
    tipo: 'DESEO',
  ),
]);

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenStore = InMemoryTokenStore();
    tokenStore.save(token: 'jwt.vigente', refreshToken: 'refresh.vigente');
  });

  /// Handler base del home (versión, perfil, saldo, página, catálogo).
  ResponseBody? baseGet(RequestOptions options) {
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
    if (options.path.endsWith('/categorias')) {
      return categoriasResponse();
    }
    return null;
  }

  Future<void> abrirAlta(WidgetTester tester) async {
    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nuevo movimiento'));
    await tester.pumpAndSettle();
    expect(find.text('Descripción'), findsOneWidget);
  }

  Future<void> escribirDescripcion(
    WidgetTester tester,
    String texto,
  ) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción'),
      texto,
    );
    // Debounce de 400 ms + respuesta.
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pumpAndSettle();
  }

  testWidgets('ambigua: no preselecciona hasta elegir y guarda el chip', (
    WidgetTester tester,
  ) async {
    adapter.handler = (RequestOptions options) async {
      final ResponseBody? base = baseGet(options);
      if (base != null) {
        return base;
      }
      if (options.path.endsWith('/categorias/sugerencia')) {
        expect(options.queryParameters['texto'], 'cena aniversario');
        expect(options.queryParameters['contexto'], 'GASTO');
        return jsonResponse(<String, Object?>{
          'texto': 'cena aniversario',
          'sugerencias': <Object?>[
            <String, Object?>{
              'categoriaId': 17,
              'codigo': 'REGALOS_CELEBRACIONES',
              'nombre': 'Regalos y Celebraciones',
              'confianza': 0.9,
              'motivo': 'PALABRA_CLAVE',
            },
            <String, Object?>{
              'categoriaId': 1,
              'codigo': 'ALIMENTACION_BASE',
              'nombre': 'Alimentación Básica',
              'confianza': 0.9,
              'motivo': 'PALABRA_CLAVE',
            },
          ],
          'ambigua': true,
        });
      }
      if (options.path.endsWith('/movimientos') && options.method == 'POST') {
        expect(jsonBodyOf(options), <String, Object?>{
          'monto': 12500,
          'descripcion': 'cena aniversario',
          'tipoMovimiento': 'GASTO_GENERAL',
          'categoriaId': 1,
        });
        return jsonResponse(<String, Object?>{
          'id': 99,
          'monto': -12500,
          'descripcion': 'cena aniversario',
          'fecha': '2026-11-06T16:30:00.000Z',
          'tipoMovimiento': 'GASTO_GENERAL',
        });
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await abrirAlta(tester);
    await escribirDescripcion(tester, 'cena aniversario');

    // Mensaje de ambigüedad y chips visibles; sin selección automática.
    expect(
      find.textContaining('más de una categoría posible'),
      findsOneWidget,
    );
    expect(find.text('Regalos y Celebraciones'), findsOneWidget);

    // Elección explícita del segundo chip.
    await tester.tap(find.text('Alimentación Básica'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monto'),
      '12500',
    );
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    // Volvió al home y refrescó saldo/listado.
    expect(find.text('Saldo disponible'), findsOneWidget);
  });

  testWidgets('sugerencia no ambigua preselecciona la primera categoría', (
    WidgetTester tester,
  ) async {
    adapter.handler = (RequestOptions options) async {
      final ResponseBody? base = baseGet(options);
      if (base != null) {
        return base;
      }
      if (options.path.endsWith('/categorias/sugerencia')) {
        return jsonResponse(<String, Object?>{
          'texto': 'supermercado',
          'sugerencias': <Object?>[
            <String, Object?>{
              'categoriaId': 1,
              'codigo': 'ALIMENTACION_BASE',
              'nombre': 'Alimentación Básica',
              'confianza': 1.0,
              'motivo': 'PALABRA_CLAVE',
            },
          ],
          'ambigua': false,
        });
      }
      if (options.path.endsWith('/movimientos') && options.method == 'POST') {
        expect(jsonBodyOf(options)['categoriaId'], 1);
        return jsonResponse(<String, Object?>{
          'id': 100,
          'monto': -8000,
          'descripcion': 'supermercado',
          'fecha': '2026-11-06T16:31:00.000Z',
          'tipoMovimiento': 'GASTO_GENERAL',
        });
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await abrirAlta(tester);
    await escribirDescripcion(tester, 'supermercado');

    expect(
      find.textContaining('puedes cambiarla'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monto'),
      '8000',
    );
    await tester.tap(find.text('Guardar movimiento'));
    await tester.pumpAndSettle();

    expect(find.text('Saldo disponible'), findsOneWidget);
  });

  testWidgets('el selector de gasto agrupa y oculta Sueldo/Ahorro', (
    WidgetTester tester,
  ) async {
    adapter.handler = (RequestOptions options) async {
      final ResponseBody? base = baseGet(options);
      if (base != null) {
        return base;
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await abrirAlta(tester);
    await tester.tap(find.text('Elegir categoría'));
    await tester.pumpAndSettle();

    expect(find.text('TODAS LAS CATEGORÍAS'), findsOneWidget);
    expect(find.text('Necesidades'), findsOneWidget);
    expect(find.text('Deseos'), findsOneWidget);
    expect(find.byIcon(Icons.fastfood), findsWidgets);
    expect(find.text('Sueldo'), findsNothing);
    expect(find.text('Ahorro y Fondo de Reserva'), findsNothing);

    await tester.tap(find.text('Alimentación Básica'));
    await tester.pumpAndSettle();

    expect(find.text('Alimentación Básica'), findsOneWidget);
  });

  testWidgets('un ingreso solo ofrece categorías de ingreso', (
    WidgetTester tester,
  ) async {
    adapter.handler = (RequestOptions options) async {
      final ResponseBody? base = baseGet(options);
      if (base != null) {
        return base;
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await abrirAlta(tester);
    await tester.tap(find.text('Gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ingreso').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elegir categoría'));
    await tester.pumpAndSettle();

    expect(find.text('CATEGORÍAS DE INGRESO'), findsOneWidget);
    expect(find.text('Sueldo'), findsOneWidget);
    expect(find.text('Otros'), findsOneWidget);
    expect(find.byIcon(Icons.work_outline), findsWidgets);
    expect(find.byIcon(Icons.label_outline), findsWidgets);
    expect(find.text('Alimentación Básica'), findsNothing);
  });
}
