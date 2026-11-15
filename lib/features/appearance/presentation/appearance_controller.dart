import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_preferences_appearance_repository.dart';
import '../domain/appearance_preference.dart';
import '../domain/appearance_repository.dart';

final NotifierProvider<AppearanceController, AppearancePreference>
appearanceProvider =
    NotifierProvider<AppearanceController, AppearancePreference>(
      AppearanceController.new,
    );

/// Conserva en memoria la opción actual y persiste cada selección localmente.
class AppearanceController extends Notifier<AppearancePreference> {
  AppearanceController([this.initialPreference = AppearancePreference.system]);

  final AppearancePreference initialPreference;

  @override
  AppearancePreference build() => initialPreference;

  Future<void> select(AppearancePreference preference) async {
    if (preference == state) {
      return;
    }

    final AppearanceRepository repository = ref.read(
      appearanceRepositoryProvider,
    );
    final AppearancePreference previous = state;
    state = preference;
    try {
      await repository.write(preference);
    } on Exception {
      state = previous;
      rethrow;
    }
  }
}
