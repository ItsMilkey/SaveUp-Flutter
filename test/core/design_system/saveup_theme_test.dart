import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveup_app/core/design_system/design_system.dart';

void main() {
  group('SaveUpTheme.bold', () {
    test('expone la paleta de papel, tinta y acentos en modo claro', () {
      final ThemeData theme = SaveUpTheme.bold();
      final SaveUpColors colors = theme.extension<SaveUpColors>()!;
      final SaveUpShadows shadows = theme.extension<SaveUpShadows>()!;

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, colors.canvas);
      expect(colors.canvas, const Color(0xFFFFEDD4));
      expect(colors.surface, const Color(0xFFFFF8E8));
      expect(colors.surfaceAlt, const Color(0xFFFFE1B5));
      expect(colors.surfaceAccent, const Color(0xFFFFDCE6));
      expect(colors.ink, AppColors.ink);
      expect(colors.border, AppColors.ink);

      expect(theme.colorScheme.primary, colors.primary);
      expect(theme.colorScheme.onPrimary, colors.onPrimary);
      expect(theme.colorScheme.secondary, colors.secondary);
      expect(theme.colorScheme.onSecondary, colors.onSecondary);
      expect(theme.colorScheme.tertiary, colors.tertiary);
      expect(theme.colorScheme.onTertiary, colors.onTertiary);
      expect(theme.colorScheme.error, colors.danger);
      expect(theme.colorScheme.onError, colors.onDanger);
      expect(colors.primary, AppColors.yellow);
      expect(colors.secondary, const Color(0xFF59C9B8));
      expect(colors.tertiary, const Color(0xFFFA7265));
      expect(colors.accent, const Color(0xFFA78BFA));

      expect(colors.success, AppColors.green);
      expect(colors.warning, AppColors.orange);
      expect(colors.danger, AppColors.danger);
      expect(colors.info, const Color(0xFF59C9B8));
      expect(colors.positiveText, SaveUpColors.light.positiveText);
      expect(colors.negativeText, SaveUpColors.light.negativeText);
      expect(colors.savingsText, SaveUpColors.light.savingsText);

      for (final (Color foreground, Color background) in <(Color, Color)>[
        (colors.onPrimary, colors.primary),
        (colors.onSecondary, colors.secondary),
        (colors.onTertiary, colors.tertiary),
        (colors.onAccent, colors.accent),
        (colors.onSuccess, colors.success),
        (colors.onWarning, colors.warning),
        (colors.onDanger, colors.danger),
        (colors.onInfo, colors.info),
        (colors.muted, colors.canvas),
        (colors.ink, colors.surface),
        (colors.ink, colors.surfaceAlt),
        (colors.ink, colors.surfaceAccent),
        (colors.muted, colors.surfaceAccent),
      ]) {
        expect(
          _contrastRatio(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: '$foreground sobre $background debe cumplir WCAG AA.',
        );
      }

      expect(shadows.sm.single.blurRadius, 0);
      expect(shadows.md.single.blurRadius, 0);
      expect(shadows.lg.single.blurRadius, 0);
      expect(shadows.md.single.offset, const Offset(4, 4));
    });

    test('claro y oscuro conservan sus colores existentes', () {
      final ThemeData light = SaveUpTheme.light();
      final SaveUpColors lightColors = light.extension<SaveUpColors>()!;
      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, AppColors.canvas);
      expect(light.colorScheme.primary, AppColors.yellow);
      expect(light.colorScheme.secondary, AppColors.cyan);
      expect(light.colorScheme.tertiary, AppColors.magenta);
      expect(light.colorScheme.error, AppColors.danger);
      expect(light.colorScheme.surface, AppColors.paper);
      expect(light.colorScheme.onSurface, AppColors.ink);
      expect(lightColors.canvas, AppColors.canvas);
      expect(lightColors.surface, AppColors.paper);
      expect(lightColors.surfaceAlt, const Color(0xFFFFF8E7));
      expect(lightColors.success, AppColors.green);
      expect(lightColors.warning, AppColors.orange);
      expect(lightColors.info, AppColors.cyan);

      final ThemeData dark = SaveUpTheme.dark();
      final SaveUpColors darkColors = dark.extension<SaveUpColors>()!;
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, AppColors.darkCanvas);
      expect(dark.colorScheme.primary, AppColors.yellow);
      expect(dark.colorScheme.secondary, AppColors.cyan);
      expect(dark.colorScheme.tertiary, AppColors.magenta);
      expect(dark.colorScheme.error, AppColors.danger);
      expect(dark.colorScheme.surface, AppColors.darkSurface);
      expect(dark.colorScheme.onSurface, AppColors.darkText);
      expect(darkColors.canvas, AppColors.darkCanvas);
      expect(darkColors.surface, AppColors.darkSurface);
      expect(darkColors.surfaceAlt, AppColors.darkSurfaceAlt);
      expect(darkColors.success, AppColors.green);
      expect(darkColors.warning, AppColors.orange);
      expect(darkColors.info, AppColors.cyan);
    });
  });

  group('SaveUpColors ThemeExtension', () {
    test('copyWith conserva y reemplaza todos los roles', () {
      const Color replacement = Color(0xFF345678);
      const List<Color> replacementPalette = <Color>[
        Color(0xFF123456),
        Color(0xFF654321),
      ];
      final SaveUpColors copied = SaveUpColors.bold.copyWith(
        canvas: replacement,
        surface: replacement,
        surfaceAlt: replacement,
        surfaceAccent: replacement,
        ink: replacement,
        muted: replacement,
        border: replacement,
        primary: replacement,
        onPrimary: replacement,
        secondary: replacement,
        onSecondary: replacement,
        tertiary: replacement,
        onTertiary: replacement,
        accent: replacement,
        onAccent: replacement,
        success: replacement,
        onSuccess: replacement,
        warning: replacement,
        onWarning: replacement,
        danger: replacement,
        onDanger: replacement,
        info: replacement,
        onInfo: replacement,
        positiveText: replacement,
        negativeText: replacement,
        savingsText: replacement,
        chartPalette: replacementPalette,
        categoryFallback: replacement,
      );

      expect(_colorFields(copied).values, everyElement(replacement));
      expect(copied.chartPalette, replacementPalette);

      final SaveUpColors partial = SaveUpColors.bold.copyWith(
        primary: replacement,
      );
      expect(partial.primary, replacement);
      expect(partial.surfaceAccent, SaveUpColors.bold.surfaceAccent);
      expect(partial.danger, SaveUpColors.bold.danger);
      expect(partial.chartPalette, SaveUpColors.bold.chartPalette);
    });

    test('lerp interpola todos los roles y la paleta de gráficos', () {
      const double t = 0.5;
      final SaveUpColors start = SaveUpColors.light;
      final SaveUpColors end = SaveUpColors.bold.copyWith(
        canvas: const Color(0xFF102030),
        surface: const Color(0xFF203040),
        surfaceAlt: const Color(0xFF304050),
        surfaceAccent: const Color(0xFF405060),
        ink: const Color(0xFF506070),
        muted: const Color(0xFF607080),
        border: const Color(0xFF708090),
        primary: const Color(0xFF8090A0),
        onPrimary: const Color(0xFF90A0B0),
        secondary: const Color(0xFFA0B0C0),
        onSecondary: const Color(0xFFB0C0D0),
        tertiary: const Color(0xFFC0D0E0),
        onTertiary: const Color(0xFFD0E0F0),
        accent: const Color(0xFFE0F001),
        onAccent: const Color(0xFFF00112),
        success: const Color(0xFF011223),
        onSuccess: const Color(0xFF122334),
        warning: const Color(0xFF233445),
        onWarning: const Color(0xFF344556),
        danger: const Color(0xFF455667),
        onDanger: const Color(0xFF566778),
        info: const Color(0xFF677889),
        onInfo: const Color(0xFF78899A),
        positiveText: const Color(0xFF899AAB),
        negativeText: const Color(0xFF9AABBC),
        savingsText: const Color(0xFFABBCDD),
        chartPalette: const <Color>[Color(0xFF112233), Color(0xFF223344)],
        categoryFallback: const Color(0xFF334455),
      );
      final SaveUpColors mid = start.lerp(end, t);

      for (final MapEntry<String, Color> entry in _colorFields(start).entries) {
        expect(
          _colorFields(mid)[entry.key],
          Color.lerp(entry.value, _colorFields(end)[entry.key], t),
          reason: '${entry.key} debe interpolarse.',
        );
      }
      final int paletteLength =
          start.chartPalette.length < end.chartPalette.length
          ? start.chartPalette.length
          : end.chartPalette.length;
      expect(mid.chartPalette, <Color>[
        for (int i = 0; i < paletteLength; i++)
          Color.lerp(start.chartPalette[i], end.chartPalette[i], t)!,
      ]);
      expect(start.lerp(null, t), same(start));
    });
  });
}

