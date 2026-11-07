import 'package:flutter/material.dart';

import '../components/atoms/neo_icon_button.dart';
import '../components/atoms/neo_surface.dart';
import '../tokens/app_density.dart';

/// Selector de mes/año con flechas, sin acoplarse a `BusinessMonth`.
class NeoMonthPicker extends StatelessWidget {
  const NeoMonthPicker({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.enabled = true,
    this.previousTooltip = 'Mes anterior',
    this.nextTooltip = 'Mes siguiente',
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool enabled;
  final String previousTooltip;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return NeoSurface(
      density: AppDensity.list,
      child: Row(
        children: <Widget>[
          NeoIconButton(
            icon: Icons.chevron_left,
            tooltip: previousTooltip,
            variant: NeoIconButtonVariant.ghost,
            onPressed: enabled ? onPrevious : null,
          ),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          NeoIconButton(
            icon: Icons.chevron_right,
            tooltip: nextTooltip,
            variant: NeoIconButtonVariant.ghost,
            onPressed: enabled ? onNext : null,
          ),
        ],
      ),
    );
  }
}
