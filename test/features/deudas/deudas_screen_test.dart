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

Map<String, Object?> deudaJson({
  int id = 1,
  String nombre = 'Crédito de consumo',
  num montoPagadoReal = 0,
  int cuotasPagadas = 0,
  String estado = 'PENDIENTE',
}) => <String, Object?>{
  'id': id,
  'nombre': nombre,
  'descripcion': 'Cuota del banco',
  'tipoDeuda': 'PERSONAL',
  'modalidadCalculo': 'TASA_CONOCIDA',
  'estado': estado,
  'montoCapital': 500000.00,
  'tasaMensual': 1.5,
  'tasaAnualEfectiva': 19.56,
  'valorCuota': 45000.00,
  'gastosIniciales': 0.00,
  'costoAdicionalPorCuota': 0.00,
  'costoTotalCredito': 540000.00,
  'cargaAnualEquivalente': 21.00,
  'fechaPrimeraCuota': '2026-12-01',
  'fechaUltimaCuota': '2027-11-01',
  'fechaCreacion': '2026-11-01T12:00:00.000Z',
  'cuotasPagadasPrevias': 0,
  'montoPagadoPrevio': 0.00,
  'montoTotal': 540000.00,
  'cantidadCuotas': 12,
  'montoPagadoReal': montoPagadoReal,
  'montoPagado': montoPagadoReal,
  'montoRestante': 540000.00 - montoPagadoReal,
  'totalPorPagar': 540000.00 - montoPagadoReal,
  'saldoCapital': 500000.00,
  'cuotasPagadas': cuotasPagadas,
  'proximaCuotaNumero': 1,
  'proximaCuotaMontoPendiente': 45000.00,
  'proximaFechaVencimiento': '2026-12-01',
  'interesesPagados': 0.00,
};

ResponseBody amortizacionResponse() => jsonResponse(<Object?>[
  <String, Object?>{
    'numero': 1,
    'fechaVencimiento': '2026-12-01',
    'cuota': 45000.00,
    'capital': 37000.00,
    'interes': 7500.00,
    'costoAdicional': 500.00,
    'saldo': 463000.00,
    'estado': 'PENDIENTE',
    'montoPagado': 0.00,
    'previa': false,
  },
]);

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;
  late int deudasListadas;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenStore = InMemoryTokenStore();
    tokenStore.save(token: 'jwt.vigente', refreshToken: 'refresh.vigente');
    deudasListadas = 0;
  });

  ResponseBody? base(RequestOptions options, {List<Object?>? deudas}) {
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
    if (options.path.endsWith('/deudas/me')) {
      deudasListadas += 1;
      return jsonResponse(
        deudas ?? <Object?>[deudaJson()],
      );
    }
    if (options.path.endsWith('/deudas/1/amortizacion')) {
      return amortizacionResponse();
    }
    if (options.path.endsWith('/deudas/1/pagos')) {
      return jsonResponse(<String, Object?>{
        'content': <Object?>[],
        'currentPage': 0,
        'totalItems': 0,
        'totalPages': 0,
      });
    }
    if (options.path.endsWith('/deudas/1')) {
      return jsonResponse(deudas?.isNotEmpty == true ? deudas!.first : deudaJson());
    }
    return null;
  }

  Future<void> abrirDeudas(WidgetTester tester, {List<Object?>? deudas}) async {
    adapter.handler = (RequestOptions options) async {
      final ResponseBody? respuesta = base(options, deudas: deudas);
      if (respuesta != null) {
        return respuesta;
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };
    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('lista con progreso, detalle y cronograma', (
    WidgetTester tester,
  ) async {
    await abrirDeudas(tester);

    expect(find.text('Crédito de consumo'), findsOneWidget);
    expect(find.text('0 de 12 cuotas'), findsOneWidget);
    expect(find.text('Pendiente: \$540.000'), findsOneWidget);
    expect(find.text('Próxima cuota 1 · \$45.000 · vence 2026-12-01'),
        findsOneWidget);

    await tester.tap(find.text('Crédito de consumo'));
    await tester.pumpAndSettle();

    expect(find.text('Deuda'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cronograma de cuotas'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cronograma de cuotas'), findsOneWidget);
    expect(find.text('2026-12-01'), findsWidgets);
    expect(find.byTooltip('Editar deuda'), findsOneWidget);
  });

  testWidgets('con pagos registrados no ofrece editar', (
    WidgetTester tester,
  ) async {
    await abrirDeudas(
      tester,
      deudas: <Object?>[
        deudaJson(montoPagadoReal: 45000, cuotasPagadas: 1),
      ],
    );

    expect(find.text('1 de 12 cuotas'), findsOneWidget);
    await tester.tap(find.text('Crédito de consumo'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Editar deuda'), findsNothing);
    expect(
      find.textContaining('Edición bloqueada: la deuda ya tiene pagos'),
      findsOneWidget,
    );
  });

  testWidgets('historial vacío y alta de deuda con el bloque condiciones', (
    WidgetTester tester,
  ) async {
    List<Object?> deudas = <Object?>[deudaJson()];
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/deudas') && options.method == 'POST') {
        expect(jsonBodyOf(options), <String, Object?>{
          'nombre': 'Crédito test',
          'tipoDeuda': 'OTRO',
          'cuotasPagadasPrevias': 0,
          'condiciones': <String, Object?>{
            'modalidad': 'SIN_INTERES',
            'montoCapital': 100000,
            'cantidadCuotas': 10,
          },
        });
        deudas = <Object?>[
          ...deudas,
          deudaJson(id: 2, nombre: 'Crédito test'),
        ];
        return jsonResponse(deudaJson(id: 2, nombre: 'Crédito test'));
      }
      final ResponseBody? respuesta = base(options, deudas: deudas);
      if (respuesta != null) {
        return respuesta;
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    // Historial sin deudas pagadas/canceladas.
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('No hay deudas pagadas ni canceladas.'), findsOneWidget);
    await tester.tap(find.text('Activas'));
    await tester.pumpAndSettle();

    // Alta.
    await tester.tap(find.text('Nueva deuda'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Crédito test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital'),
      '100000',
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Cantidad de cuotas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad de cuotas'),
      '10',
    );
    await tester.ensureVisible(find.text('Crear deuda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear deuda'));
    await tester.pumpAndSettle();

    // Volvió al listado y recargó.
    expect(deudasListadas, greaterThanOrEqualTo(2));
    expect(find.text('Crédito test'), findsOneWidget);
  });
}
