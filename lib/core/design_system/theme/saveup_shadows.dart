import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';

/// Sombras duras (blur 0) del sistema.
@immutable
class SaveUpShadows extends ThemeExtension<SaveUpShadows> {
  const SaveUpShadows({
    required this.sm,
    required this.md,
    required this.lg,
    required this.pressed,
  });

  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;
  final List<BoxShadow> pressed;

  static SaveUpShadows light() {
    return SaveUpShadows(
      sm: _hard(AppColors.ink, 2),
      md: _hard(AppColors.ink, 4),
      lg: _hard(AppColors.ink, 6),
      pressed: _hard(AppColors.ink, 1),
    );
  }

  static SaveUpShadows dark() {
    final Color shadow = AppColors.darkText.withValues(alpha: 0.24);
    return SaveUpShadows(
      sm: _hard(shadow, 2),
      md: _hard(shadow, 4),
      lg: _hard(shadow, 6),
      pressed: _hard(shadow, 1),
    );
  }

  static List<BoxShadow> _hard(Color color, double offset) {
    return <BoxShadow>[
      BoxShadow(
        color: color,
        offset: Offset(offset, offset),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }

  List<BoxShadow>? forLevel(AppShadowLevel level) {
    return switch (level) {
      AppShadowLevel.none => null,
      AppShadowLevel.sm => sm,
      AppShadowLevel.md => md,
      AppShadowLevel.lg => lg,
    };
  }

  @override
  SaveUpShadows copyWith({
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? pressed,
  }) {
    return SaveUpShadows(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      pressed: pressed ?? this.pressed,
    );
  }

  @override
  SaveUpShadows lerp(ThemeExtension<SaveUpShadows>? other, double t) {
    if (other is! SaveUpShadows) {
      return this;
    }
    return SaveUpShadows(
      sm: BoxShadow.lerpList(sm, other.sm, t) ?? sm,
      md: BoxShadow.lerpList(md, other.md, t) ?? md,
      lg: BoxShadow.lerpList(lg, other.lg, t) ?? lg,
      pressed: BoxShadow.lerpList(pressed, other.pressed, t) ?? pressed,
    );
  }
}
