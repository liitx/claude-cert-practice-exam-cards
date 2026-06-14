import 'dart:async';
import 'dart:convert';

import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/repositories/migration/legacy_migrator.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [SharedPreferences] for persisting [AppStateSnapshot]. Exposes a
/// broadcast stream of snapshots so Blocs can react to writes without polling.
class StorageRepository {
  StorageRepository({
    required SharedPreferences prefs,
    LegacyMigrator? legacyMigrator,
  })  : _prefs = prefs,
        _legacyMigrator = legacyMigrator;

  static const stateKey = 'drill-decks-v2';
  static const migratedFlagKey = 'migrated_v1';
  static const secondLaunchKey = 'migrated_v1_seen';

  final SharedPreferences _prefs;
  final LegacyMigrator? _legacyMigrator;
  final _controller = BehaviorSubject<AppStateSnapshot>();

  Stream<AppStateSnapshot> watch() => _controller.stream;
  AppStateSnapshot? get current =>
      _controller.hasValue ? _controller.value : null;

  /// Loads existing state, runs the legacy migrator on first launch, and
  /// returns the resolved snapshot. Safe to call exactly once at startup.
  Future<AppStateSnapshot> hydrate() async {
    var snapshot = _loadStored();

    final migrator = _legacyMigrator;
    if (snapshot == null && migrator != null && !_prefs.getBool(migratedFlagKey).orFalse) {
      final migrated = migrator.migrate();
      if (migrated != null) {
        snapshot = migrated;
        await _saveSnapshot(migrated);
        await _prefs.setBool(migratedFlagKey, true);
      }
    } else if (_prefs.getBool(migratedFlagKey) == true &&
        !_prefs.getBool(secondLaunchKey).orFalse) {
      // Second successful launch — safe to clear the legacy localStorage key
      // (handled by the migrator) and record that we've seen it.
      migrator?.clearLegacy();
      await _prefs.setBool(secondLaunchKey, true);
    }

    snapshot ??= AppStateSnapshot.initial();
    _controller.add(snapshot);
    return snapshot;
  }

  Future<void> save(AppStateSnapshot snapshot) async {
    await _saveSnapshot(snapshot);
    _controller.add(snapshot);
  }

  Future<void> _saveSnapshot(AppStateSnapshot snapshot) async {
    await _prefs.setString(stateKey, jsonEncode(snapshot.toJson()));
  }

  AppStateSnapshot? _loadStored() {
    final raw = _prefs.getString(stateKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AppStateSnapshot.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

extension on bool? {
  bool get orFalse => this ?? false;
}
