import 'package:drill_deck/repositories/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LibraryRepository', () {
    test('parses decks from a valid decks.json payload', () async {
      final client = MockClient((req) async {
        expect(req.headers['Cache-Control'], 'no-store');
        expect(req.url.path.endsWith('decks.json'), isTrue);
        expect(req.url.queryParameters.containsKey('t'), isTrue);
        return http.Response(
          '''
{
  "version": 1,
  "decks": [
    {
      "id": "cca-f",
      "name": "CCA-F Drill Deck",
      "scenarios": {
        "CI": { "label": "Claude Code · CI", "color": "#7c83ff" }
      },
      "cards": [
        { "id": "ci1", "scn": "CI", "topic": "Batch", "q": "q", "a": "a" }
      ]
    }
  ]
}
''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = LibraryRepository(
        client: client,
        sourceUri: Uri.parse('https://example.test/decks.json'),
      );
      final decks = await repo.fetchShared();
      expect(decks, hasLength(1));
      expect(decks.first.id, 'cca-f');
      expect(decks.first.cards, hasLength(1));
    });

    test('throws LibraryFetchException on non-200', () async {
      final client = MockClient((_) async => http.Response('nope', 500));
      final repo = LibraryRepository(
        client: client,
        sourceUri: Uri.parse('https://example.test/decks.json'),
      );
      expect(repo.fetchShared, throwsA(isA<LibraryFetchException>()));
    });

    test('throws on malformed JSON', () async {
      final client = MockClient((_) async => http.Response('not-json', 200));
      final repo = LibraryRepository(
        client: client,
        sourceUri: Uri.parse('https://example.test/decks.json'),
      );
      expect(repo.fetchShared, throwsA(isA<Exception>()));
    });

    test('skips malformed decks but keeps valid ones', () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"decks":[{"bogus":true},{"id":"good","name":"Good","scenarios":{},"cards":[]}]}',
          200,
        ),
      );
      final repo = LibraryRepository(
        client: client,
        sourceUri: Uri.parse('https://example.test/decks.json'),
      );
      final decks = await repo.fetchShared();
      expect(decks, hasLength(2));
      expect(decks.last.id, 'good');
    });
  });
}
