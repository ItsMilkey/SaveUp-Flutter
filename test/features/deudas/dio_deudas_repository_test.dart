import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/deudas/data/dio_deudas_repository.dart';
import 'package:saveup_app/features/deudas/domain/deuda.dart';
import 'package:saveup_app/features/deudas/domain/deudas_repository.dart';
import 'package:saveup_app/features/deudas/domain/pago_deuda.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

Map<String, Object?> deudaJson({
  int id = 1,
  String estado = 'PENDIENTE',
  num montoPagadoReal = 0,
  int cuotasPagadas = 0,
  String? fechaPrimeraCuota = '2026-12-01',
  String? fechaUltimaCuota = '2027-11-01',
  String modalidad = 'TASA_CONOCIDA',
  num tasaMensual = 1.5,
  num tasaAnualEfectiva = 19.56,
  num? valorCuota = 45000,
}) => <String, Object?>{
  'id': id,
  'nombre': 'Crédito de consumo',
  'descripcion': 'Cuota del banco',
  'tipoDeuda': 'PERSONAL',
  'modalidadCalculo': modalidad,
  'estado': estado,
  'montoCapital': 500000.00,
  'tasaMensual': tasaMensual,
  'tasaAnualEfectiva': tasaAnualEfectiva,
  'valorCuota': valorCuota,
  'gastosIniciales': 0.00,
  'costoAdicionalPorCuota': 0.00,
  'costoTotalCredito': 540000.00,
  'cargaAnualEquivalente': 21.00,
  'fechaPrimeraCuota': fechaPrimeraCuota,
  'fechaUltimaCuota': fechaUltimaCuota,
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

void main() {
  late FakeHttpAdapter adapter;
  late DioDeudasRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioDeudasRepository(client: ApiClient(dio));
  });

  group('listar', () {
    test('parsea deudas, tasas en porcentaje y fechas de calendario', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/deudas/me'), isTrue);
        return jsonResponse(<Object?>[deudaJson()]);
      };

      final List<Deuda> lista = await repository.listar();
      final Deuda deuda = lista.single;

      expect(deuda.nombre, 'Crédito de consumo');
      expect(deuda.tipo, TipoDeuda.personal);
      expect(deuda.modalidad, ModalidadCalculo.tasaConocida);
      expect(deuda.estado, EstadoDeuda.pendiente);
      expect(deuda.tasaMensual.toString(), '1.5');
      expect(deuda.tasaAnualEfectiva.toString(), '19.56');
      expect(deuda.fechaPrimeraCuota, CalendarDate(2026, 12, 1));
      expect(deuda.progreso, 0);
      expect(deuda.editable, isTrue);
    });

    test('marca no editable una deuda con pagos reales', () async {
      adapter.handler = (RequestOptions options) async => jsonResponse(
        <Object?>[deudaJson(montoPagadoReal: 45000, cuotasPagadas: 1)],
      );

      final Deuda deuda = (await repository.listar()).single;
      expect(deuda.editable, isFalse);
      expect(deuda.progreso, closeTo(1 / 12, 0.0001));
    });
  });

  group('crear', () {
    test('envía el bloque condiciones exacto', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'POST');
        expect(options.path.endsWith('/deudas'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'nombre': 'Crédito',
          'tipoDeuda': 'PERSONAL',
          'cuotasPagadasPrevias': 0,
          'condiciones': <String, Object?>{
            'modalidad': 'TASA_CONOCIDA',
            'montoCapital': 500000,
            'cantidadCuotas': 12,
            'tasaMensual': 1.5,
          },
        });
        return jsonResponse(deudaJson());
      };

      final Deuda deuda = await repository.crear(
        DeudaCreacion(
          nombre: 'Crédito',
          tipo: TipoDeuda.personal,
          condiciones: CondicionesCredito(
            modalidad: ModalidadCalculo.tasaConocida,
            montoCapital: Decimal.parse('500000'),
            cantidadCuotas: 12,
            tasaMensual: Decimal.parse('1.5'),
          ),
        ),
      );
      expect(deuda.id, 1);
    });

    test('editar usa PUT con el mismo DTO', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'PUT');
        expect(options.path.endsWith('/deudas/1'), isTrue);
        final Map<String, dynamic> body = jsonBodyOf(options);
        expect(body['condiciones']['fechaPrimeraCuota'], '2026-12-01');
        expect(body['condiciones'].containsKey('cantidadCuotas'), isFalse);
        return jsonResponse(deudaJson());
      };

      await repository.editar(
        1,
        DeudaCreacion(
          nombre: 'Crédito',
          tipo: TipoDeuda.personal,
          condiciones: CondicionesCredito(
            modalidad: ModalidadCalculo.sinInteres,
            montoCapital: Decimal.parse('120000'),
            fechaPrimeraCuota: CalendarDate(2026, 12, 1),
            fechaUltimaCuota: CalendarDate(2027, 11, 1),
          ),
        ),
      );
    });
  });

  group('detalle y amortización', () {
    test('GET del detalle y del cronograma', () async {
      adapter.handler = (RequestOptions options) async {
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
              'estado': 'PARCIAL',
              'montoPagado': 20000.00,
              'previa': false,
            },
          ]);
        }
        expect(options.path.endsWith('/deudas/1'), isTrue);
        return jsonResponse(deudaJson());
      };

      final Deuda deuda = await repository.detalle(1);
      expect(deuda.id, 1);

      final List<CuotaAmortizacion> cronograma = await repository.amortizacion(
        1,
      );
      final CuotaAmortizacion cuota = cronograma.single;
      expect(cuota.numero, 1);
      expect(cuota.fechaVencimiento, CalendarDate(2026, 12, 1));
      expect(cuota.estado, EstadoCuota.parcial);
      expect(cuota.previa, isFalse);
      expect(cuota.montoPagado.toString(), '20000');
    });
  });

  group('pagar', () {
    test('CUOTA_CALCULADA no envía monto', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'POST');
        expect(options.path.endsWith('/deudas/1/pagar'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'descripcion': 'Pago Cuota 1',
          'modoPago': 'CUOTA_CALCULADA',
        });
        return jsonResponse(deudaJson(montoPagadoReal: 45000, cuotasPagadas: 1));
      };

      final Deuda deuda = await repository.pagar(
        1,
        modo: ModoPago.cuotaCalculada,
        descripcion: 'Pago Cuota 1',
      );
      expect(deuda.cuotasPagadas, 1);
    });

    test('MONTO_PERSONALIZADO envía el monto como número', () async {
      adapter.handler = (RequestOptions options) async {
        expect(jsonBodyOf(options), <String, Object?>{
          'monto': 20000,
          'descripcion': 'Abono',
          'modoPago': 'MONTO_PERSONALIZADO',
        });
        return jsonResponse(deudaJson(montoPagadoReal: 20000));
      };

      await repository.pagar(
        1,
        monto: Decimal.parse('20000'),
        modo: ModoPago.montoPersonalizado,
        descripcion: 'Abono',
      );
    });
  });

  group('pagos', () {
    test('pide page/size=20 y parsea el desglose', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.queryParameters['page'], 1);
        expect(options.queryParameters['size'], 20);
        return jsonResponse(<String, Object?>{
          'content': <Object?>[
            <String, Object?>{
              'id': 9,
              'fecha': '2026-11-06T16:30:00.000Z',
              'monto': 45000.00,
              'capital': 37000.00,
              'interes': 7500.00,
              'costos': 500.00,
              'descripcion': 'Pago Cuota 1',
            },
          ],
          'currentPage': 1,
          'totalItems': 21,
          'totalPages': 2,
        });
      };

      final PaginaPagos pagina = await repository.pagos(1, page: 1);
      expect(pagina.currentPage, 1);
      expect(pagina.esUltima, isTrue);
      final PagoDeuda pago = pagina.content.single;
      expect(pago.monto.toString(), '45000');
      expect(pago.fecha, DateTime.utc(2026, 11, 6, 16, 30));
    });
  });

  group('cancelar', () {
    test('PATCH sin cuerpo devuelve la deuda cancelada', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'PATCH');
        expect(options.path.endsWith('/deudas/1/cancelar'), isTrue);
        return jsonResponse(deudaJson(estado: 'CANCELADA'));
      };

      final Deuda deuda = await repository.cancelar(1);
      expect(deuda.estado, EstadoDeuda.cancelada);
    });
  });
}
