import 'package:flutter/material.dart';

/// Paleta cruda de SaveUp (no usar directamente en features: usar tokens del
/// tema, `ColorScheme` o `SaveUpColors`).
abstract final class AppColors {
  static const Color ink = Color(0xFF111111);
  static const Color paper = Color(0xFFFFFDF7);
  static const Color canvas = Color(0xFFF7F1E3);
  static const Color yellow = Color(0xFFFFD43B);
  static const Color cyan = Color(0xFF57D9E8);
  static const Color magenta = Color(0xFFF45B9A);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color green = Color(0xFF3DDC97);
  static const Color lavender = Color(0xFFB79CFF);
  static const Color danger = Color(0xFFE5484D);
  static const Color muted = Color(0xFF6B6B6B);

  static const Color darkCanvas = Color(0xFF0E0E0E);
  static const Color darkSurface = Color(0xFF232323);
  static const Color darkSurfaceAlt = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFF7F1E3);
  static const Color darkMuted = Color(0xFFA8A8A8);
}
