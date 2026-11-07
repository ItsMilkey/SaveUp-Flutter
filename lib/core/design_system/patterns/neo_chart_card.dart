import 'package:flutter/material.dart';

import '../components/atoms/neo_card.dart';
import '../components/molecules/neo_empty_state.dart';
import '../components/molecules/neo_section_header.dart';
import '../tokens/app_density.dart';
import '../tokens/app_spacing.dart';

/// Tarjeta contenedora para gráficos (torta, barras) con título/leyenda.
class NeoChartCard extends StatelessWidget {
  const NeoChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.legend,
    this.empty,
    this.isEmpty = false,
    this.density = AppDensity.section,
  });

  final String title;
  final String? subtitle;
  final Widget? legend;
  final Widget child;
  final Widget? empty;
  final bool isEmpty;
  final AppDensity density;

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      density: density,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NeoSectionHeader(
            title: title,
            subtitle: subtitle,
            padding: EdgeInsets.zero,
          ),
          if (legend != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            legend!,
          ],
          const SizedBox(height: AppSpacing.md),
          if (isEmpty)
            empty ??
                const NeoEmptyState(
                  title: 'Sin datos',
                  message: 'No hay información para este período.',
                  icon: Icons.bar_chart_outlined,
                )
          else
            child,
        ],
      ),
    );
  }
}
