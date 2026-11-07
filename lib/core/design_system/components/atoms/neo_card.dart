import 'package:flutter/material.dart';

import '../../tokens/app_density.dart';
import 'neo_surface.dart';

/// Tarjeta neo-brutalista con densidad configurable.
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.density = AppDensity.section,
    this.color,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final AppDensity density;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeoSurface(
      density: density,
      color: color,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}
