import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import 'auth_interceptor.dart';
import 'debug_log_interceptor.dart';
import 'dio_failure.dart';
import 'session_events.dart';
import 'token_store.dart';

Dio _createDio() {
  return Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl.toString(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: const <String, dynamic>{'Accept': 'application/json'},
    ),
  );
}

/// Dio sin el interceptor de sesión: lo usa el refresh para no recursar.
final Provider<Dio> refreshDioProvider = Provider<Dio>((Ref ref) {
  return _createDio();
});

/// Dio principal: base URL, timeouts y sesión (token + refresh).
final Provider<Dio> dioProvider = Provider<Dio>((Ref ref) {
  final Dio dio = _createDio();

  dio.interceptors.add(
    AuthInterceptor(
      tokenStore: ref.watch(tokenStoreProvider),
      refreshDio: ref.watch(refreshDioProvider),
      sessionEvents: ref.watch(sessionEventsProvider),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(const DebugLogInterceptor());
  }

  return dio;
});

final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) {
  return ApiClient(ref.watch(dioProvider));
});

/// Punto único de acceso HTTP de la app.
///
/// Los features no crean `Dio()` propios: usan este cliente (o un repositorio
/// que lo reciba). Aquí los [DioException] se convierten a [AppFailure].
class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _run(() => _dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _run(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Response<T>> put<T>(String path, {Object? data}) {
    return _run(() => _dio.put<T>(path, data: data));
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return _run(() => _dio.patch<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path, {Object? data}) {
    return _run(() => _dio.delete<T>(path, data: data));
  }

  Future<Response<T>> _run<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw failureFromDioException(error);
    }
  }
}
