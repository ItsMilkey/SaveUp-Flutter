import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../theme/saveup_shadows.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

class NeoBottomDestination {
  const NeoBottomDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

/// Barra inferior flotante tipo píldora con sombra dura.
class NeoBottomNav extends StatelessWidget {
  const NeoBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<NeoBottomDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final SaveUpShadows shadows = theme.extension<SaveUpShadows>()!;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadii.pillAll,
          border: Border.all(
            color: colors.border,
            width: AppBorders.regular,
          ),
          boxShadow: shadows.lg,
        ),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NeoNavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoNavItem extends StatelessWidget {
  const _NeoNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NeoBottomDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return InkWell(
      borderRadius: AppRadii.pillAll,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.yellow : Colors.transparent,
          borderRadius: AppRadii.pillAll,
          border: selected
              ? Border.all(
                  color: colors.border,
                  width: AppBorders.thin,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              selected
                  ? (destination.selectedIcon ?? destination.icon)
                  : destination.icon,
              size: 20,
              color: selected ? colors.ink : colors.muted,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                destination.label,
                style: AppTypography.text(
                  size: 10,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.ink : colors.muted,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
