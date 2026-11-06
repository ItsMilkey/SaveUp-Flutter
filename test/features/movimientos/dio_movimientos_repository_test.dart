import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/movimientos/data/dio_categorias_repository.dart';
import 'package:saveup_app/features/movimientos/data/dio_movimientos_repository.dart';
import 'package:saveup_app/features/movimientos/data/dio_saldos_repository.dart';
import 'package:saveup_app/features/movimientos/domain/categoria.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento_filtro.dart';
import 'package:saveup_app/features/movimientos/domain/movimiento_tipo.dart';
import 'package:saveup_app/features/movimientos/domain/sugerencia_categoria.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

Map<String, Object?> movimientoJson({
  int id = 1,
  Object? monto = -12500.00,
  String descripcion = 'Supermercado',
  String fecha = '2026-11-05T12:00:00.000Z',
  String tipo = 'GASTO_GENERAL',
  Map<String, Object?>? categoria = const <String, Object?>{
    'id': 1,
    'codigo': 'ALIMENTACION_BASE',
    'nombre': 'Alimentación Básica',
  },
}) => <String, Object?>{
  'id': id,
  'monto': monto,
  'descripcion': descripcion,
  'fecha': fecha,
  'tipoMovimiento': tipo,
  'categoria': categoria,
};

