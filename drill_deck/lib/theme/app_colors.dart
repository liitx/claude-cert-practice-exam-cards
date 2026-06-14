import 'package:flutter/material.dart';

/// Raw color palette pulled from the static-site CSS variables.
///
/// See the source at `index.html` (lines 13-19) for the original definitions.
abstract final class AppColors {
  static const ink = Color(0xFF13151A);
  static const surface = Color(0xFF1B1E26);
  static const surface2 = Color(0xFF222632);

  static const text = Color(0xFFE9EAEF);
  static const muted = Color(0xFF8B909E);
  static const faint = Color(0xFF5B606D);
  static const line = Color(0xFF2A2E3A);

  static const action = Color(0xFF7C83FF);
  static const got = Color(0xFF5FB89A);
  static const miss = Color(0xFFE0A458);
  static const danger = Color(0xFFD97A8A);

  /// Default scenario chip colors used by the seed CCA-F deck.
  static const ci = Color(0xFF7C83FF);
  static const ma = Color(0xFF5FB89A);
  static const cg = Color(0xFFE0A458);
  static const cs = Color(0xFFD97A8A);
}
