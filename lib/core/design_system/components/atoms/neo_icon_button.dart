import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../theme/saveup_shadows.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radii.dart';

enum NeoIconButtonVariant { primary, secondary, ghost }

/// Botón de icono con borde/sombra neo-brutalista.
class NeoIconButton extends StatelessWidget {
  const NeoIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.variant = NeoIconButtonVariant.primary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final NeoIconButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final SaveUpShadows shadows = theme.extension<SaveUpShadows>()!;
    final bool disabled = onPressed == null;
    final BorderSide side = BorderSide(
      color: colors.border,
      width: AppBorders.regular,
    );

    final Widget button = switch (variant) {
      NeoIconButtonVariant.primary => IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: colors.surfaceAlt,
          disabledForegroundColor: colors.muted,
          side: side,
          shape: const StadiumBorder(),
        ),
      ),
      NeoIconButtonVariant.secondary => IconButton.outlined(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.ink,
          disabledForegroundColor: colors.muted,
          side: side,
          shape: const StadiumBorder(),
        ),
      ),
      NeoIconButtonVariant.ghost => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        color: colors.ink,
        disabledColor: colors.muted,
      ),
    };

    if (variant == NeoIconButtonVariant.ghost || disabled) {
      return button;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillAll,
        boxShadow: shadows.sm,
      ),
      child: button,
    );
  }
}
