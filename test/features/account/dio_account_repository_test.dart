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

  group('solicitarRecuperacion', () {
    test('envía el correo a POST /auth/recuperar-contrasena', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'POST');
        expect(options.path.endsWith('/auth/recuperar-contrasena'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'email': 'ana@example.cl',
        });
        return jsonResponse(
          <String, Object?>{'message': 'Si el correo está registrado.'},
        );
      };

      await repository.solicitarRecuperacion(email: 'ana@example.cl');
    });
  });

  group('restablecerContrasena', () {
    test('envía el token y la nueva contraseña al endpoint del contrato', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'POST');
        expect(options.path.endsWith('/auth/restablecer-contrasena'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'token': 'token-de-correo',
          'nuevaContrasena': 'contrasena2',
        });
        return jsonResponse(<String, Object?>{'message': 'Contraseña restablecida.'});
      };

      await repository.restablecerContrasena(
        token: 'token-de-correo',
        nuevaContrasena: 'contrasena2',
      );
    });

    test('TOKEN_VERIFICACION_INVALIDO llega como BadRequestFailure', () async {
      adapter.handler = (RequestOptions options) async =>
          problemResponse('TOKEN_VERIFICACION_INVALIDO', statusCode: 400);

      try {
        await repository.restablecerContrasena(
          token: 'vencido',
          nuevaContrasena: 'contrasena2',
        );
        fail('debió lanzar');
      } on BadRequestFailure catch (failure) {
        expect(failure.codigo, 'TOKEN_VERIFICACION_INVALIDO');
      }
    });

    test('VALIDACION_FALLIDA reparte errores[] por campo', () async {
      adapter.handler = (RequestOptions options) async => problemResponse(
        'VALIDACION_FALLIDA',
        errores: <Map<String, String>>[
          <String, String>{
            'campo': 'nuevaContrasena',
            'mensaje': 'no cumple la política',
          },
        ],
      );

      try {
        await repository.restablecerContrasena(
          token: 'token-de-correo',
          nuevaContrasena: 'contrasena2',
        );
        fail('debió lanzar');
      } on ValidationFailure catch (failure) {
        expect(failure.errors.single.field, 'nuevaContrasena');
      }
    });
  });

  group('eliminarCuenta', () {
    test('envía la contraseña en DELETE /usuarios/me y acepta el 204 vacío', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'DELETE');
        expect(options.path.endsWith('/usuarios/me'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'contrasena': 'contrasena1',
        });
        // El contrato responde 204 sin cuerpo.
        return ResponseBody.fromString('', 204);
      };

      await repository.eliminarCuenta(contrasena: 'contrasena1');
    });

    test('CREDENCIALES_INVALIDAS llega como CredentialsInvalidFailure', () async {
      adapter.handler = (RequestOptions options) async =>
          problemResponse('CREDENCIALES_INVALIDAS', statusCode: 401);

      try {
        await repository.eliminarCuenta(contrasena: 'contrasena1');
        fail('debió lanzar');
      } on CredentialsInvalidFailure {
        // El borrado se rechaza: la contraseña no coincide.
      }
    });
  });
}
