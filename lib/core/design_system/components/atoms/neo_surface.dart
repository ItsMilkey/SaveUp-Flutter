import 'package:flutter/material.dart';

import '../../theme/saveup_colors.dart';
import '../../theme/saveup_shadows.dart';
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
    final Widget content = Padding(
      padding: padding ?? EdgeInsets.all(density.padding),
      child: child,
    );

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
