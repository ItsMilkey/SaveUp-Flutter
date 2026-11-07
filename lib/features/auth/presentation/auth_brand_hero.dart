import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';

/// Cabecera de marca de las pantallas de autenticación.
class AuthBrandHero extends StatelessWidget {
  const AuthBrandHero({
    super.key,
    this.title = 'SaveUp',
    this.subtitle = 'Tus finanzas claras, al día.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.hero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.display(size: 36, color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: AppTypography.text(
                    size: 14,
                    weight: FontWeight.w500,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const ExcludeSemantics(child: _GeometricMark()),
        ],
      ),
    );
  }
}

/// Tres bloques de color: el acento gráfico del sistema.
class _GeometricMark extends StatelessWidget {
  const _GeometricMark();

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;

    Widget block(Color color) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: colors.border,
            width: AppBorders.thin,
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        block(AppColors.yellow),
        const SizedBox(height: AppSpacing.xs),
        block(AppColors.cyan),
        const SizedBox(height: AppSpacing.xs),
        block(AppColors.magenta),
      ],
    );
  }
}
