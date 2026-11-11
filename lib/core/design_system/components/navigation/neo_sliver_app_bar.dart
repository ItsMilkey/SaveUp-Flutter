import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_borders.dart';
import '../../tokens/app_typography.dart';

/// AppBar de sliver para pantallas con scroll propio.
///
/// Con [floating] y [snap] la barra se oculta al deslizar hacia abajo y
/// reaparece en cuanto el usuario vuelve a subir, con la animación nativa.
///
/// [brand] usa la tipografía de marca (Archivo Black) con un subrayado
/// amarillo, en lugar del título de pantalla habitual.
class NeoSliverAppBar extends StatelessWidget {
  const NeoSliverAppBar({
    super.key,
    required this.title,
    this.brand = false,
    this.centerTitle = false,
    this.leading,
    this.actions = const <Widget>[],
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.toolbarHeight = kToolbarHeight,
  });

  final String title;
  final bool brand;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool floating;
  final bool pinned;
  final bool snap;
  final double toolbarHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return SliverAppBar(
      toolbarHeight: toolbarHeight,
      title: brand
          ? Text(
              title,
              maxLines: 1,
              style: AppTypography.display(size: 28, color: colors.ink),
            )
          : Text(title),
      titleTextStyle: brand ? null : theme.textTheme.headlineSmall,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      floating: floating,
      pinned: pinned,
      snap: snap,
      backgroundColor: colors.canvas,
      foregroundColor: colors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(
        bottom: BorderSide(
          color: colors.border,
          width: AppBorders.regular,
        ),
      ),
    );
  }
}
