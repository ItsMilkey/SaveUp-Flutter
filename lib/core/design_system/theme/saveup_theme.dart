import 'package:flutter/material.dart';

import '../tokens/app_borders.dart';
import '../tokens/app_radii.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'saveup_colors.dart';
import 'saveup_shadows.dart';

/// Tema único de SaveUp (claro y oscuro) con estética neo-brutalista.
abstract final class SaveUpTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    colors: SaveUpColors.light,
    shadows: SaveUpShadows.light(),
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colors: SaveUpColors.dark,
    shadows: SaveUpShadows.dark(),
  );

  static ThemeData bold() => _build(
    brightness: Brightness.light,
    colors: SaveUpColors.bold,
    shadows: SaveUpShadows.light(),
  );

  static ThemeData _build({
    required Brightness brightness,
    required SaveUpColors colors,
    required SaveUpShadows shadows,
  }) {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          secondary: colors.secondary,
          onSecondary: colors.onSecondary,
          tertiary: colors.tertiary,
          onTertiary: colors.onTertiary,
          error: colors.danger,
          onError: colors.onDanger,
          surface: colors.surface,
          onSurface: colors.ink,
          surfaceContainerHighest: colors.surfaceAlt,
          outline: colors.border,
          outlineVariant: colors.border,
        );

    final TextTheme text = AppTypography.textTheme(colors.ink);
    final BorderSide border = BorderSide(
      color: colors.border,
      width: AppBorders.regular,
    );
    final WidgetStateProperty<Color?> selectedSurface =
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.bodyFamily,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      textTheme: text,
      primaryTextTheme: text,
      iconTheme: IconThemeData(color: colors.ink, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.ink),
        titleTextStyle: text.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: border,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceAlt,
          disabledForegroundColor: colors.muted,
          textStyle: AppTypography.text(size: 15, weight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.pillAll,
            side: border,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          textStyle: AppTypography.text(size: 15, weight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 14,
          ),
          side: border,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.ink,
          textStyle: AppTypography.text(size: 14, weight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        labelStyle: AppTypography.text(
          size: 14,
          weight: FontWeight.w500,
          color: colors.muted,
        ),
        hintStyle: AppTypography.text(size: 14, color: colors.muted),
        helperStyle: AppTypography.text(size: 12, color: colors.muted),
        errorStyle: AppTypography.text(size: 12, color: colors.danger),
        prefixIconColor: colors.ink,
        suffixIconColor: colors.ink,
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: border,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: border,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(color: colors.primary, width: AppBorders.bold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(
            color: colors.danger,
            width: AppBorders.regular,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(color: colors.danger, width: AppBorders.bold),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(color: colors.muted, width: AppBorders.thin),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lgAll,
          side: BorderSide(color: colors.border, width: AppBorders.bold),
        ),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle: AppTypography.text(
          size: 14,
          weight: FontWeight.w500,
          color: colors.canvas,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: BorderSide(color: colors.border, width: AppBorders.regular),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary,
        side: BorderSide(color: colors.border, width: AppBorders.regular),
        shape: const StadiumBorder(),
        labelStyle: AppTypography.text(
          size: 12,
          weight: FontWeight.w600,
          color: colors.ink,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: selectedSurface,
          foregroundColor: WidgetStatePropertyAll<Color>(colors.ink),
          side: WidgetStatePropertyAll<BorderSide>(border),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
          textStyle: WidgetStatePropertyAll<TextStyle?>(
            AppTypography.text(size: 13, weight: FontWeight.w600),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary,
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          AppTypography.text(
            size: 11,
            weight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
        iconTheme: WidgetStatePropertyAll<IconThemeData>(
          IconThemeData(color: colors.ink),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: AppBorders.thin,
        space: AppSpacing.lg,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceAlt,
        circularTrackColor: colors.surfaceAlt,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: AppRadii.smAll,
          border: Border.all(color: colors.border, width: AppBorders.thin),
        ),
        textStyle: AppTypography.text(
          size: 12,
          weight: FontWeight.w500,
          color: colors.canvas,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: border,
        ),
        textStyle: AppTypography.text(size: 14, color: colors.ink),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
          side: border,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[colors, shadows],
    );
  }
}
