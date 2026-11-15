import 'package:flutter/material.dart';

import '../core/design_system/design_system.dart';
import '../features/appearance/domain/appearance_preference.dart';

/// Tema de la aplicación: delega en el design system.
class AppTheme {
  const AppTheme._();

  /// Color de marca (amarillo neo-brutalista).
  static const Color seedColor = AppColors.yellow;

  static ThemeData light() => SaveUpTheme.light();

  static ThemeData dark() => SaveUpTheme.dark();

  static ThemeData bold() => SaveUpTheme.bold();

  /// Theme data provided as MaterialApp's `theme` for the selected preference.
  static ThemeData forPreference(AppearancePreference preference) =>
      switch (preference) {
        AppearancePreference.system || AppearancePreference.light => light(),
        AppearancePreference.dark => dark(),
        AppearancePreference.bold => bold(),
      };

  /// Theme mode that keeps system brightness for the automatic preference.
  static ThemeMode modeForPreference(AppearancePreference preference) =>
      switch (preference) {
        AppearancePreference.system => ThemeMode.system,
        AppearancePreference.light ||
        AppearancePreference.bold => ThemeMode.light,
        AppearancePreference.dark => ThemeMode.dark,
      };

  /// Resolved data for an isolated live preview card.
  static ThemeData preview(
    AppearancePreference preference,
    Brightness systemBrightness,
  ) => switch (preference) {
    AppearancePreference.system =>
      systemBrightness == Brightness.dark ? dark() : light(),
    AppearancePreference.light => light(),
    AppearancePreference.dark => dark(),
    AppearancePreference.bold => bold(),
  };
}
