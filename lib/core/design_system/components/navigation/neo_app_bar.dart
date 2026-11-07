import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../tokens/app_borders.dart';

/// AppBar neo-brutalista con borde inferior.
class NeoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NeoAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const <Widget>[],
    this.bottom,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    return AppBar(
      title: Text(title, style: theme.textTheme.headlineSmall),
      leading: leading,
      actions: actions,
      bottom: bottom,
      backgroundColor: colors.canvas,
      foregroundColor: colors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(
          color: colors.border,
          width: AppBorders.regular,
        ),
      ),
    );
  }
}
