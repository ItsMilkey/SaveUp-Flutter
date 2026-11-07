import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Colores propios que Material no cubre (canvas, semánticos, charts).
@immutable
class SaveUpColors extends ThemeExtension<SaveUpColors> {
  const SaveUpColors({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.border,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.positiveText,
    required this.negativeText,
    required this.savingsText,
    required this.chartPalette,
    required this.categoryFallback,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color muted;
  final Color border;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color positiveText;
  final Color negativeText;
  final Color savingsText;
  final List<Color> chartPalette;
  final Color categoryFallback;

  static const SaveUpColors light = SaveUpColors(
    canvas: AppColors.canvas,
    surface: AppColors.paper,
    surfaceAlt: Color(0xFFFFF8E7),
    ink: AppColors.ink,
    muted: AppColors.muted,
    border: AppColors.ink,
    success: AppColors.green,
    onSuccess: AppColors.ink,
    warning: AppColors.orange,
    onWarning: AppColors.ink,
    info: AppColors.cyan,
    onInfo: AppColors.ink,
    positiveText: Color(0xFF1E7A4C),
    negativeText: Color(0xFFB42318),
    savingsText: Color(0xFF0E7490),
    chartPalette: <Color>[
      AppColors.magenta,
      AppColors.orange,
      AppColors.lavender,
      AppColors.cyan,
      AppColors.green,
      AppColors.yellow,
    ],
    categoryFallback: AppColors.lavender,
  );

  static const SaveUpColors dark = SaveUpColors(
    canvas: AppColors.darkCanvas,
    surface: AppColors.darkSurface,
    surfaceAlt: AppColors.darkSurfaceAlt,
    ink: AppColors.darkText,
    muted: AppColors.darkMuted,
    border: AppColors.darkText,
    success: AppColors.green,
    onSuccess: AppColors.ink,
    warning: AppColors.orange,
    onWarning: AppColors.ink,
    info: AppColors.cyan,
    onInfo: AppColors.ink,
    positiveText: Color(0xFF6EE7B7),
    negativeText: Color(0xFFFF8A80),
    savingsText: Color(0xFF67E8F9),
    chartPalette: <Color>[
      AppColors.magenta,
      AppColors.orange,
      AppColors.lavender,
      AppColors.cyan,
      AppColors.green,
      AppColors.yellow,
    ],
    categoryFallback: AppColors.lavender,
  );

  @override
  SaveUpColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? muted,
    Color? border,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? positiveText,
    Color? negativeText,
    Color? savingsText,
    List<Color>? chartPalette,
    Color? categoryFallback,
  }) {
    return SaveUpColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      positiveText: positiveText ?? this.positiveText,
      negativeText: negativeText ?? this.negativeText,
      savingsText: savingsText ?? this.savingsText,
      chartPalette: chartPalette ?? this.chartPalette,
      categoryFallback: categoryFallback ?? this.categoryFallback,
    );
  }

  @override
  SaveUpColors lerp(ThemeExtension<SaveUpColors>? other, double t) {
    if (other is! SaveUpColors) {
      return this;
    }
    return SaveUpColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      positiveText: Color.lerp(positiveText, other.positiveText, t)!,
      negativeText: Color.lerp(negativeText, other.negativeText, t)!,
      savingsText: Color.lerp(savingsText, other.savingsText, t)!,
      chartPalette: _lerpColors(chartPalette, other.chartPalette, t),
      categoryFallback: Color.lerp(
        categoryFallback,
        other.categoryFallback,
        t,
      )!,
    );
  }

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) {
    final int length = a.length < b.length ? a.length : b.length;
    return <Color>[
      for (int i = 0; i < length; i++) Color.lerp(a[i], b[i], t)!,
    ];
  }
}
