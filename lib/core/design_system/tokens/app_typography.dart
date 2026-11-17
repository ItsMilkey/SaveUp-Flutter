import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Tipografía del sistema: Archivo Black para display, Space Grotesk para UI.
abstract final class AppTypography {
  static const String displayFamily = 'ArchivoBlack';
  static const String bodyFamily = 'SpaceGrotesk';

  /// Cifras de ancho fijo: evita que un monto cambie de ancho al actualizarse.
  static const List<ui.FontFeature> tabularFigures = <ui.FontFeature>[
    ui.FontFeature.tabularFigures(),
  ];

  static TextStyle display({
    double size = 40,
    Color? color,
    double height = 1.05,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      height: height,
      letterSpacing: -0.5,
      color: color,
      fontFeatures: tabularFigures,
    );
  }

  static TextStyle text({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
    Color? color,
    double? letterSpacing,
    bool numeric = false,
  }) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      height: height,
      fontWeight: weight,
      fontVariations: <ui.FontVariation>[
        ui.FontVariation('wght', weight.value.toDouble()),
      ],
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures: numeric ? tabularFigures : null,
    );
  }

  /// Etiqueta del sistema (R-4): mayúsculas con tracking, peso 600.
  ///
  /// El texto llega ya en mayúsculas por el llamador (`label.toUpperCase()`); aquí
  /// viven el tracking, el peso y el tamaño para que no se improvisen.
  static TextStyle label({
    double size = 12,
    Color? color,
    double letterSpacing = 0.5,
  }) {
    return text(
      size: size,
      weight: FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme(Color color) {
    return TextTheme(
      displayLarge: display(size: 48, color: color),
      displayMedium: display(size: 40, color: color),
      displaySmall: display(size: 32, color: color),
      headlineLarge: text(
        size: 28,
        weight: FontWeight.w700,
        height: 1.15,
        color: color,
      ),
      headlineMedium: text(
        size: 24,
        weight: FontWeight.w700,
        height: 1.2,
        color: color,
      ),
      headlineSmall: text(
        size: 20,
        weight: FontWeight.w700,
        height: 1.25,
        color: color,
      ),
      titleLarge: text(
        size: 18,
        weight: FontWeight.w700,
        height: 1.3,
        color: color,
      ),
      titleMedium: text(
        size: 16,
        weight: FontWeight.w600,
        height: 1.35,
        color: color,
      ),
      titleSmall: text(
        size: 14,
        weight: FontWeight.w600,
        height: 1.35,
        color: color,
      ),
      bodyLarge: text(size: 16, height: 1.5, color: color),
      bodyMedium: text(size: 14, height: 1.45, color: color),
      bodySmall: text(size: 12, height: 1.4, color: color),
      labelLarge: text(
        size: 14,
        weight: FontWeight.w600,
        color: color,
      ),
      labelMedium: text(
        size: 12,
        weight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      ),
      labelSmall: text(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      ),
    );
  }
}
