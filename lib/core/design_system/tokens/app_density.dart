import 'app_shadows.dart';

/// Densidad por jerarquía de información.
///
/// “Si todo es denso, nada lo es”: los resúmenes respiran (`hero`), los
/// formularios usan `section`, las listas `list` y las tablas/leyendas `table`.
enum AppDensity {
  hero(padding: 24, borderWidth: 3, shadow: AppShadowLevel.lg),
  section(padding: 16, borderWidth: 2, shadow: AppShadowLevel.md),
  list(padding: 12, borderWidth: 1.5, shadow: AppShadowLevel.sm),
  table(padding: 8, borderWidth: 1, shadow: AppShadowLevel.none);

  const AppDensity({
    required this.padding,
    required this.borderWidth,
    required this.shadow,
  });

  final double padding;
  final double borderWidth;
  final AppShadowLevel shadow;
}
