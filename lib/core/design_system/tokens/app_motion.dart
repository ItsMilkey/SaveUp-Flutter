import 'package:flutter/widgets.dart';

/// Duraciones y curvas del sistema.
///
/// La intención (press/fast/page) vive aquí; la animación concreta se elige en
/// cada componente. Para respetar la preferencia del sistema se usa [respect]
/// en lugar de la duración cruda.
abstract final class AppMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration page = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;

  /// Escala de un press táctil. El desplazamiento del neo-brutalismo va aparte:
  /// el componente se mueve `(2,2)` y pierde sombra; nunca se agranda.
  static const double pressedScale = 0.96;

  /// Duración efectiva: cero cuando el sistema pide reducir movimiento.
  ///
  /// Devuelve `Duration.zero` si `MediaQuery.disableAnimations` está activo, de
  /// modo que el cambio de estado sigue ocurriendo (color, icono, texto) pero
  /// sin transición. No sustituye al cambio de estado: lo acompaña.
  static Duration respect(BuildContext context, Duration duration) {
    final MediaQueryData? data = MediaQuery.maybeOf(context);
    if (data != null && data.disableAnimations) {
      return Duration.zero;
    }
    return duration;
  }
}
