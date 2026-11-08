import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_density.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../atoms/neo_surface.dart';

/// Tarjeta de métrica (KPI): etiqueta, valor y ayuda/delta.
class NeoStat extends StatelessWidget {
  const NeoStat({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    this.icon,
    this.accent = AppColors.yellow,
    this.density = AppDensity.section,
    this.color,
  });

  final String label;
  final Widget value;
  final String? helper;
  final IconData? icon;
  final Color accent;
  final AppDensity density;

  /// Fondo de color plano (tinta sobre el color, sin degradados).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final bool colorida = color != null;
    final Color foreground = colorida ? AppColors.ink : colors.muted;
    return NeoSurface(
      density: density,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorida ? colors.surface : accent,
                    borderRadius: AppRadii.smAll,
                    border: Border.all(
                      color: colors.border,
                      width: AppBorders.regular,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: colorida ? colors.ink : AppColors.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.text(
                    size: 11,
                    weight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          value,
          if (helper != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorida ? AppColors.ink : colors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
