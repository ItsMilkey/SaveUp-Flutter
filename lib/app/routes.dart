/// Nombres de ruta centralizados para evitar strings sueltos en la app.
abstract final class AppRoutes {
  /// Splash: consulta de versión y validación de sesión.
  static const String splash = '/';

  /// Actualización obligatoria (pantalla bloqueante).
  static const String actualizacion = '/actualizacion';

  /// Inicio de sesión.
  static const String login = '/login';

  /// Creación de cuenta.
  static const String registro = '/registro';

  /// Home provisorio (se reemplaza en F3).
  static const String home = '/home';

  /// Cambio de contraseña (sesión activa).
  static const String cambiarContrasena = '/cuenta/cambiar-contrasena';

  /// Solicitud de recuperación sin sesión.
  static const String recuperarContrasena = '/recuperar-contrasena';

  /// Restablecimiento con token, sin sesión.
  static const String restablecerContrasena = '/restablecer-contrasena';

  /// Visor de documentos legales (accesible con o sin sesión).
  static const String legales = '/legales';
}
