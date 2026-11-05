import 'app_platform.dart';
import 'app_version_info.dart';

/// Consulta de la política de actualización (`GET /app/version`).
abstract interface class AppVersionRepository {
  /// [version] debe tener la forma `MAJOR.MINOR.PATCH` (SemVer).
  Future<AppVersionInfo> fetch({
    required AppPlatform platform,
    required String version,
  });
}
