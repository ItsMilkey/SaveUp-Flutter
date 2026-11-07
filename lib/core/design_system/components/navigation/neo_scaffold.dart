import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';

/// Scaffold del sistema con fondo y navegación opcional.
class NeoScaffold extends StatelessWidget {
  const NeoScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final SaveUpColors colors = Theme.of(context).extension<SaveUpColors>()!;
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor ?? colors.canvas,
    );
  }
}
