import 'package:flutter/material.dart';

/// Monospace text styles used for scenario chips, topic labels, counters,
/// and flip hints. Falls back across SF Mono, Menlo, Consolas.
@immutable
class MonoTypography extends ThemeExtension<MonoTypography> {
  const MonoTypography({
    required this.chip,
    required this.topic,
    required this.counter,
    required this.hint,
  });

  factory MonoTypography.dark() {
    const fallback = ['SF Mono', 'Menlo', 'Consolas', 'monospace'];
    const base = TextStyle(
      fontFamilyFallback: fallback,
      letterSpacing: 0.4,
    );
    return MonoTypography(
      chip: base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.0,
      ),
      topic: base.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF8B909E),
      ),
      counter: base.copyWith(
        fontSize: 12,
        color: const Color(0xFF8B909E),
      ),
      hint: base.copyWith(
        fontSize: 11,
        color: const Color(0xFF5B606D),
      ),
    );
  }

  final TextStyle chip;
  final TextStyle topic;
  final TextStyle counter;
  final TextStyle hint;

  @override
  MonoTypography copyWith({
    TextStyle? chip,
    TextStyle? topic,
    TextStyle? counter,
    TextStyle? hint,
  }) {
    return MonoTypography(
      chip: chip ?? this.chip,
      topic: topic ?? this.topic,
      counter: counter ?? this.counter,
      hint: hint ?? this.hint,
    );
  }

  @override
  MonoTypography lerp(ThemeExtension<MonoTypography>? other, double t) {
    if (other is! MonoTypography) return this;
    return MonoTypography(
      chip: TextStyle.lerp(chip, other.chip, t) ?? chip,
      topic: TextStyle.lerp(topic, other.topic, t) ?? topic,
      counter: TextStyle.lerp(counter, other.counter, t) ?? counter,
      hint: TextStyle.lerp(hint, other.hint, t) ?? hint,
    );
  }
}
