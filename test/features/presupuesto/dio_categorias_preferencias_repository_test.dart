import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/features/presupuesto/data/dio_categorias_preferencias_repository.dart';
import 'package:saveup_app/features/presupuesto/domain/plan_calculo.dart';
import 'package:saveup_app/features/presupuesto/domain/preferencia_categoria.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

Map<String, Object?> preferenciaJson({
  int id = 2,
  String porDefecto = 'NECESIDAD',
  String? preferido,
  String efectivo = 'NECESIDAD',
}) => <String, Object?>{
  'id': id,
  'nombre': 'Alimentación Básica',
  'codigo': 'ALIMENTACION_BASE',
  'iconId': 'food',
  'colorHex': '#FFAA00',
  'tipoPorDefecto': porDefecto,
  'tipoPreferido': preferido,
  'tipoEfectivo': efectivo,
};

void main() {
  late FakeHttpAdapter adapter;
  late DioCategoriasPreferenciasRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioCategoriasPreferenciasRepository(client: ApiClient(dio));
  });

  test('GET preferencias parsea tipos por defecto, preferido y efectivo', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.path.endsWith('/categorias/preferencias'), isTrue);
      return jsonResponse(<Object?>[
        preferenciaJson(),
        preferenciaJson(
          id: 4,
          porDefecto: 'DESEO',
          preferido: 'NECESIDAD',
          efectivo: 'NECESIDAD',
        ),
        preferenciaJson(
          id: 8,
          porDefecto: 'AHORRO',
          efectivo: 'AHORRO',
        ),
      ]);
    };

    final List<PreferenciaCategoria> lista = await repository.listar();
    expect(lista[0].tipoPreferido, isNull);
    expect(lista[0].reclasificable, isTrue);
    expect(lista[1].tipoPreferido, TipoPresupuesto.necesidad);
    expect(lista[1].tipoEfectivo, TipoPresupuesto.necesidad);
    expect(lista[2].reclasificable, isFalse);
  });

  test('PUT tipo-preferido envía solo NECESIDAD/DESEO', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'PUT');
      expect(options.path.endsWith('/categorias/2/tipo-preferido'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{'tipo': 'DESEO'});
      return jsonResponse(
        preferenciaJson(preferido: 'DESEO', efectivo: 'DESEO'),
      );
    };

    final PreferenciaCategoria preferencia = await repository
        .establecerTipoPreferido(2, TipoPresupuesto.deseo);
    expect(preferencia.tipoEfectivo, TipoPresupuesto.deseo);
  });

  test('DELETE tipo-preferido acepta el 204 idempotente', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'DELETE');
      expect(options.path.endsWith('/categorias/2/tipo-preferido'), isTrue);
      return ResponseBody.fromString('', 204);
    };

    await repository.quitarTipoPreferido(2);
  });
}
