import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

/// Barra de progreso con pista bordeada y relleno sólido.
///
/// [value] es 0..1 y solo representa la posición visual: el dinero/porcentajes
/// se calculan fuera del design system con `Decimal`.
class NeoProgress extends StatelessWidget {
  const NeoProgress({
    super.key,
    required this.value,
    this.color = AppColors.yellow,
    this.height = 10,
    this.label,
  });

  final double value;
  final Color color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: AppTypography.text(
              size: 12,
              weight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          height: height + 4,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadii.pillAll,
            border: Border.all(
              color: colors.border,
              width: AppBorders.regular,
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadii.pillAll,
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: height,
              backgroundColor: Colors.transparent,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
