import 'dart:async';
import 'dart:convert';

import 'package:drill_deck/models/deck.dart';
import 'package:http/http.dart' as http;

/// Fetches the shared deck library (`decks.json`) hosted alongside the app.
///
/// Same-origin fetch (`./decks.json`) so it works on GitHub Pages without
/// CORS. Cache-Control: no-store plus a millisecond cache-buster ensures
/// we don't get a stale copy from the CDN edge.
class LibraryRepository {
  LibraryRepository({
    http.Client? client,
    Uri? sourceUri,
  })  : _client = client ?? http.Client(),
        _sourceUri = sourceUri ?? Uri.parse('decks.json');

  final http.Client _client;
  final Uri _sourceUri;

  Future<List<SharedDeck>> fetchShared() async {
    final url = _sourceUri.replace(
      queryParameters: {
        ..._sourceUri.queryParameters,
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    final response = await _client.get(
      url,
      headers: const {'Cache-Control': 'no-store'},
    );
    if (response.statusCode != 200) {
      throw LibraryFetchException(
        'decks.json returned ${response.statusCode}',
      );
    }
    return _parse(response.body);
  }

  List<SharedDeck> _parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const LibraryFetchException('decks.json is not a JSON object');
    }
    final decksRaw = decoded['decks'];
    if (decksRaw is! List) {
      throw const LibraryFetchException('decks.json missing decks[]');
    }
    final out = <SharedDeck>[];
    for (final d in decksRaw) {
      if (d is Map) {
        try {
          out.add(SharedDeck.fromJson(d.cast<String, Object?>()));
        } catch (_) {
          // Skip malformed decks instead of failing the whole library.
        }
      }
    }
    return out;
  }

  void dispose() {
    _client.close();
  }
}

class LibraryFetchException implements Exception {
  const LibraryFetchException(this.message);
  final String message;
  @override
  String toString() => 'LibraryFetchException: $message';
}
