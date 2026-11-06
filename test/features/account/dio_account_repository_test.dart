import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/features/account/data/dio_account_repository.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

void main() {
  late FakeHttpAdapter adapter;
  late DioAccountRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    repository = DioAccountRepository(client: ApiClient(dio));
  });

  group('cambiarContrasena', () {
    test('envía el cuerpo exacto a PUT /usuarios/me/contrasena', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'PUT');
        expect(options.path.endsWith('/usuarios/me/contrasena'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'contrasenaActual': 'contrasena1',
          'nuevaContrasena': 'contrasena2',
        });
        return jsonResponse(<String, Object?>{'message': 'Contraseña actualizada.'});
      };

      await repository.cambiarContrasena(
        contrasenaActual: 'contrasena1',
        nuevaContrasena: 'contrasena2',
      );
    });

    test('VALIDACION_FALLIDA llega como ValidationFailure por campo', () async {
      adapter.handler = (RequestOptions options) async => problemResponse(
        'VALIDACION_FALLIDA',
        errores: <Map<String, String>>[
          <String, String>{
            'campo': 'nuevaContrasena',
            'mensaje': 'la contraseña no cumple la política',
          },
        ],
      );

      try {
        await repository.cambiarContrasena(
          contrasenaActual: 'contrasena1',
          nuevaContrasena: 'contrasena2',
        );
        fail('debió lanzar');
      } on ValidationFailure catch (failure) {
        expect(failure.errors.single.field, 'nuevaContrasena');
      }
    });

    test('CREDENCIALES_INVALIDAS llega como CredentialsInvalidFailure', () async {
      adapter.handler = (RequestOptions options) async =>
          problemResponse('CREDENCIALES_INVALIDAS', statusCode: 401);

      try {
        await repository.cambiarContrasena(
          contrasenaActual: 'contrasena1',
          nuevaContrasena: 'contrasena2',
        );
        fail('debió lanzar');
      } on CredentialsInvalidFailure {
        // El cambio se rechaza porque la contraseña actual no coincide.
      }
    });
  });
}
