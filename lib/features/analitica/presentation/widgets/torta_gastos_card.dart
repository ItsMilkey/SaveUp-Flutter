import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/money/money.dart';
import '../../domain/analitica.dart';
import 'analitica_colors.dart';

/// Torta de gastos por categoría con leyenda seleccionable.
class TortaGastosCard extends StatefulWidget {
  const TortaGastosCard({
    super.key,
    required this.categorias,
    required this.total,
  });

  final List<GastoCategoria> categorias;
  final Decimal total;

  @override
  State<TortaGastosCard> createState() => _TortaGastosCardState();
}

class _TortaGastosCardState extends State<TortaGastosCard> {
  int? _seleccion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;

    if (widget.categorias.isEmpty) {
      return NeoChartCard(
        title: 'Gastos por categoría',
        subtitle: 'Total ${Money.formatClp(widget.total)}',
        isEmpty: true,
        empty: Text(
          'Sin gastos por categoría este mes.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        child: const SizedBox.shrink(),
      );
    }

    final List<PieChartSectionData> secciones = <PieChartSectionData>[
      for (int i = 0; i < widget.categorias.length; i++)
        PieChartSectionData(
          value: widget.categorias[i].monto.toDouble(),
          color: colorDeCategoria(context, widget.categorias[i], i),
          radius: _seleccion == i ? 62 : 56,
          title: widget.categorias[i].porcentaje >= Decimal.fromInt(8)
              ? '${widget.categorias[i].porcentaje.round(scale: 1).toStringAsFixed(1)}%'
              : '',
          titleStyle: AppTypography.text(
            size: 10,
            weight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titlePositionPercentageOffset: 0.58,
        ),
    ];

    return NeoChartCard(
      title: 'Gastos por categoría',
      subtitle: 'Total ${Money.formatClp(widget.total)}',
      child: Column(
        children: <Widget>[
          Semantics(
            label:
                'Torta de gastos por categoría. Total '
                '${Money.formatClp(widget.total)}.',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 230,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    PieChart(
                      PieChartData(
                        sections: secciones,
                        centerSpaceRadius: 54,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, response) {
                            if (!event.isInterestedForInteractions) {
                              return;
                            }
                            final int? index =
                                response?.touchedSection?.touchedSectionIndex;
                            if (index == null || index < 0) {
                              return;
                            }
                            setState(() => _seleccion = index);
                          },
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.muted,
                          ),
                        ),
                        NeoMoneyText(
                          amount: widget.total,
                          size: NeoMoneySize.title,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: <Widget>[
              for (int i = 0; i < widget.categorias.length; i++)
                _LeyendaFila(
                  categoria: widget.categorias[i],
                  color: colorDeCategoria(context, widget.categorias[i], i),
                  seleccionada: _seleccion == i,
                  onTap: () => setState(() => _seleccion = i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeyendaFila extends StatelessWidget {
  const _LeyendaFila({
    required this.categoria,
    required this.color,
    required this.seleccionada,
    required this.onTap,
  });

  final GastoCategoria categoria;
  final Color color;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: BoxDecoration(
          color: seleccionada ? colors.surfaceAlt : null,
          borderRadius: AppRadii.smAll,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
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
                categoria.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.text(
                  size: 13,
                  weight: seleccionada ? FontWeight.w700 : FontWeight.w500,
                  color: colors.ink,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatearPorcentaje(categoria.porcentaje),
              style: AppTypography.text(
                size: 12,
                weight: FontWeight.w600,
                color: colors.muted,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            NeoMoneyText(
              amount: categoria.monto,
              size: NeoMoneySize.body,
            ),
          ],
        ),
      ),
    );
  }
}
