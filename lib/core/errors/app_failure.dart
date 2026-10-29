/// Fallas de la app.
///
/// Toda respuesta de error del backend (`application/problem+json`) se traduce
/// a uno de estos tipos **por `codigo`**, nunca por el texto de `detail`.
sealed class AppFailure {
  const AppFailure();
}

/// Error de validación por campo (`errores[]` del backend).
class FieldError {
  const FieldError({required this.field, required this.message});

  /// Nombre JSON del campo (p. ej. `condiciones.montoCapital`).
  final String field;

  /// Mensaje en español listo para mostrar junto al campo.
  final String message;
}

/// `VALIDACION_FALLIDA`: se muestran los errores junto a cada campo.
class ValidationFailure extends AppFailure {
  const ValidationFailure(this.errors);

  final List<FieldError> errors;
}

/// Fallas de autenticación y sesión.
sealed class AuthFailure extends AppFailure {
  const AuthFailure();
}

/// `TOKEN_EXPIRADO`: el access token venció; corresponde refrescar una vez.
class TokenExpiredFailure extends AuthFailure {
  const TokenExpiredFailure();
}

/// `REFRESH_INVALIDO`: la sesión ya no existe; hay que volver al login.
class RefreshInvalidFailure extends AuthFailure {
  const RefreshInvalidFailure();
}

/// `NO_AUTENTICADO`: falta el token o no es válido.
class NotAuthenticatedFailure extends AuthFailure {
  const NotAuthenticatedFailure();
}

/// `CREDENCIALES_INVALIDAS`: mensaje genérico de login.
class CredentialsInvalidFailure extends AuthFailure {
  const CredentialsInvalidFailure();
}

/// `INTENTOS_LOGIN_EXCEDIDOS` (429): bloqueo temporal por fuerza bruta.
class LoginBlockedFailure extends AppFailure {
  const LoginBlockedFailure();
}

/// `PROHIBIDO`: el recurso pertenece a otro usuario.
class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure();
}

/// `NO_ENCONTRADO`: recurso inexistente; usualmente un estado vacío.
class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

/// `CONFLICTO_REGLA_NEGOCIO`, `USUARIO_YA_REGISTRADO`, `DEUDA_SOBREPAGO`.
class ConflictFailure extends AppFailure {
  const ConflictFailure({required this.codigo, this.detail});

  final String codigo;
  final String? detail;
}

/// Errores 400 con `codigo` estable que no son de validación por campo.
class BadRequestFailure extends AppFailure {
  const BadRequestFailure({required this.codigo, this.detail});

  final String codigo;
  final String? detail;
}

/// `ERROR_INTERNO` (500): se muestra [idError] para soporte.
class ServerFailure extends AppFailure {
  const ServerFailure({this.idError});

  final String? idError;
}

/// Falla local: no hubo conexión con el backend.
class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

/// Falla local: la petición expiró (el servidor puede estar despertando).
class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
}

/// `codigo` desconocido o cuerpo de error no parseable.
class UnknownFailure extends AppFailure {
  const UnknownFailure({this.status, this.codigo, this.detail});

  final int? status;
  final String? codigo;
  final String? detail;
}
