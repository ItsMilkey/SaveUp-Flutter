import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/money/money.dart';
import '../../domain/analitica.dart';
import 'analitica_colors.dart';

/// Barras de ingresos, gastos y ahorro de los últimos meses.
class BarrasMensualesCard extends StatelessWidget {
  const BarrasMensualesCard({super.key, required this.puntos});

  final List<PuntoMensual> puntos;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    if (puntos.isEmpty) {
      return NeoChartCard(
        title: 'Últimos 6 meses',
        isEmpty: true,
        empty: Text(
          'Sin historial de tendencia.',
          style: theme.textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        child: const SizedBox.shrink(),
      );
    }

    double maximo = 1;
    for (final PuntoMensual punto in puntos) {
      maximo = _mayor(maximo, punto.ingresos.toDouble());
      maximo = _mayor(maximo, punto.gastos.toDouble());
      maximo = _mayor(maximo, punto.ahorro.toDouble());
    }
    final double maxY = maximo * 1.15;

    final Color ingresos = colors.info;
    final Color gastos = AppColors.magenta;
    final Color ahorro = colors.success;

    return NeoChartCard(
      title: 'Últimos 6 meses',
      subtitle: 'Ingresos, gastos y ahorro',
      legend: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: <Widget>[
          _LeyendaPunto(color: ingresos, label: 'Ingresos'),
          _LeyendaPunto(color: gastos, label: 'Gastos'),
          _LeyendaPunto(color: ahorro, label: 'Ahorro'),
        ],
      ),
      child: Semantics(
        label:
            'Barras de ingresos, gastos y ahorro de los últimos '
            '${puntos.length} meses.',
        child: ExcludeSemantics(
          child: SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                groupsSpace: AppSpacing.sm,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.ink,
                    getTooltipItem:
                        (
                          BarChartGroupData group,
                          int groupIndex,
                          BarChartRodData rod,
                          int rodIndex,
                        ) {
                          final String etiqueta = switch (rodIndex) {
                            0 => 'Ingresos',
                            1 => 'Gastos',
                            _ => 'Ahorro',
                          };
                          return BarTooltipItem(
                            '$etiqueta\n${Money.formatClp(Decimal.parse(rod.toY.toStringAsFixed(2)))}',
                            AppTypography.text(
                              size: 12,
                              weight: FontWeight.w600,
                              color: colors.canvas,
                            ),
                          );
                        },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (double value) => FlLine(
                    color: colors.border.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= puntos.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            mesCorto(puntos[index].mes),
                            style: AppTypography.text(
                              size: 11,
                              weight: FontWeight.w600,
                              color: colors.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: <BarChartGroupData>[
                  for (int i = 0; i < puntos.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: <BarChartRodData>[
                        _rod(puntos[i].ingresos, ingresos),
                        _rod(puntos[i].gastos, gastos),
                        _rod(puntos[i].ahorro, ahorro),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static BarChartRodData _rod(Decimal valor, Color color) {
    return BarChartRodData(
      toY: valor.toDouble(),
      color: color,
      width: 7,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    );
  }

  static double _mayor(double actual, double candidato) =>
      candidato > actual ? candidato : actual;
}

class _LeyendaPunto extends StatelessWidget {
  const _LeyendaPunto({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadii.smAll,
            border: Border.all(
              color: colors.border,
              width: AppBorders.thin,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.text(
            size: 11,
            weight: FontWeight.w600,
            color: colors.muted,
          ),
        ),
      ],
    );
  }
}
