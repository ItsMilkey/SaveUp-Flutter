import 'package:flutter/material.dart';

/// Tema Material 3 de la aplicación (claro y oscuro).
///
/// Ambos esquemas se derivan de la misma paleta semilla para mantener
/// coherencia de marca entre modos.
class AppTheme {
  const AppTheme._();

  /// Color semilla de la marca SaveUp.
  static const Color seedColor = Color(0xFF00695C);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
    );
  }
}
