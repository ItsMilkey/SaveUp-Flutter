/// DTOs escritos a mano para los endpoints de cuenta.
///
/// La forma de cada campo viene de `docs/contrato/openapi.json`; los
/// obligatorios ausentes se reportan como [FormatException] y la capa de
/// datos lo traduce a una falla de la app.
library;

/// Cuerpo de `PUT /usuarios/me/contrasena`.
class CambioContrasenaRequestDto {
  const CambioContrasenaRequestDto({
    required this.contrasenaActual,
    required this.nuevaContrasena,
  });

  /// Contraseña actual; el cambio se rechaza si no coincide.
  final String contrasenaActual;

  /// Nueva contraseña: 8–64 caracteres, letra y número, ≤72 bytes UTF-8.
  final String nuevaContrasena;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'contrasenaActual': contrasenaActual,
      'nuevaContrasena': nuevaContrasena,
    };
  }
}

/// Cuerpo de `POST /auth/recuperar-contrasena`.
class SolicitudRecuperacionRequestDto {
  const SolicitudRecuperacionRequestDto({required this.email});

  /// Correo con el que se registró la cuenta.
  final String email;

  Map<String, Object?> toJson() => <String, Object?>{'email': email};
}

/// Cuerpo de `POST /auth/restablecer-contrasena`.
class RestablecerContrasenaRequestDto {
  const RestablecerContrasenaRequestDto({
    required this.token,
    required this.nuevaContrasena,
  });

  /// Token de un solo uso recibido por correo (o por los logs, en dev).
  final String token;

  /// Nueva contraseña: 8–64 caracteres, letra y número, ≤72 bytes UTF-8.
  final String nuevaContrasena;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'token': token,
      'nuevaContrasena': nuevaContrasena,
    };
  }
}

/// Cuerpo de `DELETE /usuarios/me`: confirmación por contraseña actual.
class EliminacionCuentaRequestDto {
  const EliminacionCuentaRequestDto({required this.contrasena});

  /// Contraseña actual; el borrado se rechaza si no coincide.
  final String contrasena;

  Map<String, Object?> toJson() =>
      <String, Object?>{'contrasena': contrasena};
}
