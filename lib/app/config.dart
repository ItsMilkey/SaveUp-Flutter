/// Configuración de la aplicación, resuelta en tiempo de compilación.
///
/// Los valores se inyectan con `--dart-define`, por lo que nunca se
/// commitean secretos ni URLs de entornos reales al repositorio.
class AppConfig {
  const AppConfig._();

  /// Nombre visible de la aplicación.
  static const String appName = 'SaveUp';

  /// Valor crudo de `API_BASE_URL` tal como lo entrega el compilador.
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// URL base del backend, incluyendo el prefijo de versión (`/api/v1`).
  ///
  /// Lanza [StateError] si `API_BASE_URL` no fue definida en el build o si
  /// no es una URL absoluta válida. No existe valor por defecto a propósito:
  /// apuntar silenciosamente a un entorno equivocado es peor que fallar.
  static Uri get apiBaseUrl => _resolveApiBaseUrl();

  /// Fuerza la validación de la configuración al arranque de la app.
  ///
  /// Se llama desde `main()` para que un build mal configurado falle de
  /// inmediato con un mensaje claro en lugar de al primer request.
  static void ensureConfigured() {
    _resolveApiBaseUrl();
  }

  static Uri _resolveApiBaseUrl() {
    if (_apiBaseUrl.isEmpty) {
      throw StateError(
        'Falta la variable de compilación API_BASE_URL. '
        'Ejemplo: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1',
      );
    }

    final Uri? uri = Uri.tryParse(_apiBaseUrl);
    if (uri == null || !uri.isScheme('http') && !uri.isScheme('https')) {
      throw StateError(
        'API_BASE_URL debe ser una URL absoluta http/https. '
        'Valor recibido: $_apiBaseUrl',
      );
    }

    return uri;
  }
}
