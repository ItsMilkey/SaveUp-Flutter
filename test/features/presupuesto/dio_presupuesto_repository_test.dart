import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/errors/failure_messages.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/features/presupuesto/data/dio_presupuesto_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/ejecucion_presupuesto.dart';
import 'package:saveup_app/features/presupuesto/domain/limite_categoria.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/regla_presupuestaria.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

Map<String, Object?> configJson() => <String, Object?>{
  'id': 1,
  'usuarioRut': '12345678-5',
  'porcentajeNecesidades': 50.00,
  'porcentajeDeseos': 30.00,
  'porcentajeAhorro': 20.00,
  'activo': true,
  'automatizarAhorroEnMetas': false,
};

Map<String, Object?> porcentajesJson({
  num necesidades = 50,
  num deseos = 30,
  num ahorro = 20,
}) => <String, Object?>{
  'necesidades': necesidades,
  'deseos': deseos,
  'ahorro': ahorro,
};

Map<String, Object?> ejecucionJson() => <String, Object?>{
  'presupuestoNecesidades': 500000.00,
  'gastoNecesidades': 450000.00,
  'presupuestoDeseos': 300000.00,
  'gastoDeseos': 120000.00,
  'presupuestoAhorro': 200000.00,
  'ahorroRealizado': 50000.00,
  'totalIngresos': 1000000.00,
  'porcentajeNecesidadesConfigurado': 50.00,
  'porcentajeDeseosConfigurado': 30.00,
  'porcentajeAhorroConfigurado': 20.00,
  'automatizarAhorroEnMetas': false,
};

Map<String, Object?> limiteJson({int id = 2}) => <String, Object?>{
  'categoriaId': id,
  'categoria': 'Alimentación Básica',
  'limiteMensual': 150000.00,
};

Map<String, Object?> ejecucionCategoriaJson({int id = 2}) => <String, Object?>{
  'categoriaId': id,
  'categoria': 'Alimentación Básica',
  'limite': 150000.00,
  'gastado': 130000.00,
  'porcentajeUsado': 86.66,
  'estado': 'CERCA_DEL_PLAN',
};

