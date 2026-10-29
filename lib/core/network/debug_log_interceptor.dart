import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Log de peticiones **solo en debug**.
///
/// Nunca imprime headers ni cuerpos: el header `Authorization`, los tokens y
/// los cuerpos de auth no pueden terminar en el log.
class DebugLogInterceptor extends Interceptor {
  const DebugLogInterceptor();

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    developer.log(
      _line(response.requestOptions, response.statusCode),
      name: 'http',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      _line(
        err.requestOptions,
        err.response?.statusCode,
        fallback: err.type.name,
      ),
      name: 'http',
    );
    handler.next(err);
  }

  String _line(RequestOptions options, int? status, {String? fallback}) {
    final String statusText = status?.toString() ?? fallback ?? 'sin status';
    return '${options.method} ${options.path} -> $statusText';
  }
}
