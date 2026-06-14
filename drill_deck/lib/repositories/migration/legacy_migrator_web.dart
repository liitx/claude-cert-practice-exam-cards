import 'dart:convert';

import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/repositories/migration/legacy_migrator.dart';
import 'package:web/web.dart' as web;

/// Web implementation: reads `window.localStorage['drill-decks-v2']` and
/// hands it to [AppStateSnapshot.fromJson]. Tolerates malformed JSON by
/// returning null.
class LegacyMigratorImpl implements LegacyMigrator {
  static const _key = 'drill-decks-v2';

  @override
  AppStateSnapshot? migrate() {
    final storage = web.window.localStorage;
    final raw = storage.getItem(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AppStateSnapshot.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  @override
  void clearLegacy() {
    web.window.localStorage.removeItem(_key);
  }
}
