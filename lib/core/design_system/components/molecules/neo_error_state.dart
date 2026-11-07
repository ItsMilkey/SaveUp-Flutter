import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../atoms/neo_button.dart';
import 'neo_empty_state.dart';

/// Estado de error con reintento.
class NeoErrorState extends StatelessWidget {
  const NeoErrorState({
    super.key,
    required this.message,
    this.title = 'Algo salió mal',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return NeoEmptyState(
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      accent: AppColors.danger,
      action: onRetry == null
          ? null
          : NeoButton(
              label: 'Reintentar',
              variant: NeoButtonVariant.secondary,
              onPressed: onRetry,
            ),
    );
  }
}
