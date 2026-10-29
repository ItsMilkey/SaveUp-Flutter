import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/network/api_client.dart';

import '../../support/fake_http_adapter.dart';

const String _baseUrl = 'http://localhost:8080/api/v1';

void main() {
  late FakeHttpAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: _baseUrl))
      ..httpClientAdapter = adapter;
    client = ApiClient(dio);
  });

  test('mapea un 500 con idError a ServerFailure', () async {
    adapter.handler = (RequestOptions options) async => problemResponse(
          'ERROR_INTERNO',
          statusCode: 500,
          idError: 'uuid-123',
        );

    try {
      await client.get('/movimientos/me');
      fail('debió lanzar');
    } on ServerFailure catch (failure) {
      expect(failure.idError, 'uuid-123');
    }
  });

  test('mapea la validación por campo', () async {
    adapter.handler = (RequestOptions options) async => problemResponse(
          'VALIDACION_FALLIDA',
          errores: <Map<String, String>>[
            <String, String>{
              'campo': 'monto',
              'mensaje': 'Debe ser mayor que cero',
            },
          ],
        );

    try {
      await client.post('/movimientos', data: <String, Object?>{'monto': 0});
      fail('debió lanzar');
    } on ValidationFailure catch (failure) {
      expect(failure.errors.single.field, 'monto');
      expect(failure.errors.single.message, 'Debe ser mayor que cero');
    }
  });

  test('un cuerpo no JSON conserva el status', () async {
    adapter.handler = (RequestOptions options) async => ResponseBody.fromString(
          '<html>Bad Gateway</html>',
          502,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/html'],
          },
        );

    try {
      await client.get('/movimientos/me');
      fail('debió lanzar');
    } on UnknownFailure catch (failure) {
      expect(failure.status, 502);
    }
  });
}