void main() {
  late FakeHttpAdapter adapter;
  late DioPresupuestoRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioPresupuestoRepository(client: ApiClient(dio));
  });

  group('configuración', () {
    test('GET /presupuestos/me parsea los porcentajes', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'GET');
        expect(options.path.endsWith('/presupuestos/me'), isTrue);
        return jsonResponse(configJson());
      };

      final ConfiguracionPresupuesto config =
          await repository.obtenerConfiguracion();
      expect(config.porcentajes.necesidades.toString(), '50');
      expect(config.porcentajes.sumaValida, isTrue);
      expect(config.automatizarAhorroEnMetas, isFalse);
    });

    test('POST /presupuestos/me envía el cuerpo exacto', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'POST');
        expect(options.path.endsWith('/presupuestos/me'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'porcentajeNecesidades': 50,
          'porcentajeDeseos': 30,
          'porcentajeAhorro': 20,
          'activo': true,
          'automatizarAhorroEnMetas': false,
        });
        return jsonResponse(configJson());
      };

      await repository.guardarConfiguracion(
        porcentajes: PorcentajesRegla(
          necesidades: Decimal.fromInt(50),
          deseos: Decimal.fromInt(30),
          ahorro: Decimal.fromInt(20),
        ),
      );
    });

    test('400 DATOS_INVALIDOS conserva el detail', () async {
      adapter.handler = (RequestOptions options) async => problemResponse(
        'DATOS_INVALIDOS',
        statusCode: 400,
        detail: 'Los porcentajes deben sumar 100.00.',
      );

      try {
        await repository.guardarConfiguracion(
          porcentajes: PorcentajesRegla(
            necesidades: Decimal.fromInt(50),
            deseos: Decimal.fromInt(30),
            ahorro: Decimal.fromInt(30),
          ),
        );
        fail('debió lanzar');
      } on BadRequestFailure catch (failure) {
        expect(failure.codigo, 'DATOS_INVALIDOS');
        expect(failureMessage(failure), contains('100.00'));
      }
    });
  });

  group('sugerencia', () {
    test('parsea la sugerencia cuando hay datos', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/presupuestos/sugerencia-regla'), isTrue);
        return jsonResponse(<String, Object?>{
          'actual': porcentajesJson(),
          'sugerencia': porcentajesJson(
            necesidades: 55,
            deseos: 25,
            ahorro: 20,
          ),
          'mesesAnalizados': <String>['2026-09', '2026-10'],
          'gastoSuperaIngreso': false,
          'igualALaGuia': false,
        });
      };

      final SugerenciaRegla sugerencia = await repository.sugerenciaRegla();
      expect(sugerencia.sugerencia!.necesidades.toString(), '55');
      expect(sugerencia.mesesAnalizados, <String>['2026-09', '2026-10']);
      expect(sugerencia.motivo, isNull);
    });

    test('DATOS_INSUFICIENTES deja la sugerencia nula', () async {
      adapter.handler = (RequestOptions options) async => jsonResponse(
        <String, Object?>{
          'actual': porcentajesJson(),
          'mesesAnalizados': <String>['2026-10'],
          'gastoSuperaIngreso': false,
          'igualALaGuia': false,
          'motivo': 'DATOS_INSUFICIENTES',
        },
      );

      final SugerenciaRegla sugerencia = await repository.sugerenciaRegla();
      expect(sugerencia.sugerencia, isNull);
      expect(sugerencia.motivo, 'DATOS_INSUFICIENTES');
    });
  });

  group('ejecución', () {
    test('sin parámetros no envía query', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/presupuestos/ejecucion/me'), isTrue);
        expect(options.queryParameters, isEmpty);
        return jsonResponse(ejecucionJson());
      };

      final EjecucionPresupuesto ejecucion = await repository.ejecucion();
      expect(ejecucion.totalIngresos.toString(), '1000000');
      expect(ejecucion.gastoDeseos.toString(), '120000');
    });

    test('month/year viajan como enteros', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.queryParameters['month'], 10);
        expect(options.queryParameters['year'], 2026);
        return jsonResponse(ejecucionJson());
      };

      await repository.ejecucion(month: 10, year: 2026);
    });

    test('historial exige desde/hasta en yyyy-MM y parsea la lista', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/presupuestos/historial/me'), isTrue);
        expect(options.queryParameters['desde'], '2026-08');
        expect(options.queryParameters['hasta'], '2026-10');
        return jsonResponse(<Object?>[
          <String, Object?>{
            'anio': 2026,
            'mes': 10,
            'ejecucion': ejecucionJson(),
          },
        ]);
      };

      final List<HistorialPresupuesto> historial = await repository.historial(
        desde: '2026-08',
        hasta: '2026-10',
      );
      expect(historial.single.anio, 2026);
      expect(historial.single.mes, 10);
      expect(historial.single.ejecucion.presupuestoAhorro.toString(), '200000');
    });
  });

  group('límites por categoría', () {
    test('GET lista los límites configurados', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/presupuestos/categorias/me'), isTrue);
        return jsonResponse(<Object?>[limiteJson()]);
      };

      final List<LimiteCategoria> limites = await repository.listarLimites();
      expect(limites.single.categoria, 'Alimentación Básica');
      expect(limites.single.limiteMensual.toString(), '150000');
    });

    test('PUT reemplaza el conjunto completo con {categorias:[...]}', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'PUT');
        expect(jsonBodyOf(options), <String, Object?>{
          'categorias': <Object?>[
            <String, Object?>{'categoriaId': 2, 'limiteMensual': 150000},
            <String, Object?>{'categoriaId': 3, 'limiteMensual': 50000},
          ],
        });
        return jsonResponse(<Object?>[
          limiteJson(),
          <String, Object?>{
            'categoriaId': 3,
            'categoria': 'Transporte',
            'limiteMensual': 50000.00,
          },
        ]);
      };

      final List<LimiteCategoria> resultado = await repository.reemplazarLimites(
        <LimiteCategoriaItem>[
          LimiteCategoriaItem(
            categoriaId: 2,
            limiteMensual: Decimal.fromInt(150000),
          ),
          LimiteCategoriaItem(
            categoriaId: 3,
            limiteMensual: Decimal.fromInt(50000),
          ),
        ],
      );
      expect(resultado, hasLength(2));
    });

    test('ejecución por categoría usa month/year y parsea el estado', () async {
      adapter.handler = (RequestOptions options) async {
        expect(
          options.path.endsWith('/presupuestos/categorias/ejecucion/me'),
          isTrue,
        );
        expect(options.queryParameters['month'], 11);
        expect(options.queryParameters['year'], 2026);
        return jsonResponse(<Object?>[ejecucionCategoriaJson()]);
      };

      final List<EjecucionCategoria> ejecucion = await repository
          .ejecucionCategorias(month: 11, year: 2026);
      expect(ejecucion.single.estado, EstadoEjecucion.cercaDelPlan);
      expect(ejecucion.single.porcentajeUsado.toString(), '86.66');
    });
  });
}
