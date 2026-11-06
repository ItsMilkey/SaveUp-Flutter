import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/deudas/data/dio_simulador_repository.dart';
import 'package:saveup_app/features/deudas/domain/deuda.dart';
import 'package:saveup_app/features/deudas/domain/simulacion.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

void main() {
  late FakeHttpAdapter adapter;
  late DioSimuladorRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioSimuladorRepository(client: ApiClient(dio));
  });

  test('envía el request exacto y parsea tabla, comparación y advertencias',
      () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'POST');
      expect(options.path.endsWith('/simulaciones/credito'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{
        'modalidad': 'TASA_CONOCIDA',
        'montoCapital': 500000,
        'cantidadCuotas': 12,
        'tasaMensual': 1.5,
        'ingresoMensual': 1000000,
        'cantidadCuotasAlternativas': <int>[24],
        'incluirTabla': true,
      });
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
          'porcentajeIngresoComprometido': 4.59,
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
        'comparacionPlazos': <Object?>[
          <String, Object?>{
            'cantidadCuotas': 24,
            'valorCuota': 25000.00,
            'costoTotalCredito': 600000.00,
            'interesesYCostos': 100000.00,
            'cargaAnualEquivalente': 22.1,
          },
        ],
        'advertencias': <String>[
          'El CAE mostrado es referencial; el oficial lo informa la '
              'institución financiera.',
        ],
      });
    };

    final SimulacionResultado r = await repository.simular(
      SimulacionRequest(
        modalidad: ModalidadCalculo.tasaConocida,
        montoCapital: Decimal.parse('500000'),
        cantidadCuotas: 12,
        tasaMensual: Decimal.parse('1.5'),
        ingresoMensual: Decimal.parse('1000000'),
        cantidadCuotasAlternativas: <int>[24],
      ),
    );

    expect(r.valorCuota.toString(), '45900');
    expect(r.resumen.porcentajeIngresoComprometido.toString(), '4.59');
    expect(r.tabla.single.numero, 1);
    expect(r.comparacion.single.cantidadCuotas, 24);
    expect(r.advertencias, hasLength(1));
  });

  test('plazo por fechas usa las fechas del request', () async {
    adapter.handler = (RequestOptions options) async {
      final Map<String, dynamic> body = jsonBodyOf(options);
      expect(body['fechaPrimeraCuota'], '2026-12-01');
      expect(body['fechaUltimaCuota'], '2027-11-01');
      expect(body.containsKey('cantidadCuotas'), isFalse);
      return jsonResponse(<String, Object?>{
        'condiciones': <String, Object?>{
          'modalidad': 'SIN_INTERES',
          'montoCapital': 120000.00,
          'cantidadCuotas': 12,
          'tasaMensual': 0.0,
          'tasaAnualEfectiva': 0.0,
        },
        'valorCuota': 10000.00,
        'montoTotal': 120000.00,
        'gastosIniciales': 0.00,
        'costoTotalCredito': 0.00,
        'interesesYCostos': 0.00,
        'cargaAnualEquivalente': 0.0,
        'resumenEducativo': <String, Object?>{
          'costoPorCada100': 0.0,
          'porcentajeSobreCapital': 0.0,
          'porcentajeInteresesYCostos': 0.0,
        },
      });
    };

    final SimulacionResultado r = await repository.simular(
      SimulacionRequest(
        modalidad: ModalidadCalculo.sinInteres,
        montoCapital: Decimal.parse('120000'),
        fechaPrimeraCuota: CalendarDate(2026, 12, 1),
        fechaUltimaCuota: CalendarDate(2027, 11, 1),
        incluirTabla: false,
      ),
    );

    expect(r.tabla, isEmpty);
    expect(r.comparacion, isEmpty);
    expect(r.advertencias, isEmpty);
  });
}
