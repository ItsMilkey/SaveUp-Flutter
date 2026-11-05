import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre una URL fuera de la app. Se inyecta para poder probar la UI sin
/// depender del plugin.
typedef UrlOpener = Future<bool> Function(Uri url);

/// Abre la URL con la app externa correspondiente (tienda, navegador…).
final Provider<UrlOpener> urlOpenerProvider = Provider<UrlOpener>((Ref ref) {
  return (Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
});
