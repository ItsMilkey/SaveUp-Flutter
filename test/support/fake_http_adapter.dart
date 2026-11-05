import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef FakeHandler = Future<ResponseBody> Function(RequestOptions options);

/// Adaptador HTTP falso escrito a mano (sin paquetes de mocking).
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHandler? handler;

  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);

    final FakeHandler? current = handler;
    if (current == null) {
      throw StateError('FakeHttpAdapter sin handler configurado.');
    }
    return current(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['application/json'],
    },
  );
}

ResponseBody problemResponse(
  String codigo, {
  int statusCode = 400,
  String detail = 'detalle del backend',
  List<Map<String, String>>? errores,
  String? idError,
}) {
  return jsonResponse(<String, Object?>{
    'type': 'about:blank',
    'title': 'Error',
    'status': statusCode,
    'detail': detail,
    'instance': '/api/v1/recurso',
    'codigo': codigo,
    'errores': ?errores,
    'idError': ?idError,
  }, statusCode: statusCode);
}

/// Header de autorización, sin depender de las mayúsculas internas de Dio.
Object? authorizationOf(RequestOptions options) {
  return options.headers['Authorization'] ?? options.headers['authorization'];
}

/// Cuerpo de la petición como JSON, sin importar si Dio lo serializó a texto.
Map<String, dynamic> jsonBodyOf(RequestOptions options) {
  final Object? data = options.data;
  if (data is Map) {
    return data.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }
  if (data is String) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  throw StateError('No hay cuerpo JSON: ${data.runtimeType}');
}
