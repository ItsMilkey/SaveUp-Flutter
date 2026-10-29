import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/errors/app_failure.dart';
import 'package:saveup_app/core/network/api_client.dart';
import 'package:saveup_app/core/network/auth_interceptor.dart';
import 'package:saveup_app/core/network/session_events.dart';
import 'package:saveup_app/core/network/token_store.dart';

import '../../support/fake_http_adapter.dart';

const String _baseUrl = 'http://localhost:8080/api/v1';

ResponseBody _refreshResponse({
  String token = 'nuevo',
  String refreshToken = 'refresh-nuevo',
}) {
  return jsonResponse(<String, Object?>{
    'token': token,
    'refreshToken': refreshToken,
    'expiraEn': '2026-10-22T12:15:00.000Z',
  });
}

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStore store;
  late SessionEvents events;
  late Dio refreshDio;
  late Dio dio;
  late ApiClient client;

  setUp(() {
    adapter = FakeHttpAdapter();
    store = InMemoryTokenStore();
    events = SessionEvents();

    refreshDio = Dio(BaseOptions(baseUrl: _baseUrl))
      ..httpClientAdapter = adapter;
    dio = Dio(BaseOptions(baseUrl: _baseUrl))..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenStore: store,
        refreshDio: refreshDio,
        sessionEvents: events,
      ),
    );
    client = ApiClient(dio);
  });

  tearDown(() async {
    await events.dispose();
  });

  Future<void> saveTokens({
    String token = 'viejo',
    String refreshToken = 'refresh-viejo',
  }) {
    return store.save(token: token, refreshToken: refreshToken);
  }

  test('adjunta el token en las rutas protegidas', () async {
    await saveTokens(token: 'abc');
    adapter.handler = (RequestOptions options) async => jsonResponse(<String, Object?>{'ok': true});

    await client.get<Map<String, dynamic>>('/movimientos/me');

    expect(authorizationOf(adapter.requests.single), 'Bearer abc');
  });

  test('TOKEN_EXPIRADO refresca y reintenta una sola vez', () async {
    await saveTokens(token: 'viejo', refreshToken: 'refresh-viejo');

    int refreshCalls = 0;
    int resourceCalls = 0;
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        return _refreshResponse();
      }
      resourceCalls++;
      if (authorizationOf(options) == 'Bearer nuevo') {
        return jsonResponse(<String, Object?>{'ok': true});
      }
      return problemResponse('TOKEN_EXPIRADO', statusCode: 401);
    };

    final Response<Map<String, dynamic>> response =
        await client.get<Map<String, dynamic>>('/movimientos/me');

    expect(response.statusCode, 200);
    expect(resourceCalls, 2);
    expect(refreshCalls, 1);

    final AuthTokens? tokens = await store.read();
    expect(tokens?.token, 'nuevo');
    expect(tokens?.refreshToken, 'refresh-nuevo');
  });

  test('tres peticiones simultáneas comparten un solo refresh', () async {
    await saveTokens();

    int refreshCalls = 0;
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _refreshResponse();
      }

      await Future<void>.delayed(const Duration(milliseconds: 5));
      if (authorizationOf(options) == 'Bearer nuevo') {
        return jsonResponse(<String, Object?>{'ok': true});
      }
      return problemResponse('TOKEN_EXPIRADO', statusCode: 401);
    };

    final List<Response<Map<String, dynamic>>> responses =
        await Future.wait(<Future<Response<Map<String, dynamic>>>>[
      client.get<Map<String, dynamic>>('/movimientos/a'),
      client.get<Map<String, dynamic>>('/movimientos/b'),
      client.get<Map<String, dynamic>>('/movimientos/c'),
    ]);

    expect(
      responses.every((Response<Map<String, dynamic>> r) => r.statusCode == 200),
      isTrue,
    );
    expect(refreshCalls, 1, reason: 'el refresh debe ser single-flight');
  });

  test('REFRESH_INVALIDO borra tokens y emite sesión expirada', () async {
    await saveTokens();

    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/auth/refresh')) {
        return problemResponse('REFRESH_INVALIDO', statusCode: 401);
      }
      return problemResponse('TOKEN_EXPIRADO', statusCode: 401);
    };

    final Future<SessionEvent> expired = events.events.first;

    await expectLater(
      client.get('/movimientos/me'),
      throwsA(isA<RefreshInvalidFailure>()),
    );
    expect(await expired, isA<SessionExpired>());
    expect(await store.read(), isNull);
  });

  test('si el reintento vuelve a dar 401 no hay tercer intento', () async {
    await saveTokens();

    int resourceCalls = 0;
    int refreshCalls = 0;
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        return _refreshResponse();
      }
      resourceCalls++;
      return problemResponse('TOKEN_EXPIRADO', statusCode: 401);
    };

    final Future<SessionEvent> expired = events.events.first;

    await expectLater(
      client.get('/movimientos/me'),
      throwsA(isA<AppFailure>()),
    );
    expect(await expired, isA<SessionExpired>());
    expect(resourceCalls, 2);
    expect(refreshCalls, 1);
    expect(await store.read(), isNull);
  });

  test('un 401 del login no dispara refresh', () async {
    int refreshCalls = 0;
    adapter.handler = (RequestOptions options) async {
      if (options.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        return _refreshResponse();
      }
      return problemResponse('CREDENCIALES_INVALIDAS', statusCode: 401);
    };

    await expectLater(
      client.post<Map<String, dynamic>>(
        '/usuarios/login',
        data: <String, Object?>{'email': 'a@b.cl', 'contrasena': 'secreta1'},
      ),
      throwsA(isA<CredentialsInvalidFailure>()),
    );
    expect(refreshCalls, 0);
  });

  test('las rutas públicas no llevan Authorization', () async {
    await saveTokens();
    adapter.handler = (RequestOptions options) async =>
        jsonResponse(<String, Object?>{'ok': true});

    await client.get('/app/version');
    await client.post<Map<String, dynamic>>(
      '/usuarios/login',
      data: <String, Object?>{'email': 'a@b.cl', 'contrasena': 'secreta1'},
    );

    expect(adapter.requests, hasLength(2));
    for (final RequestOptions request in adapter.requests) {
      expect(authorizationOf(request), isNull);
    }
  });

  test('timeout y falta de red se traducen a fallas locales', () async {
    adapter.handler = (RequestOptions options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    };

    await expectLater(
      client.get('/movimientos/me'),
      throwsA(isA<TimeoutFailure>()),
    );

    adapter.handler = (RequestOptions options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    };

    await expectLater(
      client.get('/movimientos/me'),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
