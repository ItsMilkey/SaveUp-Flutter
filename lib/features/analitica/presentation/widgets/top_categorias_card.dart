import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/analitica.dart';
import 'analitica_colors.dart';

/// Tabla accesible de las categorías con más gasto del mes.
class TopCategoriasCard extends StatelessWidget {
  const TopCategoriasCard({super.key, required this.categorias});

  final List<GastoCategoria> categorias;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return NeoSurface(
      density: AppDensity.section,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NeoSectionHeader(title: 'Top categorías'),
          if (categorias.isEmpty)
            Text(
              'Sin gastos por categoría este mes.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
            )
          else
            for (int i = 0; i < categorias.length; i++) ...<Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorDeCategoria(context, categorias[i], i),
                      borderRadius: AppRadii.smAll,
                      border: Border.all(
                        color: colors.border,
                        width: AppBorders.thin,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      categorias[i].nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    formatearPorcentaje(categorias[i].porcentaje),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  NeoMoneyText(
                    amount: categorias[i].monto,
                    size: NeoMoneySize.body,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              NeoProgress(
                value: categorias[i].porcentaje.toDouble() / 100,
                color: colorDeCategoria(context, categorias[i], i),
                height: 6,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}
