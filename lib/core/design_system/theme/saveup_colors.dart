import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Roles de paleta, superficies y estados compartidos mediante el tema.
@immutable
class SaveUpColors extends ThemeExtension<SaveUpColors> {
  const SaveUpColors({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceAccent,
    required this.ink,
    required this.muted,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.tertiary,
    required this.onTertiary,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
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
  final Color surfaceAccent;
  final Color ink;
  final Color muted;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color tertiary;
  final Color onTertiary;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color info;
  final Color onInfo;
  final Color positiveText;
  final Color negativeText;
  final Color savingsText;
  final List<Color> chartPalette;
  final Color categoryFallback;

  /// Foreground sobre una superficie de acento (regla R-1 del contrato §3.1):
  /// siempre tinta, en los tres temas.
  ///
  /// No confundir con [ink], que es el color de texto **del tema** y cambia con
  /// el brillo. Usar `ink` sobre un acento claro deja texto claro sobre claro en
  /// el tema oscuro.
  Color get onAccentSurface => AppColors.ink;

  static const SaveUpColors light = SaveUpColors(
    canvas: AppColors.canvas,
    surface: AppColors.paper,
    surfaceAlt: Color(0xFFFFF8E7),
    surfaceAccent: Color(0xFFF4EDFF),
    ink: AppColors.ink,
    muted: AppColors.muted,
    border: AppColors.ink,
    primary: AppColors.yellow,
    onPrimary: AppColors.ink,
    secondary: AppColors.cyan,
    onSecondary: AppColors.ink,
    tertiary: AppColors.magenta,
    onTertiary: AppColors.ink,
    accent: AppColors.lavender,
    onAccent: AppColors.ink,
    success: AppColors.green,
    onSuccess: AppColors.ink,
    warning: AppColors.orange,
    onWarning: AppColors.ink,
    danger: AppColors.danger,
    onDanger: AppColors.ink,
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
    surfaceAccent: AppColors.darkSurfaceAlt,
    ink: AppColors.darkText,
    muted: AppColors.darkMuted,
    border: AppColors.darkText,
    primary: AppColors.yellow,
    onPrimary: AppColors.ink,
    secondary: AppColors.cyan,
    onSecondary: AppColors.ink,
    tertiary: AppColors.magenta,
    onTertiary: AppColors.ink,
    accent: AppColors.lavender,
    onAccent: AppColors.ink,
    success: AppColors.green,
    onSuccess: AppColors.ink,
    warning: AppColors.orange,
    onWarning: AppColors.ink,
    danger: AppColors.danger,
    onDanger: AppColors.ink,
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

  /// Variante diurna con bloques pastel cálidos y acentos de marca vibrantes.
  static const SaveUpColors bold = SaveUpColors(
    canvas: Color(0xFFFFEDD4),
    surface: Color(0xFFFFF8E8),
    surfaceAlt: Color(0xFFFFE1B5),
    surfaceAccent: Color(0xFFFFDCE6),
    ink: AppColors.ink,
    muted: Color(0xFF5A4C52),
    border: AppColors.ink,
    primary: AppColors.yellow,
    onPrimary: AppColors.ink,
    secondary: Color(0xFF59C9B8),
    onSecondary: AppColors.ink,
    tertiary: Color(0xFFFA7265),
    onTertiary: AppColors.ink,
    accent: Color(0xFFA78BFA),
    onAccent: AppColors.ink,
    success: AppColors.green,
    onSuccess: AppColors.ink,
    warning: AppColors.orange,
    onWarning: AppColors.ink,
    danger: AppColors.danger,
    onDanger: AppColors.ink,
    info: Color(0xFF59C9B8),
    onInfo: AppColors.ink,
    positiveText: Color(0xFF1E7A4C),
    negativeText: Color(0xFFB42318),
    savingsText: Color(0xFF0E7490),
    chartPalette: <Color>[
      Color(0xFFFA7265),
      AppColors.orange,
      Color(0xFFA78BFA),
      Color(0xFF59C9B8),
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
    Color? surfaceAccent,
    Color? ink,
    Color? muted,
    Color? border,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? tertiary,
    Color? onTertiary,
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
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
      surfaceAccent: surfaceAccent ?? this.surfaceAccent,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
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
      surfaceAccent: Color.lerp(surfaceAccent, other.surfaceAccent, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
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
    return <Color>[for (int i = 0; i < length; i++) Color.lerp(a[i], b[i], t)!];
  }
}