void main() {
  late FakeHttpAdapter adapter;
  late DioMovimientosRepository movimientos;
  late DioSaldosRepository saldos;
  late DioCategoriasRepository categorias;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    final ApiClient client = ApiClient(dio);
    movimientos = DioMovimientosRepository(client: client);
    saldos = DioSaldosRepository(client: client);
    categorias = DioCategoriasRepository(client: client);
  });

  group('filtro', () {
    test('omite nulos y serializa fechas y montos como número', () {
      final MovimientoFiltro filtro = MovimientoFiltro(
        desde: CalendarDate(2026, 11, 1),
        hasta: CalendarDate(2026, 11, 30),
        tipo: MovimientoTipo.gastoGeneral,
        montoMin: null,
      );

      expect(filtro.toQueryParameters(), <String, Object?>{
        'desde': '2026-11-01',
        'hasta': '2026-11-30',
        'tipoMovimiento': 'GASTO_GENERAL',
      });
      expect(filtro.vacio, isFalse);
      expect(const MovimientoFiltro().toQueryParameters(), isEmpty);
      expect(const MovimientoFiltro().vacio, isTrue);
    });
  });

  group('saldos', () {
    test('parsea saldo negativo como Decimal', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/saldos/me'), isTrue);
        return jsonResponse(<String, Object?>{'saldo': -12500.50});
      };

      final saldo = await saldos.saldoActual();
      expect(saldo.toString(), '-12500.5');
    });
  });

  group('movimientos paginados', () {
    test('envía page/size y el filtro; parsea monto, fecha y categoría', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/movimientos/paginados/me'), isTrue);
        expect(options.queryParameters['page'], 2);
        expect(options.queryParameters['size'], 50);
        expect(options.queryParameters['tipoMovimiento'], 'GASTO_GENERAL');
        expect(options.queryParameters.containsKey('desde'), isFalse);
        return jsonResponse(<String, Object?>{
          'content': <Object?>[movimientoJson()],
          'currentPage': 2,
          'totalItems': 123,
          'totalPages': 3,
        });
      };

      final PaginaMovimientos pagina = await movimientos.pagina(
        filtro: const MovimientoFiltro(tipo: MovimientoTipo.gastoGeneral),
        page: 2,
      );

      expect(pagina.currentPage, 2);
      expect(pagina.totalItems, 123);
      expect(pagina.totalPages, 3);
      expect(pagina.esUltima, isTrue);
      final movimiento = pagina.content.single;
      expect(movimiento.monto.toString(), '-12500');
      expect(movimiento.fecha, DateTime.utc(2026, 11, 5, 12));
      expect(movimiento.tipo, MovimientoTipo.gastoGeneral);
      expect(movimiento.categoria?.codigo, 'ALIMENTACION_BASE');
    });

    test('un cuerpo con monto inválido se traduce a UnknownFailure', () async {
      adapter.handler = (RequestOptions options) async => jsonResponse(
        <String, Object?>{
          'content': <Object?>[
            movimientoJson(monto: 'no-es-numero'),
          ],
          'currentPage': 0,
          'totalItems': 1,
          'totalPages': 1,
        },
      );

      try {
        await movimientos.pagina(
          filtro: const MovimientoFiltro(),
          page: 0,
        );
        fail('debió lanzar');
      } on UnknownFailure {
        // La forma inválida no debe escalar como excepción de Dart.
      }
    });
  });

  group('registrar', () {
    test('envía el cuerpo exacto con el monto como número', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'POST');
        expect(options.path.endsWith('/movimientos'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'monto': 12500,
          'descripcion': 'Supermercado',
          'tipoMovimiento': 'GASTO_GENERAL',
          'categoriaId': 3,
        });
        return jsonResponse(movimientoJson(monto: -12500));
      };

      await movimientos.registrar(
        monto: Decimal.parse('12500'),
        descripcion: 'Supermercado',
        tipo: MovimientoTipo.gastoGeneral,
        categoriaId: 3,
      );
    });
  });

  group('editar', () {
    test('PUT parcial: envía solo los campos y devuelve el actualizado', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'PUT');
        expect(options.path.endsWith('/movimientos/7'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'monto': 13000,
          'descripcion': 'Supermercado editado',
        });
        return jsonResponse(
          movimientoJson(
            id: 7,
            monto: -13000,
            descripcion: 'Supermercado editado',
          ),
        );
      };

      final movimiento = await movimientos.editar(
        id: 7,
        monto: Decimal.parse('13000'),
        descripcion: 'Supermercado editado',
      );

      expect(movimiento.id, 7);
      expect(movimiento.descripcion, 'Supermercado editado');
      expect(movimiento.monto.toString(), '-13000');
    });

    test('desvincularPartida viaja solo cuando es true', () async {
      adapter.handler = (RequestOptions options) async {
        expect(jsonBodyOf(options), <String, Object?>{
          'desvincularPartida': true,
        });
        return jsonResponse(movimientoJson(id: 7, monto: -1000));
      };

      await movimientos.editar(id: 7, desvincularPartida: true);
    });
  });

  group('eliminar', () {
    test('DELETE /movimientos/{id} acepta el 204 sin cuerpo', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'DELETE');
        expect(options.path.endsWith('/movimientos/9'), isTrue);
        return ResponseBody.fromString('', 204);
      };

      await movimientos.eliminar(9);
    });
  });

  group('sugerencia', () {    test('envía texto y contexto; parsea ambigua y confianza', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/categorias/sugerencia'), isTrue);
        expect(options.queryParameters['texto'], 'cena aniversario');
        expect(options.queryParameters['contexto'], 'GASTO');
        return jsonResponse(<String, Object?>{
          'texto': 'cena aniversario',
          'sugerencias': <Object?>[
            <String, Object?>{
              'categoriaId': 17,
              'codigo': 'REGALOS_CELEBRACIONES',
              'nombre': 'Regalos y Celebraciones',
              'confianza': 0.90,
              'motivo': 'PALABRA_CLAVE',
            },
          ],
          'ambigua': true,
        });
      };

      final RespuestaSugerencia respuesta = await categorias.sugerir(
        texto: 'cena aniversario',
      );

      expect(respuesta.texto, 'cena aniversario');
      expect(respuesta.ambigua, isTrue);
      expect(respuesta.sugerencias.single.confianza.toString(), '0.9');
    });
  });

  group('catálogo', () {
    test('lista categorías del endpoint', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/categorias'), isTrue);
        return jsonResponse(<Object?>[
          <String, Object?>{
            'id': 1,
            'codigo': 'ALIMENTACION_BASE',
            'nombre': 'Alimentación Básica',
          },
        ]);
      };

      final List<Categoria> lista = await categorias.listar();
      expect(lista.single.nombre, 'Alimentación Básica');
    });
  });
}
