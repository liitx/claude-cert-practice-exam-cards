import 'package:drill_deck/features/backup/backup_payload.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('stripFences', () {
    test('removes ```json fence', () {
      const wrapped = '```json\n{"kind":"deck"}\n```';
      expect(BackupImport.stripFences(wrapped), '{"kind":"deck"}');
    });
    test('removes plain ``` fence', () {
      const wrapped = '```\n{"kind":"deck"}\n```';
      expect(BackupImport.stripFences(wrapped), '{"kind":"deck"}');
    });
    test('removes leading/trailing whitespace and tilde fences', () {
      const wrapped = '   ~~~json\n{"kind":"deck"}\n~~~  ';
      expect(BackupImport.stripFences(wrapped), '{"kind":"deck"}');
    });
    test('leaves un-fenced JSON alone', () {
      const raw = '  {"kind":"deck"}  ';
      expect(BackupImport.stripFences(raw), '{"kind":"deck"}');
    });
    test('does not touch fences inside the payload', () {
      const inner = '{"q":"```code block```"}';
      expect(BackupImport.stripFences(inner), inner);
    });
    test('extracts JSON from the share body (HTML comment + fence)', () {
      const wrapped = '<!-- Submission via the Flutter app. -->\n\n'
          '```json\n{"kind":"deck"}\n```';
      expect(BackupImport.stripFences(wrapped), '{"kind":"deck"}');
    });
    test('strips a leading HTML comment before un-fenced JSON', () {
      const wrapped = '<!-- header -->\n{"kind":"deck"}';
      expect(BackupImport.stripFences(wrapped), '{"kind":"deck"}');
    });
  });

  group('import → save → reload', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('private deck survives a full storage reload', () async {
      const importJson = '''
{
  "kind": "deck",
  "deck": {
    "id": "imported-test",
    "name": "Imported Test Deck",
    "scenarios": {
      "S": {"label": "Subject", "color": "#5fb5e0"}
    },
    "cards": [
      {"id": "c1", "scn": "S", "topic": "t", "q": "Q1?", "a": "A1"}
    ]
  }
}''';

      final prefs1 = await SharedPreferences.getInstance();
      final storage1 = StorageRepository(prefs: prefs1);
      final initial = await storage1.hydrate();
      expect(initial.userDecks, isEmpty);

      final result = BackupImport.merge(importJson, initial);
      await storage1.save(result.snapshot);
      expect(result.snapshot.userDecks, hasLength(1));
      expect(result.snapshot.userDecks.first.name, 'Imported Test Deck');
      await storage1.dispose();

      // Fresh instance (same SharedPreferences-backed store).
      final prefs2 = await SharedPreferences.getInstance();
      final storage2 = StorageRepository(prefs: prefs2);
      final reloaded = await storage2.hydrate();
      expect(reloaded.userDecks, hasLength(1));
      expect(reloaded.userDecks.first.id, 'imported-test');
      expect(reloaded.userDecks.first.cards, hasLength(1));
      await storage2.dispose();
    });

    test('kind:all import (private deck + overlay) survives reload', () async {
      const importJson = '''
{
  "kind": "all",
  "userDecks": [
    {
      "id": "private-1",
      "name": "Private",
      "scenarios": {"X": {"label": "X", "color": "#7c83ff"}},
      "cards": [
        {"id": "p1", "scn": "X", "topic": "t", "q": "q", "a": "a"}
      ]
    }
  ],
  "overlay": {
    "cards": {
      "cca-f": [
        {"id": "o1", "scn": "CI", "topic": "t", "q": "q", "a": "a"}
      ]
    },
    "scenarios": {
      "cca-f": {"Z": {"label": "Z", "color": "#5fb89a"}}
    }
  },
  "progress": {
    "cca-f": {"ci1": "got"}
  }
}''';

      final prefs1 = await SharedPreferences.getInstance();
      final storage1 = StorageRepository(prefs: prefs1);
      final initial = await storage1.hydrate();

      final result = BackupImport.merge(importJson, initial);
      await storage1.save(result.snapshot);
      await storage1.dispose();

      final prefs2 = await SharedPreferences.getInstance();
      final storage2 = StorageRepository(prefs: prefs2);
      final reloaded = await storage2.hydrate();

      expect(reloaded.userDecks, hasLength(1));
      expect(reloaded.userDecks.first.id, 'private-1');
      expect(reloaded.overlayCards['cca-f'], hasLength(1));
      expect(reloaded.overlayScenarios['cca-f']!['Z']!.label, 'Z');
      expect(reloaded.progress['cca-f']!.containsKey('ci1'), isTrue);
      await storage2.dispose();
    });

    test('overlay cards survive a full storage reload', () async {
      const importJson = '''
{
  "kind": "overlay",
  "targetDeckId": "cca-f",
  "cards": [
    {"id": "extra-1", "scn": "CI", "topic": "t", "q": "Q?", "a": "A"}
  ],
  "scenarios": {
    "EX": {"label": "Extra", "color": "#5fb89a"}
  }
}''';

      final prefs1 = await SharedPreferences.getInstance();
      final storage1 = StorageRepository(prefs: prefs1);
      final initial = await storage1.hydrate();

      final result = BackupImport.merge(importJson, initial);
      await storage1.save(result.snapshot);
      await storage1.dispose();

      final prefs2 = await SharedPreferences.getInstance();
      final storage2 = StorageRepository(prefs: prefs2);
      final reloaded = await storage2.hydrate();

      expect(reloaded.overlayCards['cca-f'], hasLength(1));
      expect(reloaded.overlayCards['cca-f']!.first.id, 'extra-1');
      expect(reloaded.overlayScenarios['cca-f']!['EX']!.label, 'Extra');
      await storage2.dispose();
    });
  });
}
