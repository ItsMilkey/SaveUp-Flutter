import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/features/presupuesto/data/dio_plan_mensual_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_mensual.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

Map<String, Object?> planJson({
  String mes = '2026-11',
  List<Object?> partidas = const <Object?>[],
  List<Object?> porCategoria = const <Object?>[],
  List<Object?> grupos = const <Object?>[],
  List<Object?> avisos = const <Object?>[],
  Object? guia,
}) => <String, Object?>{
  'mes': mes,
  'existe': true,
  'ingresoReferencia': 1000000.00,
  'resumen': <String, Object?>{
    'planificadoTotal': 730000.00,
    'remanenteLibre': 270000.00,
    'margenSeguridadPct': 27.00,
    'excedeIngreso': false,
    'ingresoReal': 0.00,
    'gastoRealTotal': 0.00,
    'disponibleReal': 0.00,
    'ahorroRegistrado': 0.00,
    'sinPlanificar': <String, Object?>{
      'monto': 0.00,
      'movimientos': 0,
      'porMotivo': <Object?>[],
    },
  },
  'partidas': partidas,
  'porCategoria': porCategoria,
  'repartoPorTipo': <Object?>[
    <String, Object?>{
      'tipo': 'NECESIDAD',
      'planificado': 730000.00,
      'porcentajeDelIngreso': 73.00,
      'real': 0.00,
      'porcentajeRealDelIngresoReal': null,
      'diferenciaPuntos': null,
    },
    <String, Object?>{
      'tipo': 'DESEO',
      'planificado': 0.00,
      'porcentajeDelIngreso': 0.00,
      'real': 0.00,
      'porcentajeRealDelIngresoReal': null,
      'diferenciaPuntos': null,
    },
    <String, Object?>{
      'tipo': 'OTROS',
      'planificado': 0.00,
      'porcentajeDelIngreso': 0.00,
      'real': 0.00,
      'porcentajeRealDelIngresoReal': null,
      'diferenciaPuntos': null,
    },
  ],
  'guia': guia,
  'grupos': grupos,
  'avisos': avisos,
};

Map<String, Object?> partidaJson({int id = 1}) => <String, Object?>{
  'id': id,
  'nombre': 'Arriendo',
  'categoriaId': 4,
  'categoriaCodigo': 'VIVIENDA_SUMINISTROS',
  'montoPlanificado': 400000.00,
  'real': 0.00,
  'diferencia': 400000.00,
  'porcentajeUsado': 0.00,
  'estado': 'BAJO_EL_PLAN',
  'estadoCuota': null,
  'grupoId': 1,
  'deudaId': null,
  'vinculoDesactualizado': false,
  'orden': 1,
  'actualizadoEn': '2026-11-01T12:00:00.000Z',
};

