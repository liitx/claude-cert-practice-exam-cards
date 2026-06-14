import 'dart:convert';

import 'package:drill_deck/models/deck.dart';

/// Builds the URL / clipboard payload for "share to library". Matches the
/// shape produced by `shareDeck()` in the static-site source so the existing
/// `ingest-submission` workflow accepts it unchanged.
class SharePayload {
  SharePayload._({
    required this.title,
    required this.body,
    required this.uri,
    required this.clipboardFallback,
  });

  factory SharePayload.forDeck(
    Deck deck, {
    String repo = 'liitx/claude-cert-practice-exam-cards',
  }) {
    final isShared = deck is SharedDeck;
    final Map<String, Object?> payload;
    final String title;
    if (isShared) {
      title = 'Cards for ${deck.name}: ${deck.cards.length} new';
      payload = {
        'type': 'cards-for-deck',
        'targetDeckId': deck.id,
        'cards': deck.cards.map((c) => c.toJson()).toList(),
        'scenarios': {
          for (final e in deck.scenarios.entries) e.key: e.value.toJson(),
        },
      };
    } else {
      title = 'Deck submission: ${deck.name}';
      payload = {
        'type': 'new-deck',
        'deck': deck.toJson(),
      };
    }
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final body = '<!-- Submission via the Flutter app. Maintainer: review and merge into decks.json. -->\n\n```json\n$json\n```';
    final base = Uri.https('github.com', '/$repo/issues/new', {
      'labels': 'submission',
      'title': title,
    });
    final full = base.replace(
      queryParameters: {
        ...base.queryParameters,
        'body': body,
      },
    );
    final fallback = full.toString().length > 7500;
    return SharePayload._(
      title: title,
      body: body,
      uri: fallback ? base : full,
      clipboardFallback: fallback,
    );
  }

  final String title;
  final String body;
  final Uri uri;
  final bool clipboardFallback;
}
