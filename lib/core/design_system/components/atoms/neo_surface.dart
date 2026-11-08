import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../theme/saveup_shadows.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_density.dart';
import '../../tokens/app_radii.dart';

/// Superficie base neo-brutalista: color, borde grueso y sombra dura.
class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.density = AppDensity.section,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.radius,
    this.boxShadow,
    this.padding,
    this.onTap,
    this.textColor,
  });

  final Widget child;
  final AppDensity density;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? radius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  /// Color del texto/iconos sobre [color]. Por defecto, tinta si hay fondo.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SaveUpColors colors = theme.extension<SaveUpColors>()!;
    final SaveUpShadows shadowTokens = theme.extension<SaveUpShadows>()!;
    final BorderRadius effectiveRadius = radius ?? AppRadii.mdAll;
    final BorderSide side = BorderSide(
      color: borderColor ?? colors.border,
      width: borderWidth ?? density.borderWidth,
    );
    final Color? foreground =
        textColor ?? (color == null ? null : AppColors.ink);
    Widget content = Padding(
      padding: padding ?? EdgeInsets.all(density.padding),
      child: child,
    );
    if (foreground != null) {
      content = Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme.apply(
            bodyColor: foreground,
            displayColor: foreground,
          ),
          primaryTextTheme: theme.primaryTextTheme.apply(
            bodyColor: foreground,
            displayColor: foreground,
          ),
          iconTheme: IconThemeData(color: foreground),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: content,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: effectiveRadius,
        border: Border.all(color: side.color, width: side.width),
        boxShadow: boxShadow ?? shadowTokens.forLevel(density.shadow),
      ),
      child: onTap == null
          ? content
          : ClipRRect(
              borderRadius: effectiveRadius,
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: content),
              ),
            ),
    );
  }
}
