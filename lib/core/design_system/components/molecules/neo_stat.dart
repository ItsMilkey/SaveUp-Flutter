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
  });

  final String label;
  final Widget value;
  final String? helper;
  final IconData? icon;
  final Color accent;
  final AppDensity density;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return NeoSurface(
      density: density,
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
                    color: accent,
                    borderRadius: AppRadii.smAll,
                    border: Border.all(
                      color: colors.border,
                      width: AppBorders.regular,
                    ),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.ink),
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
                    color: colors.muted,
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
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
