import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../theme/saveup_shadows.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_density.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../atoms/neo_surface.dart';

class NeoMoreOption {
  const NeoMoreOption({
    required this.label,
    required this.icon,
    this.onTap,
    this.badge,
    this.showDividerBefore = false,
  });

  final String label;
  final IconData icon;

  /// `null` = opción deshabilitada (“Pronto”).
  final VoidCallback? onTap;
  final Widget? badge;
  final bool showDividerBefore;

  bool get enabled => onTap != null;
}

/// Hoja inferior «Más» con opciones de navegación/cuenta.
abstract final class NeoMoreMenu {
  static Future<void> show(
    BuildContext context, {
    String title = 'Más',
    required List<NeoMoreOption> options,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) =>
          _NeoMoreSheet(title: title, options: options),
    );
  }
}

class _NeoMoreSheet extends StatelessWidget {
  const _NeoMoreSheet({required this.title, required this.options});

  final String title;
  final List<NeoMoreOption> options;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final SaveUpShadows shadows = theme.extension<SaveUpShadows>()!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: NeoSurface(
          density: AppDensity.section,
          borderWidth: AppBorders.bold,
          boxShadow: shadows.lg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: AppRadii.pillAll,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final NeoMoreOption option in options) ...<Widget>[
                        if (option.showDividerBefore)
                          const Divider(height: AppSpacing.xl),
                        _MoreTile(option: option),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.option});

  final NeoMoreOption option;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final Color color = option.enabled ? colors.ink : colors.muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.smAll,
        onTap: option.enabled
            ? () {
                Navigator.of(context).pop();
                option.onTap!();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Icon(option.icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  option.label,
                  style: AppTypography.text(
                    size: 15,
                    weight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (option.badge != null) option.badge!,
            ],
          ),
        ),
      ),
    );
  }
}
