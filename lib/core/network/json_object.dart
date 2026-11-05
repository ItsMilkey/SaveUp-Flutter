import 'dart:convert';

/// Devuelve [data] como objeto JSON (`Map<String, dynamic>`).
///
/// Acepta tanto un `Map` ya decodificado por Dio como un texto JSON, porque
/// algunas respuestas del backend declaran `Content-Type: */*`. Se usa para
/// validar la forma de una respuesta sin depender del content-type.
Map<String, dynamic>? asJsonMap(Object? data) {
  if (data is Map) {
    return data.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }
  if (data is String) {
    final String text = data.trim();
    if (text.isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(text);
      if (decoded is Map) {
        return decoded.map(
          (Object? key, Object? value) => MapEntry(key.toString(), value),
        );
      }
    } on FormatException {
      return null;
    }
  }
  return null;
}
