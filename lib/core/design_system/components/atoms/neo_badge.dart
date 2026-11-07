import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

/// Etiqueta compacta con borde (estado, categoría, contador).
class NeoBadge extends StatelessWidget {
  const NeoBadge({
    super.key,
    required this.label,
    this.color = AppColors.yellow,
    this.textColor,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    final Color foreground = textColor ?? AppColors.ink;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.pillAll,
        border: Border.all(
          color: colors.border,
          width: AppBorders.thin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.text(
              size: 11,
              weight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
