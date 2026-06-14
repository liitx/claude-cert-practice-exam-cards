import 'package:drill_deck/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Theme extension exposing the named slots used for scenario chips.
/// Lets widgets read intent (action / got / miss / danger) without hard-coding
/// hex literals.
@immutable
class ScenarioPalette extends ThemeExtension<ScenarioPalette> {
  const ScenarioPalette({
    required this.action,
    required this.got,
    required this.miss,
    required this.danger,
  });

  factory ScenarioPalette.dark() {
    return const ScenarioPalette(
      action: AppColors.action,
      got: AppColors.got,
      miss: AppColors.miss,
      danger: AppColors.danger,
    );
  }

  final Color action;
  final Color got;
  final Color miss;
  final Color danger;

  @override
  ScenarioPalette copyWith({
    Color? action,
    Color? got,
    Color? miss,
    Color? danger,
  }) {
    return ScenarioPalette(
      action: action ?? this.action,
      got: got ?? this.got,
      miss: miss ?? this.miss,
      danger: danger ?? this.danger,
    );
  }

  @override
  ScenarioPalette lerp(ThemeExtension<ScenarioPalette>? other, double t) {
    if (other is! ScenarioPalette) return this;
    return ScenarioPalette(
      action: Color.lerp(action, other.action, t) ?? action,
      got: Color.lerp(got, other.got, t) ?? got,
      miss: Color.lerp(miss, other.miss, t) ?? miss,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
    );
  }
}