Map<String, Color> _colorFields(SaveUpColors colors) => <String, Color>{
  'canvas': colors.canvas,
  'surface': colors.surface,
  'surfaceAlt': colors.surfaceAlt,
  'surfaceAccent': colors.surfaceAccent,
  'ink': colors.ink,
  'muted': colors.muted,
  'border': colors.border,
  'primary': colors.primary,
  'onPrimary': colors.onPrimary,
  'secondary': colors.secondary,
  'onSecondary': colors.onSecondary,
  'tertiary': colors.tertiary,
  'onTertiary': colors.onTertiary,
  'accent': colors.accent,
  'onAccent': colors.onAccent,
  'success': colors.success,
  'onSuccess': colors.onSuccess,
  'warning': colors.warning,
  'onWarning': colors.onWarning,
  'danger': colors.danger,
  'onDanger': colors.onDanger,
  'info': colors.info,
  'onInfo': colors.onInfo,
  'positiveText': colors.positiveText,
  'negativeText': colors.negativeText,
  'savingsText': colors.savingsText,
  'categoryFallback': colors.categoryFallback,
};

double _contrastRatio(Color foreground, Color background) {
  final double foregroundLuminance = foreground.computeLuminance();
  final double backgroundLuminance = background.computeLuminance();
  final double lighter = math
      .max(foregroundLuminance, backgroundLuminance)
      .toDouble();
  final double darker = math
      .min(foregroundLuminance, backgroundLuminance)
      .toDouble();
  return (lighter + 0.05) / (darker + 0.05);
}
