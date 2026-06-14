import 'package:equatable/equatable.dart';

/// A scenario / subject label attached to cards. The hex color string is the
/// canonical wire format used in `decks.json`.
final class Scenario extends Equatable {
  const Scenario({
    required this.label,
    required this.color,
  });

  factory Scenario.fromJson(Map<String, Object?> json) {
    final label = json['label'] as String? ?? '';
    final color = json['color'] as String? ?? '#7c83ff';
    return Scenario(label: label, color: _normalizeHex(color));
  }

  /// 7-character hex string in the form `#rrggbb`. Lower-cased.
  final String label;
  final String color;

  static String _normalizeHex(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (RegExp(r'^#[0-9a-f]{6}$').hasMatch(trimmed)) return trimmed;
    return '#7c83ff';
  }

  /// Integer ARGB value suitable for `Color()` construction.
  int get argb => 0xff000000 | int.parse(color.substring(1), radix: 16);

  Map<String, Object?> toJson() => {'label': label, 'color': color};

  Scenario copyWith({String? label, String? color}) =>
      Scenario(label: label ?? this.label, color: color ?? this.color);

  @override
  List<Object?> get props => [label, color];
}
