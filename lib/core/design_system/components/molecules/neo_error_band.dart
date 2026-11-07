import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_density.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../atoms/neo_surface.dart';

/// Banda de error de formulario: el `detail` del backend se ve inline,
/// no en un toast que se escapa.
class NeoErrorBand extends StatelessWidget {
  const NeoErrorBand({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.table,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderColor: colors.negativeText,
      borderWidth: AppBorders.regular,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline, size: 18, color: colors.negativeText),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.text(
                size: 13,
                weight: FontWeight.w500,
                color: colors.negativeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
