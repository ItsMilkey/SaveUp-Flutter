import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_density.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../atoms/neo_surface.dart';

/// Cargando con esqueleto (evita bloquear la pantalla completa si hay datos).
class NeoLoading extends StatelessWidget {
  const NeoLoading({
    super.key,
    this.message = 'Cargando…',
    this.rows = 3,
  });

  final String message;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return Semantics(
      label: message,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (message.isNotEmpty) ...<Widget>[
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            for (int i = 0; i < rows; i++) ...<Widget>[
              NeoSurface(
                density: AppDensity.table,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: AppRadii.smAll,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.surfaceAlt,
                          borderRadius: AppRadii.smAll,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
