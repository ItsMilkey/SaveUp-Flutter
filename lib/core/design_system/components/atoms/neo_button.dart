import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../theme/saveup_shadows.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

enum NeoButtonVariant { primary, secondary, ghost, danger }

/// Botón con variantes neo-brutalistas y sombra dura.
class NeoButton extends StatelessWidget {
  const NeoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = NeoButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NeoButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final SaveUpShadows shadows = theme.extension<SaveUpShadows>()!;
    final bool disabled = onPressed == null || loading;

    final Widget content = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.ink,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) Icon(icon, size: 18),
              if (icon != null) const SizedBox(width: AppSpacing.sm),
              Text(label),
            ],
          );

    final Widget button = switch (variant) {
      NeoButtonVariant.primary => FilledButton(
        onPressed: disabled ? null : onPressed,
        child: content,
      ),
      NeoButtonVariant.secondary => OutlinedButton(
        onPressed: disabled ? null : onPressed,
        child: content,
      ),
      NeoButtonVariant.ghost => TextButton(
        style: TextButton.styleFrom(
          foregroundColor: IconTheme.of(context).color ?? colors.ink,
        ),
        onPressed: disabled ? null : onPressed,
        child: content,
      ),
      NeoButtonVariant.danger => FilledButton(
        onPressed: disabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: colors.ink,
          disabledBackgroundColor: colors.surfaceAlt,
          disabledForegroundColor: colors.muted,
          textStyle: AppTypography.text(size: 15, weight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.pillAll,
            side: BorderSide(
              color: colors.border,
              width: AppBorders.regular,
            ),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: content,
      ),
    };

    final Widget withShadow = variant == NeoButtonVariant.ghost || disabled
        ? button
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.pillAll,
              boxShadow: shadows.sm,
            ),
            child: button,
          );

    return expanded
        ? SizedBox(width: double.infinity, child: withShadow)
        : withShadow;
  }
}
