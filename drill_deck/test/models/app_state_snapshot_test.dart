import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/progress_state.dart';
import 'package:drill_deck/models/study_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStateSnapshot', () {
    test('initial returns sensible defaults', () {
      final s = AppStateSnapshot.initial();
      expect(s.currentDeckId, 'cca-f');
      expect(s.userDecks, isEmpty);
      expect(s.overlayCards, isEmpty);
      expect(s.overlayScenarios, isEmpty);
      expect(s.progress, isEmpty);
      expect(s.hiddenDecks, isEmpty);
      expect(s.filter, StudyFilter.miss);
      expect(s.cardIndex, 0);
    });

    test('fromJson reads the legacy-shape map', () {
      final json = <String, Object?>{
        'currentDeckId': 'cca-f',
        'userDecks': [
          {
            'id': 'd1',
            'name': 'My Deck',
            'scenarios': {
              'X': {'label': 'X', 'color': '#7c83ff'},
            },
            'cards': [
              {
                'id': 'c1',
                'scn': 'X',
                'topic': 't',
                'q': 'q',
                'a': 'a',
              },
            ],
          },
        ],
        'overlay': {
          'cards': {
            'cca-f': [
              {
                'id': 'u1',
                'scn': 'CI',
                'topic': 't',
                'q': 'q',
                'a': 'a',
              },
            ],
          },
          'scenarios': {
            'cca-f': {
              'NEW': {'label': 'New', 'color': '#5fb89a'},
            },
          },
        },
        'progress': {
          'cca-f': {'ci1': 'review', 'ci2': 'got', 'bad': 'nope'},
        },
        'hiddenDecks': ['hidden-deck'],
        'view': {'filter': 'all', 'idx': 3},
      };

      final snapshot = AppStateSnapshot.fromJson(json);

      expect(snapshot.currentDeckId, 'cca-f');
      expect(snapshot.userDecks, hasLength(1));
      expect(snapshot.userDecks.first.cards.first.userOwned, isTrue);
      expect(snapshot.overlayCards['cca-f'], hasLength(1));
      expect(snapshot.overlayCards['cca-f']!.first.userOwned, isTrue);
      expect(snapshot.overlayScenarios['cca-f']!['NEW']!.label, 'New');
      expect(snapshot.progress['cca-f']!['ci1'], ProgressState.review);
      expect(snapshot.progress['cca-f']!['ci2'], ProgressState.got);
      expect(snapshot.progress['cca-f']!.containsKey('bad'), isFalse);
      expect(snapshot.hiddenDecks, ['hidden-deck']);
      expect(snapshot.filter, StudyFilter.all);
      expect(snapshot.cardIndex, 3);
    });

    test('falls back to initial defaults for malformed/missing fields', () {
      final snapshot = AppStateSnapshot.fromJson(const {});
      expect(snapshot.currentDeckId, 'cca-f');
      expect(snapshot.userDecks, isEmpty);
      expect(snapshot.filter, StudyFilter.miss);
    });

    test('round-trips toJson -> fromJson', () {
      final original = AppStateSnapshot.fromJson(const {
        'currentDeckId': 'cca-f',
        'overlay': {
          'cards': {
            'cca-f': [
              {'id': 'u', 'scn': 'CI', 'topic': 't', 'q': 'q', 'a': 'a'},
            ],
          },
          'scenarios': {},
        },
        'progress': {
          'cca-f': {'u': 'got'},
        },
        'hiddenDecks': <String>[],
        'view': {'filter': 'got', 'idx': 7},
      });
      final back = AppStateSnapshot.fromJson(original.toJson());
      expect(back, original);
    });
  });
}
