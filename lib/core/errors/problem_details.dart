import 'dart:convert';

import 'app_failure.dart';

/// Traduce un `application/problem+json` del backend a [AppFailure].
///
/// La decisión se toma **por `codigo`** (estable); `detail` solo se conserva
/// como respaldo. Si el cuerpo no es parseable o el `codigo` es desconocido,
/// se devuelve [UnknownFailure] conservando el status.
AppFailure failureFromProblemDetails({
  required int statusCode,
  required Object? body,
}) {
  final Map<String, dynamic>? problem = _asMap(body);
  if (problem == null) {
    return UnknownFailure(status: statusCode);
  }

  final String? codigo = _asString(problem['codigo']);
  final String? detail = _asString(problem['detail']);
  final String? idError = _asString(problem['idError']);

  if (codigo == null) {
    return UnknownFailure(status: statusCode, detail: detail);
  }

  switch (codigo) {
    case 'VALIDACION_FALLIDA':
      return ValidationFailure(_parseFieldErrors(problem['errores']));
    case 'DATOS_INVALIDOS':
    case 'PARAMETRO_INVALIDO':
    case 'SOLICITUD_INVALIDA':
    case 'TOKEN_VERIFICACION_INVALIDO':
      return BadRequestFailure(codigo: codigo, detail: detail);
    case 'NO_AUTENTICADO':
      return const NotAuthenticatedFailure();
    case 'TOKEN_EXPIRADO':
      return const TokenExpiredFailure();
    case 'REFRESH_INVALIDO':
      return const RefreshInvalidFailure();
    case 'CREDENCIALES_INVALIDAS':
      return const CredentialsInvalidFailure();
    case 'INTENTOS_LOGIN_EXCEDIDOS':
      return const LoginBlockedFailure();
    case 'PROHIBIDO':
      return const ForbiddenFailure();
    case 'NO_ENCONTRADO':
      return const NotFoundFailure();
    case 'CONFLICTO_REGLA_NEGOCIO':
    case 'USUARIO_YA_REGISTRADO':
    case 'DEUDA_SOBREPAGO':
      return ConflictFailure(codigo: codigo, detail: detail);
    case 'ERROR_INTERNO':
      return ServerFailure(idError: idError);
    default:
      return UnknownFailure(
        status: statusCode,
        codigo: codigo,
        detail: detail,
      );
  }
}

List<FieldError> _parseFieldErrors(Object? raw) {
  if (raw is! List) {
    return const <FieldError>[];
  }

  final List<FieldError> errors = <FieldError>[];
  for (final Object? item in raw) {
    if (item is! Map) {
      continue;
    }
    final String? field = _asString(item['campo']);
    final String? message = _asString(item['mensaje']);
    if (message != null && message.isNotEmpty) {
      errors.add(FieldError(field: field ?? '', message: message));
    }
  }
  return errors;
}

Map<String, dynamic>? _asMap(Object? body) {
  if (body is Map<String, dynamic>) {
    return body;
  }
  if (body is Map) {
    return body.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }
  if (body is String) {
    final String text = body.trim();
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
  if (body is List<int>) {
    // Endpoints binarios (p. ej. reportes) devuelven el problem+json como bytes.
    final String text = utf8.decode(body, allowMalformed: true).trim();
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

String? _asString(Object? value) => value is String ? value : null;