void main() {
  late FakeHttpAdapter adapter;
  late DioPlanMensualRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioPlanMensualRepository(client: ApiClient(dio));
  });

  test('parsea referencias históricas de porCategoria', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.queryParameters['incluirReferencias'], true);
      return jsonResponse(
        planJson(
          porCategoria: <Object?>[
            <String, Object?>{
              'categoriaId': 4,
              'codigo': 'VIVIENDA_SUMINISTROS',
              'tipo': 'NECESIDAD',
              'planificado': 400000.00,
              'real': 0.00,
              'diferencia': 400000.00,
              'porcentajeUsado': 0.00,
              'estado': 'BAJO_EL_PLAN',
              'referencia': <String, Object?>{
                'mesAnterior': 380000.00,
                'promedio3Meses': 390000.00,
              },
            },
          ],
        ),
      );
    };

    final PlanMensual plan = await repository.obtener(
      '2026-11',
      incluirReferencias: true,
    );
    final CategoriaResultado categoria = plan.calculo.porCategoria.single;
    expect(categoria.referencia, isNotNull);
    expect(categoria.referencia!.mesAnterior.toString(), '380000');
    expect(categoria.referencia!.promedio3Meses.toString(), '390000');
  });

  test('copiarDesde usa POST del contrato y devuelve avisos', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'POST');
      expect(
        options.path.endsWith('/planes/2026-11/copiar-desde/2026-10'),
        isTrue,
      );
      return jsonResponse(
        planJson(
          avisos: <Object?>[
            <String, Object?>{
              'motivo': 'SIN_COUOTA_EN_EL_MES',
              'partidaId': 20,
              'nombre': 'Cuota crédito',
              'deudaId': 77,
              'mensaje': 'La deuda no tiene cuota en este mes.',
            },
          ],
        ),
      );
    };

    final PlanMensual plan = await repository.copiarDesde(
      '2026-11',
      '2026-10',
    );
    expect(plan.avisos.single.motivo, 'SIN_COUOTA_EN_EL_MES');
    expect(plan.avisos.single.deudaId, 77);
  });

  test('CRUD de grupos contra /planes/grupos', () async {
    final List<String> llamadas = <String>[];
    adapter.handler = (RequestOptions options) async {
      llamadas.add('${options.method} ${options.path}');
      if (options.method == 'GET') {
        return jsonResponse(<Object?>[
          <String, Object?>{'id': 1, 'nombre': 'Fijos', 'orden': 1},
        ]);
      }
      if (options.method == 'POST') {
        expect(jsonBodyOf(options), <String, Object?>{
          'nombre': 'Variable',
          'orden': 2,
        });
        return jsonResponse(
          <String, Object?>{'id': 2, 'nombre': 'Variable', 'orden': 2},
        );
      }
      if (options.method == 'PUT') {
        expect(options.path.endsWith('/planes/grupos/2'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{'nombre': 'Mensual'});
        return jsonResponse(
          <String, Object?>{'id': 2, 'nombre': 'Mensual', 'orden': 2},
        );
      }
      if (options.method == 'DELETE') {
        expect(options.path.endsWith('/planes/grupos/2'), isTrue);
        return ResponseBody.fromString('', 204);
      }
      fail('inesperado: ${options.method}');
    };

    final List<GrupoPlan> inicial = await repository.listarGrupos();
    expect(inicial.single.nombre, 'Fijos');

    final GrupoPlan creado = await repository.crearGrupo(
      nombre: 'Variable',
      orden: 2,
    );
    expect(creado.id, 2);

    final GrupoPlan editado = await repository.editarGrupo(2, nombre: 'Mensual');
    expect(editado.nombre, 'Mensual');

    await repository.eliminarGrupo(2);
    expect(llamadas, hasLength(4));
  });

  test('parsea partidas, grupos y guía del plan', () async {
    adapter.handler = (RequestOptions options) async => jsonResponse(
      planJson(
        partidas: <Object?>[partidaJson()],
        grupos: <Object?>[
          <String, Object?>{
            'id': 1,
            'nombre': 'Fijos',
            'orden': 1,
            'planificado': 400000.00,
            'porcentajeDelPlanificado': 100.00,
            'real': 0.00,
            'partidaIds': <int>[1],
          },
        ],
        guia: <String, Object?>{
          'necesidades': 50.00,
          'deseos': 30.00,
          'ahorro': 20.00,
        },
      ),
    );

    final PlanMensual plan = await repository.obtener('2026-11');
    expect(plan.partidas.single.nombre, 'Arriendo');
    expect(plan.grupos.single.nombre, 'Fijos');
    expect(plan.calculo.guia?.necesidades.toString(), '50');
    expect(plan.partidas.single.estado.codigo, 'BAJO_EL_PLAN');
  });

  test('actualizarIngreso envía el monto como número', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'PUT');
      expect(options.path.endsWith('/planes/2026-11/ingreso-referencia'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{'monto': 900000});
      return jsonResponse(planJson());
    };

    await repository.actualizarIngreso('2026-11', Decimal.parse('900000'));
  });

  test('crearPartida envía el cuerpo del contrato', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'POST');
      expect(options.path.endsWith('/planes/2026-11/partidas'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{
        'nombre': 'Arriendo',
        'categoriaId': 4,
        'montoPlanificado': 400000,
        'grupoId': 1,
      });
      return jsonResponse(planJson());
    };

    await repository.crearPartida(
      '2026-11',
      nombre: 'Arriendo',
      categoriaId: 4,
      montoPlanificado: Decimal.parse('400000'),
      grupoId: 1,
    );
  });

  test('editarPartida es parcial y permite quitar el grupo', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'PUT');
      expect(options.path.endsWith('/planes/2026-11/partidas/9'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{
        'nombre': 'Arriendo 2',
        'quitarGrupo': true,
      });
      return jsonResponse(planJson());
    };

    await repository.editarPartida(
      '2026-11',
      9,
      nombre: 'Arriendo 2',
      quitarGrupo: true,
    );
  });

  test('eliminarPartida acepta el 204', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'DELETE');
      expect(options.path.endsWith('/planes/2026-11/partidas/9'), isTrue);
      return ResponseBody.fromString('', 204);
    };

    await repository.eliminarPartida('2026-11', 9);
  });
}
