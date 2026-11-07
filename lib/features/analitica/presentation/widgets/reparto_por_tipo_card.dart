import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/money/money.dart';
import '../../domain/analitica.dart';
import 'analitica_colors.dart';

/// Reparto del gasto por tipo efectivo (necesidades/deseos/otros/ahorro).
class RepartoPorTipoCard extends StatelessWidget {
  const RepartoPorTipoCard({super.key, required this.tipos});

  final List<GastoPorTipo> tipos;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Reparto por tipo'),
          if (tipos.isEmpty)
            Text(
              'Sin gastos por tipo este mes.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            )
          else
            for (final GastoPorTipo tipo in tipos) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      labelDeTipo(tipo.tipo),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${Money.formatClp(tipo.monto)} · '
                    '${formatearPorcentaje(tipo.porcentaje)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              NeoProgress(
                value: tipo.porcentaje.toDouble() / 100,
                color: colorDeTipo(context, tipo.tipo),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}
