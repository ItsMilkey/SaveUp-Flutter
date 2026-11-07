import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_density.dart';
import '../../tokens/app_radii.dart';
import '../../tokens/app_spacing.dart';
import '../atoms/neo_surface.dart';

/// Fila de lista neo-brutalista con leading/trailing opcionales.
class NeoListItem extends StatelessWidget {
  const NeoListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.density = AppDensity.list,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final AppDensity density;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return NeoSurface(
      density: density,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          if (accent != null) ...<Widget>[
            Container(
              width: 5,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: AppRadii.smAll,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
