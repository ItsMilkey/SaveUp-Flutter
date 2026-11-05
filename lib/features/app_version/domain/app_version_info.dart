/// Política de actualización y versiones legales que entrega
/// `GET /app/version`.
///
/// `versionTerminos` y `versionPrivacidad` se conservan en memoria para la
/// tarea de legales (F2); todavía no hay pantalla que las muestre.
class AppVersionInfo {
  const AppVersionInfo({
    required this.actualizacionObligatoria,
    required this.actualizacionSugerida,
    required this.mensaje,
    required this.urlTienda,
    required this.versionTerminos,
    required this.versionPrivacidad,
  });

  /// `true` si la versión compilada está por debajo del mínimo soportado.
  final bool actualizacionObligatoria;

  /// `true` si hay una versión más reciente sin bloquear la app.
  final bool actualizacionSugerida;

  /// Mensaje en español listo para mostrar.
  final String mensaje;

  /// URL de la tienda (Play Store o App Store) para actualizar.
  final String urlTienda;

  /// Versión vigente de los términos y condiciones.
  final String versionTerminos;

  /// Versión vigente de la política de privacidad.
  final String versionPrivacidad;
}
