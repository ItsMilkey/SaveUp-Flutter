import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../theme/saveup_shadows.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_density.dart';
import '../../tokens/app_spacing.dart';
import '../atoms/neo_surface.dart';

/// Estado vacío con icono geométrico y acción opcional.
class NeoEmptyState extends StatelessWidget {
  const NeoEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.accent = AppColors.yellow,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final SaveUpShadows shadows = theme.extension<SaveUpShadows>()!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NeoSurface(
            density: AppDensity.table,
            color: accent,
            padding: const EdgeInsets.all(AppSpacing.lg),
            boxShadow: shadows.md,
            child: Icon(icon, size: 32, color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
