import 'package:drill_deck/models/scenario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scenario', () {
    test('parses lowercases hex color', () {
      final s = Scenario.fromJson(const {'label': 'CI', 'color': '#7C83FF'});
      expect(s.label, 'CI');
      expect(s.color, '#7c83ff');
    });

    test('falls back to action color on invalid hex', () {
      final s = Scenario.fromJson(const {'label': 'X', 'color': 'not-hex'});
      expect(s.color, '#7c83ff');
    });

    test('argb getter produces a Color-compatible int', () {
      final s = Scenario.fromJson(const {'label': 'X', 'color': '#ffffff'});
      expect(s.argb, 0xffffffff);
    });

    test('round-trips through toJson', () {
      final s = Scenario.fromJson(const {'label': 'Multi-Agent', 'color': '#5fb89a'});
      final back = Scenario.fromJson(s.toJson());
      expect(back, s);
    });
  });
}
