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

  /// Alta mínima de movimiento (formulario con sugeridor).
  static const String nuevoMovimiento = '/movimientos/nuevo';

  /// Edición de un movimiento (recibe el `Movimiento` por `extra`).
  static const String editarMovimiento = '/movimientos/editar';

  /// Visor de documentos legales (accesible con o sin sesión).
  static const String legales = '/legales';

  /// Listado de deudas (F4).
  static const String deudas = '/deudas';

  /// Alta de deuda.
  static const String nuevaDeuda = '/deudas/nueva';

  /// Detalle de una deuda.
  static String deudaDetalle(int id) => '/deudas/$id';

  /// Edición de una deuda (recibe la `Deuda` por `extra`).
  static String editarDeuda(int id) => '/deudas/$id/editar';

  /// Simulador de crédito (sin persistencia).
  static const String simulador = '/simulador';

  /// Plan mensual (F6a).
  static const String plan = '/plan';

  /// Configuración de la regla de presupuesto (F6).
  static const String presupuestoConfiguracion = '/presupuestos/configuracion';

  /// Ejecución mensual e historial (F6).
  static const String presupuestoEjecucion = '/presupuestos/ejecucion';

  /// Límites por categoría y tipos preferidos (F6).
  static const String presupuestoCategorias = '/presupuestos/categorias';

  /// Metas de ahorro (F7).
  static const String metas = '/metas';

  /// Alta de una meta de ahorro.
  static const String nuevaMeta = '/metas/nueva';

  /// Edición de una meta (recibe la `MetaAhorro` por `extra`).
  static String editarMeta(int id) => '/metas/$id/editar';

  /// Exportación de movimientos (F8).
  static const String reportes = '/reportes';
}
