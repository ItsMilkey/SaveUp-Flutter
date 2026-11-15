import 'appearance_preference.dart';

/// Persistencia local de la preferencia visual, no sincronizada con el backend.
abstract interface class AppearanceRepository {
  Future<AppearancePreference> read();

  Future<void> write(AppearancePreference preference);
}
