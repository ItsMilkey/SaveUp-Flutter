import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';
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
  String estado = 'PENDIENTE',
  num montoPagadoReal = 0,
  int cuotasPagadas = 0,
}) => <String, Object?>{
  'id': id,
  'nombre': 'Crédito de consumo',
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
  'proximaCuotaNumero': cuotasPagadas >= 12 ? null : cuotasPagadas + 1,
  'proximaCuotaMontoPendiente': 45000.00,
  'proximaFechaVencimiento': '2026-12-01',
  'interesesPagados': 0.00,
};

Map<String, Object?> pagoJson(int id, String descripcion) => <String, Object?>{
  'id': id,
  'fecha': '2026-11-06T16:30:00.000Z',
  'monto': 45000.00,
  'capital': 37000.00,
  'interes': 7500.00,
  'costos': 500.00,
  'descripcion': descripcion,
};

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;
  late bool pagado;
  late bool cancelada;
  late int saldoLlamadas;
  late int pagosPagina;

  setUp(() {
    adapter = FakeHttpAdapter();
    tokenStore = InMemoryTokenStore();
    tokenStore.save(token: 'jwt.vigente', refreshToken: 'refresh.vigente');
    pagado = false;
    cancelada = false;
    saldoLlamadas = 0;
    pagosPagina = 0;
  });

  DeudaActual deudaActual() => DeudaActual(
    pagado: pagado,
    cancelada: cancelada,
  );

  ResponseBody? base(RequestOptions options) {
    if (options.path.endsWith('/app/version')) {
      return versionResponse();
    }
    if (options.path.endsWith('/usuarios/me')) {
      return jsonResponse(meBody());
    }
    if (options.path.endsWith('/saldos/me')) {
      saldoLlamadas += 1;
      return saldoResponse(saldo: pagado ? -45000 : 0);
    }
    if (options.path.endsWith('/movimientos/paginados/me')) {
      return paginaVaciaResponse();
    }
    if (options.path.endsWith('/deudas/me')) {
      return jsonResponse(<Object?>[deudaActual().json()]);
    }
    if (options.path.endsWith('/deudas/1/amortizacion')) {
      return jsonResponse(<Object?>[
        <String, Object?>{
          'numero': 1,
          'fechaVencimiento': '2026-12-01',
          'cuota': 45000.00,
          'capital': 37000.00,
          'interes': 7500.00,
          'costoAdicional': 500.00,
          'saldo': 463000.00,
          'estado': pagado ? 'PAGADA' : 'PENDIENTE',
          'montoPagado': pagado ? 45000.00 : 0.00,
          'previa': false,
        },
      ]);
    }
    if (options.path.endsWith('/deudas/1/pagos')) {
      final int page = (options.queryParameters['page'] as int?) ?? 0;
      return jsonResponse(<String, Object?>{
        'content': <Object?>[
          if (page == 0)
            pagoJson(1, 'Pago Cuota 1')
          else
            pagoJson(2, 'Pago Cuota 2'),
        ],
        'currentPage': page,
        'totalItems': 2,
        'totalPages': 2,
      });
    }
    if (options.path.endsWith('/deudas/1')) {
      return jsonResponse(deudaActual().json());
    }
    return null;
  }

  Future<void> abrirDetalle(WidgetTester tester) async {
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/deudas/1/pagar')) {
        expect(options.method, 'POST');
        final Map<String, dynamic> body = jsonBodyOf(options);
        if (pagado) {
          expect(body['modoPago'], 'MONTO_PERSONALIZADO');
          expect(body['monto'], 20000);
        } else {
          expect(body['modoPago'], 'CUOTA_CALCULADA');
          expect(body.containsKey('monto'), isFalse);
          expect(body['descripcion'], 'Pago Cuota 1');
        }
        pagado = true;
        return jsonResponse(
          deudaJson(montoPagadoReal: 45000, cuotasPagadas: 1),
        );
      }
      if (options.path.endsWith('/deudas/1/cancelar')) {
        expect(options.method, 'PATCH');
        cancelada = true;
        return jsonResponse(deudaJson(estado: 'CANCELADA'));
      }
      final ResponseBody? respuesta = base(options);
      if (respuesta != null) {
        return respuesta;
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crédito de consumo'));
    await tester.pumpAndSettle();
  }

  testWidgets('pago CUOTA_CALCULADA y monto personalizado refrescan la deuda',
      (WidgetTester tester) async {
    await abrirDetalle(tester);
    final int saldoInicial = saldoLlamadas;

    await tester.tap(find.widgetWithText(FilledButton, 'Registrar pago'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Próxima cuota:'),
      findsOneWidget,
    );

    // Confirmar en el diálogo (la barra inferior también dice lo mismo).
    await tester.tap(
      find.descendant(
        of: find.byType(NeoDialog),
        matching: find.widgetWithText(FilledButton, 'Registrar pago'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1 de 12 cuotas'), findsOneWidget);
    expect(find.text('Pago registrado.'), findsOneWidget);
    // El backend creó el PAGO_DEUDA: home refresca saldo/listado.
    expect(saldoLlamadas, greaterThan(saldoInicial));

    // Segundo pago con monto libre.
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otro monto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monto'),
      '20000',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NeoDialog),
        matching: find.widgetWithText(FilledButton, 'Registrar pago'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1 de 12 cuotas'), findsOneWidget);
  });

  testWidgets('cancelación defensiva deja la deuda cancelada', (
    WidgetTester tester,
  ) async {
    await abrirDetalle(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar deuda'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar la deuda?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NeoDialog),
        matching: find.widgetWithText(FilledButton, 'Cancelar deuda'),
      ),
    );
    await tester.pumpAndSettle();

    expect(cancelada, isTrue);
    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.text('Deuda cancelada.'), findsOneWidget);
    expect(find.text('Registrar pago'), findsNothing);
  });

  testWidgets('historial paginado con Cargar más', (
    WidgetTester tester,
  ) async {
    await abrirDetalle(tester);

    await tester.scrollUntilVisible(
      find.text('Historial de pagos'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pago Cuota 1'), findsOneWidget);

    final Finder cargarMas = find.textContaining('Cargar más');
    await tester.ensureVisible(cargarMas);
    await tester.pumpAndSettle();
    await tester.tap(cargarMas);
    await tester.pumpAndSettle();
    expect(find.text('Pago Cuota 2'), findsOneWidget);
    pagosPagina += 1;
    expect(pagosPagina, 1);
  });

  testWidgets('simulador muestra resultado, tabla y advertencias', (
    WidgetTester tester,
  ) async {
    int solicitudes = 0;
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/simulaciones/credito')) {
        solicitudes += 1;
        expect(jsonBodyOf(options)['modalidad'], 'TASA_CONOCIDA');
        return jsonResponse(<String, Object?>{
          'condiciones': <String, Object?>{
            'modalidad': 'TASA_CONOCIDA',
            'montoCapital': 500000.00,
            'cantidadCuotas': 12,
            'tasaMensual': 1.5,
            'tasaAnualEfectiva': 19.56,
          },
          'valorCuota': 45900.00,
          'montoTotal': 550800.00,
          'gastosIniciales': 0.00,
          'costoTotalCredito': 50800.00,
          'interesesYCostos': 50800.00,
          'cargaAnualEquivalente': 21.5,
          'resumenEducativo': <String, Object?>{
            'costoPorCada100': 10.16,
            'porcentajeSobreCapital': 10.16,
            'porcentajeInteresesYCostos': 9.22,
          },
          'tablaAmortizacion': <Object?>[
            <String, Object?>{
              'numero': 1,
              'cuota': 45900.00,
              'capital': 38400.00,
              'interes': 7500.00,
              'costoAdicional': 0.00,
              'saldo': 461600.00,
            },
          ],
          'advertencias': <String>[
            'El CAE mostrado es referencial; el oficial lo informa la '
                'institución financiera.',
          ],
        });
      }
      final ResponseBody? respuesta = base(options);
      if (respuesta != null) {
        return respuesta;
      }
      fail('petición inesperada: ${options.method} ${options.path}');
    };

    await tester.pumpWidget(testApp(adapter: adapter, tokenStore: tokenStore));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Simular crédito'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capital'),
      '500000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tasa mensual (%)'),
      '1.5',
    );
    expect(find.text('1.5'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Simular'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Simular'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Simular'));
    await tester.pumpAndSettle();
    expect(solicitudes, 1);

    await tester.scrollUntilVisible(
      find.text('Resultado'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Resultado'), findsOneWidget);
    expect(find.text('Resumen educativo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tabla de amortización'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tabla de amortización'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ten en cuenta'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('CAE mostrado es referencial'), findsOneWidget);
  });
}

/// Deuda mutable para el handler de la prueba.
class DeudaActual {
  const DeudaActual({required this.pagado, required this.cancelada});

  final bool pagado;
  final bool cancelada;

  Map<String, Object?> json() {
    if (cancelada) {
      return deudaJson(estado: 'CANCELADA');
    }
    if (pagado) {
      return deudaJson(montoPagadoReal: 45000, cuotasPagadas: 1);
    }
    return deudaJson();
  }
}
