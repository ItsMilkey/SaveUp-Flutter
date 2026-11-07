import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/time/calendar_date.dart';
import 'package:saveup_app/features/metas/data/dio_metas_repository.dart';
import 'package:saveup_app/features/metas/domain/meta_ahorro.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

Map<String, Object?> metaJson({
  int id = 3,
  String nombre = 'Viaje a Japón',
  num? montoObjetivo = 1500000.00,
  String? fechaLimite = '2027-06-30',
  num montoActual = 250000.00,
}) => <String, Object?>{
  'id': id,
  'nombre': nombre,
  'montoObjetivo': montoObjetivo,
  'fechaLimite': fechaLimite,
  'montoActual': montoActual,
};

void main() {
  late FakeHttpAdapter adapter;
  late DioMetasRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioMetasRepository(client: ApiClient(dio));
  });

  test('GET /metas/me parsea objetivo, fecha y la meta sin objetivo', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.path.endsWith('/metas/me'), isTrue);
      return jsonResponse(<Object?>[
        metaJson(),
        metaJson(
          id: 1,
          nombre: 'Ahorros',
          montoObjetivo: null,
          fechaLimite: null,
          montoActual: 50000.00,
        ),
      ]);
    };

    final List<MetaAhorro> metas = await repository.listar();
    expect(metas, hasLength(2));
    expect(metas[0].montoObjetivo!.toString(), '1500000');
    expect(metas[0].fechaLimite, CalendarDate(2027, 6, 30));
    expect(metas[0].montoActual.toString(), '250000');
    expect(metas[0].esPorDefecto, isFalse);

    expect(metas[1].montoObjetivo, isNull);
    expect(metas[1].fechaLimite, isNull);
    expect(metas[1].esPorDefecto, isTrue);
  });

  test('POST /metas envía nombre, objetivo y fecha', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'POST');
      expect(options.path.endsWith('/metas'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{
        'nombre': 'Viaje a Japón',
        'montoObjetivo': 1500000.5,
        'fechaLimite': '2027-06-30',
      });
      return jsonResponse(metaJson(), statusCode: 201);
    };

    final MetaAhorro meta = await repository.crear(
      MetaAhorroDatos(
        nombre: 'Viaje a Japón',
        montoObjetivo: Decimal.parse('1500000.50'),
        fechaLimite: CalendarDate(2027, 6, 30),
      ),
    );
    expect(meta.id, 3);
  });

  test('PUT /metas/{id} envía el mismo DTO', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'PUT');
      expect(options.path.endsWith('/metas/3'), isTrue);
      expect(jsonBodyOf(options), <String, Object?>{
        'nombre': 'Viaje',
        'montoObjetivo': 900000,
        'fechaLimite': null,
      });
      return jsonResponse(metaJson(montoObjetivo: 900000));
    };

    final MetaAhorro meta = await repository.editar(
      3,
      MetaAhorroDatos(
        nombre: 'Viaje',
        montoObjetivo: Decimal.fromInt(900000),
      ),
    );
    expect(meta.montoObjetivo!.toString(), '900000');
  });

  test('DELETE /metas/{id} acepta 204', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'DELETE');
      expect(options.path.endsWith('/metas/3'), isTrue);
      return ResponseBody.fromString('', 204);
    };

    await repository.eliminar(3);
  });

  test('abonar y retirar envían monto y descripción', () async {
    adapter.handler = (RequestOptions options) async {
      expect(options.method, 'POST');
      expect(
        options.path,
        anyOf(
          endsWith('/metas/3/abonar'),
          endsWith('/metas/3/retirar'),
        ),
      );
      expect(jsonBodyOf(options), <String, Object?>{
        'monto': 50000,
        'descripcion': 'Abono mensual',
      });
      return jsonResponse(metaJson(montoActual: 300000));
    };

    final MetaAhorro abono = await repository.abonar(
      3,
      monto: Decimal.fromInt(50000),
      descripcion: 'Abono mensual',
    );
    expect(abono.montoActual.toString(), '300000');

    final MetaAhorro retiro = await repository.retirar(
      3,
      monto: Decimal.fromInt(50000),
      descripcion: 'Abono mensual',
    );
    expect(retiro.montoActual.toString(), '300000');
  });

  test('retiro mayor al ahorrado expone el detail del 409', () async {
    adapter.handler = (RequestOptions options) async {
      return problemResponse(
        'CONFLICTO_REGLA_NEGOCIO',
        statusCode: 409,
        detail: 'El monto a retirar no puede ser mayor al total ahorrado.',
      );
    };

    await expectLater(
      repository.retirar(
        3,
        monto: Decimal.fromInt(999999),
        descripcion: 'Retiro',
      ),
      throwsA(
        isA<ConflictFailure>().having(
          (ConflictFailure f) => f.detail,
          'detail',
          'El monto a retirar no puede ser mayor al total ahorrado.',
        ),
      ),
    );
  });
}
