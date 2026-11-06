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
