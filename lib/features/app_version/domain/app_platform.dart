/// Plataforma que se reporta al backend en `GET /app/version`.
///
/// El contrato solo admite `ANDROID` e `IOS`; la app es móvil.
enum AppPlatform {
  android('ANDROID'),
  ios('IOS');

  const AppPlatform(this.apiValue);

  /// Valor que viaja en el parámetro `plataforma`.
  final String apiValue;
}
