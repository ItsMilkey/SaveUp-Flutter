import 'package:flutter/material.dart';

import '../../theme/saveup_shadows.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_density.dart';
import '../../tokens/app_spacing.dart';
import '../atoms/neo_button.dart';
import '../atoms/neo_surface.dart';

/// Diálogo neo-brutalista con sombra dura y borde grueso.
class NeoDialog extends StatelessWidget {
  const NeoDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
    List<Widget> actions = const <Widget>[],
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => NeoDialog(title: title, actions: actions, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpShadows shadows = theme.extension<SaveUpShadows>()!;
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: NeoSurface(
        density: AppDensity.section,
        borderWidth: AppBorders.bold,
        boxShadow: shadows.lg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            child,
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirmación con acción destructiva opcional.
abstract final class NeoConfirmDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'Cancelar',
    String confirmLabel = 'Confirmar',
    bool destructive = false,
  }) {
    return NeoDialog.show<bool>(
      context,
      title: title,
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      actions: <Widget>[
        NeoButton(
          label: cancelLabel,
          variant: NeoButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        NeoButton(
          label: confirmLabel,
          variant: destructive
              ? NeoButtonVariant.danger
              : NeoButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
