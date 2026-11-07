import 'package:flutter/material.dart';

import '../core/design_system/design_system.dart';

/// Tema de la aplicación: delega en el design system.
class AppTheme {
  const AppTheme._();

  /// Color de marca (amarillo neo-brutalista).
  static const Color seedColor = AppColors.yellow;

  static ThemeData light() => SaveUpTheme.light();

  static ThemeData dark() => SaveUpTheme.dark();
}
