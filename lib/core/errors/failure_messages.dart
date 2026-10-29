import 'app_failure.dart';

/// Mensaje en español listo para mostrar en la UI para cada [AppFailure].
///
/// El texto se decide por el tipo de falla (derivado del `codigo` del backend),
/// nunca por el texto libre de `detail`, salvo los casos donde el contrato
/// indica mostrarlo (p. ej. `DATOS_INVALIDOS`).
String failureMessage(AppFailure failure) => switch (failure) {
      ValidationFailure() => 'Revisa los datos marcados.',
      TokenExpiredFailure() => 'Tu sesión expiró. Inicia sesión nuevamente.',
      RefreshInvalidFailure() => 'Tu sesión expiró. Inicia sesión nuevamente.',
      NotAuthenticatedFailure() => 'Debes iniciar sesión para continuar.',
      CredentialsInvalidFailure() => 'Correo o contraseña incorrectos.',
      LoginBlockedFailure() => 'Demasiados intentos; espera unos minutos.',
      ForbiddenFailure() => 'No tienes permiso para acceder a este recurso.',
      NotFoundFailure() => 'No encontramos lo que buscas.',
      ConflictFailure(:final String codigo, :final String? detail) =>
        _conflictMessage(codigo, detail),
      BadRequestFailure(:final String codigo, :final String? detail) =>
        _badRequestMessage(codigo, detail),
      ServerFailure(:final String? idError) => _serverMessage(idError),
      NetworkFailure() => 'Sin conexión. Revisa tu red e intenta nuevamente.',
      TimeoutFailure() =>
        'El servidor está tardando demasiado. Intenta nuevamente.',
      UnknownFailure(:final String? detail) =>
        detail != null && detail.isNotEmpty
            ? detail
            : 'Ocurrió un error inesperado.',
    };

String _conflictMessage(String codigo, String? detail) {
  switch (codigo) {
    case 'USUARIO_YA_REGISTRADO':
      return 'Ya existe una cuenta con esos datos. Inicia sesión o recupera '
          'tu cuenta.';
    case 'DEUDA_SOBREPAGO':
      return 'El pago supera el saldo pendiente. Ajusta el monto.';
    default:
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
      return 'No se pudo completar la operación por una regla de negocio.';
  }
}

String _badRequestMessage(String codigo, String? detail) {
  switch (codigo) {
    case 'DATOS_INVALIDOS':
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
      return 'Los datos enviados no son válidos.';
    case 'PARAMETRO_INVALIDO':
      return 'Parámetro inválido. Revisa los filtros enviados.';
    case 'SOLICITUD_INVALIDA':
      return 'La solicitud no es válida. Intenta nuevamente.';
    case 'TOKEN_VERIFICACION_INVALIDO':
      return 'El código no es válido o ya expiró. Solicita uno nuevo.';
    default:
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
      return 'La solicitud no es válida.';
  }
}

String _serverMessage(String? idError) {
  if (idError == null || idError.isEmpty) {
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }
  return 'Ocurrió un error inesperado. Reporta el código $idError a soporte.';
}
