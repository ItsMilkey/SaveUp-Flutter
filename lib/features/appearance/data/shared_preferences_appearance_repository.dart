import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/appearance_preference.dart';
import '../domain/appearance_repository.dart';

/// Implementación local para una preferencia visual no sensible.
class SharedPreferencesAppearanceRepository implements AppearanceRepository {
  SharedPreferencesAppearanceRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String preferenceKey = 'saveup_appearance';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppearancePreference> read() async {
    return AppearancePreference.fromStorage(
      await _preferences.getString(preferenceKey),
    );
  }

  @override
  Future<void> write(AppearancePreference preference) {
    return _preferences.setString(preferenceKey, preference.name);
  }
}

final Provider<AppearanceRepository> appearanceRepositoryProvider =
    Provider<AppearanceRepository>(
      (Ref ref) => SharedPreferencesAppearanceRepository(),
    );
