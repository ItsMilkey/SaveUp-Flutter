import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/network/token_store.dart';
import 'package:saveup_app/features/auth/data/dio_auth_repository.dart';
import 'package:saveup_app/features/auth/domain/user_profile.dart';

import '../../support/fake_http_adapter.dart';

const String baseUrl = 'http://localhost:8080/api/v1';

Map<String, Object?> loginJson() => <String, Object?>{
  'token': 'jwt.abc',
  'refreshToken': 'refresh.xyz',
  'expiraEn': '2026-11-05T12:15:00.000Z',
};

Map<String, Object?> meJson() => <String, Object?>{
  'rut': '12345678-5',
  'nombre': 'Ana',
  'apellido': 'Primerahija',
  'email': 'ana@example.cl',
  'fechaRegistro': '2026-01-15T10:30:00.000Z',
};

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore tokenStore;
  late DioAuthRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter;
    tokenStore = InMemoryTokenStore();
    repository = DioAuthRepository(
      client: ApiClient(dio),
      tokenStore: tokenStore,
    );
  });

  group('register', () {
    test('envía los campos del contrato y no guarda tokens', () async {
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'POST');
        expect(options.path.endsWith('/usuarios/register'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'rut': '12345678-5',
          'nombre': 'Ana',
          'apellido': 'Primerahija',
          'email': 'ana@example.cl',
          'contrasena': 'contrasena1',
        });
        return jsonResponse(<String, Object?>{'message': 'ok'});
      };

      await repository.register(
        rut: '12345678-5',
        nombre: 'Ana',
        apellido: 'Primerahija',
        email: 'ana@example.cl',
        password: 'contrasena1',
      );

      expect(await tokenStore.read(), isNull);
    });

    test('VALIDACION_FALLIDA se traduce a ValidationFailure', () async {
      adapter.handler = (RequestOptions options) async => problemResponse(
        'VALIDACION_FALLIDA',
        errores: <Map<String, String>>[
          <String, String>{'campo': 'email', 'mensaje': 'correo inválido'},
        ],
      );

      try {
        await repository.register(
          rut: '12345678-5',
          nombre: 'Ana',
          apellido: 'Primerahija',
          email: 'ana@example.cl',
          password: 'contrasena1',
        );
        fail('debió lanzar');
      } on ValidationFailure catch (failure) {
        expect(failure.errors.single.field, 'email');
      }
    });

    test('USUARIO_YA_REGISTRADO (409) llega como ConflictFailure', () async {
      adapter.handler = (RequestOptions options) async =>
          problemResponse('USUARIO_YA_REGISTRADO', statusCode: 409);

      try {
        await repository.register(
          rut: '12345678-5',
          nombre: 'Ana',
          apellido: 'Primerahija',
          email: 'ana@example.cl',
          password: 'contrasena1',
        );
        fail('debió lanzar');
      } on ConflictFailure catch (failure) {
        expect(failure.codigo, 'USUARIO_YA_REGISTRADO');
      }
    });
  });

  group('login', () {
    test('guarda ambos tokens y devuelve el perfil de /usuarios/me', () async {
      adapter.handler = (RequestOptions options) async {
        if (options.path.endsWith('/usuarios/login')) {
          expect(jsonBodyOf(options), <String, Object?>{
            'email': 'ana@example.cl',
            'contrasena': 'contrasena1',
          });
          return jsonResponse(loginJson());
        }
        if (options.path.endsWith('/usuarios/me')) {
          // El Authorization lo prueba auth_interceptor_test.
          return jsonResponse(meJson());
        }
        fail('petición inesperada: ${options.path}');
      };

      final UserProfile profile = await repository.login(
        email: 'ana@example.cl',
        password: 'contrasena1',
      );

      expect(profile.email, 'ana@example.cl');
      expect(profile.nombre, 'Ana');
      final AuthTokens? tokens = await tokenStore.read();
      expect(tokens?.token, 'jwt.abc');
      expect(tokens?.refreshToken, 'refresh.xyz');
    });

    test('CREDENCIALES_INVALIDAS no guarda tokens', () async {
      adapter.handler = (RequestOptions options) async =>
          problemResponse('CREDENCIALES_INVALIDAS', statusCode: 401);

      try {
        await repository.login(email: 'ana@example.cl', password: 'malas1');
        fail('debió lanzar');
      } on CredentialsInvalidFailure {
        expect(await tokenStore.read(), isNull);
      }
    });

    test(
      'INTENTOS_LOGIN_EXCEDIDOS (429) llega como LoginBlockedFailure',
      () async {
        adapter.handler = (RequestOptions options) async =>
            problemResponse('INTENTOS_LOGIN_EXCEDIDOS', statusCode: 429);

        try {
          await repository.login(
            email: 'ana@example.cl',
            password: 'contrasena1',
          );
          fail('debió lanzar');
        } on LoginBlockedFailure {
          // Nada más: la UI decide el reintento manual.
        }
      },
    );
  });

  group('logout', () {
    test('envía el refresh token y borra los tokens locales', () async {
      await tokenStore.save(token: 'jwt.abc', refreshToken: 'refresh.xyz');
      adapter.handler = (RequestOptions options) async {
        expect(options.method, 'POST');
        expect(options.path.endsWith('/auth/logout'), isTrue);
        expect(jsonBodyOf(options), <String, Object?>{
          'refreshToken': 'refresh.xyz',
        });
        return jsonResponse(<String, Object?>{'message': 'ok'});
      };

      await repository.logout();

      expect(await tokenStore.read(), isNull);
    });

    test('borra los tokens aunque la llamada falle', () async {
      await tokenStore.save(token: 'jwt.abc', refreshToken: 'refresh.xyz');
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/auth/logout'), isTrue);
        // Un 500 se traduce a AppFailure en el cliente: logout es local.
        return problemResponse('ERROR_INTERNO', statusCode: 500);
      };

      await repository.logout();

      expect(await tokenStore.read(), isNull);
    });

    test('sin tokens guardados no envía petición y limpia igual', () async {
      adapter.handler = (RequestOptions options) async =>
          jsonResponse(<String, Object?>{'message': 'ok'});

      await repository.logout();

      expect(
        adapter.requests.where(
          (RequestOptions r) => r.path.contains('/auth/logout'),
        ),
        isEmpty,
      );
      expect(await tokenStore.read(), isNull);
    });
  });

  group('currentUser / hasSession', () {
    test('sin tokens devuelve null sin llamar a /usuarios/me', () async {
      adapter.handler = (RequestOptions options) async =>
          fail('no debió pedir nada: ${options.path}');

      expect(await repository.currentUser(), isNull);
      expect(await repository.hasSession(), isFalse);
    });

    test('con tokens devuelve el perfil', () async {
      await tokenStore.save(token: 'jwt.abc', refreshToken: 'refresh.xyz');
      adapter.handler = (RequestOptions options) async {
        expect(options.path.endsWith('/usuarios/me'), isTrue);
        return jsonResponse(meJson());
      };

      final UserProfile? profile = await repository.currentUser();

      expect(profile?.email, 'ana@example.cl');
      expect(profile?.fechaRegistro.toUtc().year, 2026);
      expect(await repository.hasSession(), isTrue);
    });
  });
}
