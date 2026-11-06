import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import 'json_object.dart';

/// Helpers de lectura JSON para las capas de datos.
///
/// Traducen cuerpos inesperados o con forma inválida a [UnknownFailure], igual
/// que el resto de repositorios de la app.

Future<Map<String, dynamic>> readObject(
  Future<Response<dynamic>> Function() request,
) async {
  final Response<dynamic> response = await request();
  final Map<String, dynamic>? body = asJsonMap(response.data);
  if (body == null) {
    throw const UnknownFailure(
      detail: 'El servidor devolvió una respuesta inesperada.',
    );
  }
  return body;
}

Future<List<dynamic>> readList(
  Future<Response<dynamic>> Function() request,
) async {
  final Response<dynamic> response = await request();
  final List<dynamic>? body = asJsonList(response.data);
  if (body == null) {
    throw const UnknownFailure(
      detail: 'El servidor devolvió una respuesta inesperada.',
    );
  }
  return body;
}

/// Ejecuta [parse] y traduce [FormatException] a [UnknownFailure].
T parseJson<T>(T Function() parse) {
  try {
    return parse();
  } on FormatException {
    throw const UnknownFailure(
      detail: 'El servidor devolvió una respuesta inesperada.',
    );
  }
}
