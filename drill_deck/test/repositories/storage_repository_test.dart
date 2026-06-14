import 'dart:convert';

import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/progress_state.dart';
import 'package:drill_deck/models/study_filter.dart';
import 'package:drill_deck/repositories/migration/legacy_migrator.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubMigrator implements LegacyMigrator {
  _StubMigrator(this._snapshot);
  final AppStateSnapshot? _snapshot;
  bool cleared = false;

  @override
  AppStateSnapshot? migrate() => _snapshot;

  @override
  void clearLegacy() {
    cleared = true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageRepository.hydrate', () {
    test('returns initial state when nothing is stored and no migrator', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StorageRepository(prefs: prefs);
      final snap = await repo.hydrate();
      expect(snap, AppStateSnapshot.initial());
      await repo.dispose();
    });

    test('runs migrator on first launch and persists result', () async {
      final prefs = await SharedPreferences.getInstance();
      final migrated = AppStateSnapshot.fromJson(const {
        'currentDeckId': 'cca-f',
        'progress': {
          'cca-f': {'ci1': 'review'},
        },
      });
      final migrator = _StubMigrator(migrated);
      final repo = StorageRepository(prefs: prefs, legacyMigrator: migrator);

      final snap = await repo.hydrate();
      expect(snap.progress['cca-f']!['ci1'], ProgressState.review);
      expect(prefs.getBool(StorageRepository.migratedFlagKey), isTrue);
      final stored = prefs.getString(StorageRepository.stateKey);
      expect(stored, isNotNull);
      final decoded = jsonDecode(stored!) as Map<String, Object?>;
      expect(decoded['currentDeckId'], 'cca-f');
      await repo.dispose();
    });

    test('skips migrator when migrated_v1 is already set', () async {
      SharedPreferences.setMockInitialValues({
        StorageRepository.migratedFlagKey: true,
        StorageRepository.stateKey: jsonEncode(
          AppStateSnapshot.fromJson(const {
            'currentDeckId': 'cca-f',
            'view': {'filter': 'all', 'idx': 4},
          }).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      final migrator = _StubMigrator(null);
      final repo = StorageRepository(prefs: prefs, legacyMigrator: migrator);

      final snap = await repo.hydrate();
      expect(snap.cardIndex, 4);
      expect(snap.filter, StudyFilter.all);
      expect(migrator.cleared, isTrue);
      await repo.dispose();
    });

    test('save() persists and broadcasts on the stream', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = StorageRepository(prefs: prefs);
      await repo.hydrate();

      final next = AppStateSnapshot.initial().copyWith(cardIndex: 9);
      final received = <AppStateSnapshot>[];
      final sub = repo.watch().listen(received.add);
      await repo.save(next);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received.last, next);
      final stored = prefs.getString(StorageRepository.stateKey);
      expect(stored, contains('"idx":9'));
      await repo.dispose();
    });

    test('returns initial state when stored payload is corrupt', () async {
      SharedPreferences.setMockInitialValues({
        StorageRepository.stateKey: 'not-json',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = StorageRepository(prefs: prefs);
      final snap = await repo.hydrate();
      expect(snap, AppStateSnapshot.initial());
      await repo.dispose();
    });
  });
}
