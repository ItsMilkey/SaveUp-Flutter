import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/app_platform.dart';

/// Fuente de la versión compilada de la app (`MAJOR.MINOR.PATCH`).
///
/// El formato lo exige `GET /app/version`; se inyecta como función para poder
/// probar el arranque sin depender del plugin.
typedef AppVersionReader = Future<String> Function();

/// Versión compilada con `package_info_plus`.
///
/// `PackageInfo.version` es la versión del build (`1.2.3`); si el proyecto la
/// define sin patch, se entrega igual y el backend responde
/// `DATOS_INVALIDOS`: el arranque degrada, no bloquea.
final Provider<AppVersionReader> appVersionReaderProvider =
    Provider<AppVersionReader>((Ref ref) {
      return () async {
        final PackageInfo info = await PackageInfo.fromPlatform();
        return info.version;
      };
    });

/// Plataforma que se reporta al backend.
///
/// Solo existe `ANDROID` e `IOS` en el contrato; en una app móvil no hay otra
/// `TargetPlatform` posible.
final Provider<AppPlatform> appPlatformProvider = Provider<AppPlatform>((
  Ref ref,
) {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AppPlatform.android;
    case TargetPlatform.iOS:
      return AppPlatform.ios;
    // En pruebas y escritorio se reporta Android para no inventar valores que
    // el contrato no admite.
    default:
      return AppPlatform.android;
  }
});
