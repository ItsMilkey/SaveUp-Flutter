import 'package:flutter/animation.dart';

/// Duraciones y curvas del sistema.
abstract final class AppMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration page = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;
}
