import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

enum NeoSnackbarTone { neutral, success, warning, danger, info }

/// SnackBar con tono semántico y acción opcional.
abstract final class NeoSnackbar {
  static void show(
    BuildContext context,
    String message, {
    NeoSnackbarTone tone = NeoSnackbarTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final (Color background, Color foreground, IconData icon) =
        switch (tone) {
          NeoSnackbarTone.neutral => (
            colors.ink,
            colors.canvas,
            Icons.info_outline,
          ),
          NeoSnackbarTone.success => (
            colors.success,
            colors.onSuccess,
            Icons.check_circle_outline,
          ),
          NeoSnackbarTone.warning => (
            colors.warning,
            colors.onWarning,
            Icons.warning_amber_rounded,
          ),
          NeoSnackbarTone.danger => (
            theme.colorScheme.error,
            AppColors.ink,
            Icons.error_outline,
          ),
          NeoSnackbarTone.info => (
            colors.info,
            colors.onInfo,
            Icons.info_outline,
          ),
        };

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          duration: const Duration(seconds: 4),
          content: Row(
            children: <Widget>[
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.text(
                    size: 14,
                    weight: FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: foreground,
                  onPressed: onAction ?? () {},
                ),
        ),
      );
  }
}
