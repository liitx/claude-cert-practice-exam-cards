import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/models/progress_state.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/models/study_filter.dart';
import 'package:equatable/equatable.dart';

/// The persisted state, mirroring the legacy `drill-decks-v2` localStorage
/// shape so migration is a structural translation, not a model rewrite.
final class AppStateSnapshot extends Equatable {
  const AppStateSnapshot({
    required this.currentDeckId,
    required this.userDecks,
    required this.overlayCards,
    required this.overlayScenarios,
    required this.progress,
    required this.hiddenDecks,
    required this.filter,
    required this.cardIndex,
    this.selectedDeckIds = const [],
  });

  factory AppStateSnapshot.initial() => const AppStateSnapshot(
        currentDeckId: 'cca-f',
        userDecks: [],
        overlayCards: {},
        overlayScenarios: {},
        progress: {},
        hiddenDecks: [],
        filter: StudyFilter.miss,
        cardIndex: 0,
        selectedDeckIds: [],
      );

  factory AppStateSnapshot.fromJson(Map<String, Object?> json) {
    final view = json['view'];
    final filterRaw = view is Map ? view['filter'] : null;
    final idxRaw = view is Map ? view['idx'] : null;
    final selectedRaw = view is Map ? view['selectedDeckIds'] : null;

    return AppStateSnapshot(
      currentDeckId: json['currentDeckId'] is String
          ? json['currentDeckId']! as String
          : 'cca-f',
      userDecks: _readUserDecks(json['userDecks']),
      overlayCards: _readOverlayCards(json['overlay']),
      overlayScenarios: _readOverlayScenarios(json['overlay']),
      progress: _readProgress(json['progress']),
      hiddenDecks: _readStringList(json['hiddenDecks']),
      filter: StudyFilter.tryParse(filterRaw),
      cardIndex: idxRaw is int ? idxRaw : 0,
      selectedDeckIds: _readStringList(selectedRaw),
    );
  }

  final String currentDeckId;
  final List<PrivateDeck> userDecks;
  final Map<String, List<Card>> overlayCards;
  final Map<String, Map<String, Scenario>> overlayScenarios;
  final Map<String, Map<String, ProgressState>> progress;
  final List<String> hiddenDecks;
  final StudyFilter filter;
  final int cardIndex;

  /// Decks combined into the current group study session (empty = just the
  /// single [currentDeckId]).
  final List<String> selectedDeckIds;

  Map<String, Object?> toJson() => {
        'currentDeckId': currentDeckId,
        'userDecks': userDecks.map((d) => d.toJson()).toList(),
        'overlay': {
          'cards': {
            for (final entry in overlayCards.entries)
              entry.key: entry.value.map((c) => c.toJson()).toList(),
          },
          'scenarios': {
            for (final entry in overlayScenarios.entries)
              entry.key: {
                for (final s in entry.value.entries) s.key: s.value.toJson(),
              },
          },
        },
        'progress': {
          for (final entry in progress.entries)
            entry.key: {
              for (final p in entry.value.entries) p.key: p.value.id,
            },
        },
        'hiddenDecks': hiddenDecks,
        'view': {
          'filter': filter.id,
          'idx': cardIndex,
          'selectedDeckIds': selectedDeckIds,
        },
      };

  AppStateSnapshot copyWith({
    String? currentDeckId,
    List<PrivateDeck>? userDecks,
    Map<String, List<Card>>? overlayCards,
    Map<String, Map<String, Scenario>>? overlayScenarios,
    Map<String, Map<String, ProgressState>>? progress,
    List<String>? hiddenDecks,
    StudyFilter? filter,
    int? cardIndex,
    List<String>? selectedDeckIds,
  }) {
    return AppStateSnapshot(
      currentDeckId: currentDeckId ?? this.currentDeckId,
      userDecks: userDecks ?? this.userDecks,
      overlayCards: overlayCards ?? this.overlayCards,
      overlayScenarios: overlayScenarios ?? this.overlayScenarios,
      progress: progress ?? this.progress,
      hiddenDecks: hiddenDecks ?? this.hiddenDecks,
      filter: filter ?? this.filter,
      cardIndex: cardIndex ?? this.cardIndex,
      selectedDeckIds: selectedDeckIds ?? this.selectedDeckIds,
    );
  }

  @override
  List<Object?> get props => [
        currentDeckId,
        userDecks,
        overlayCards,
        overlayScenarios,
        progress,
        hiddenDecks,
        filter,
        cardIndex,
        selectedDeckIds,
      ];
}

List<PrivateDeck> _readUserDecks(Object? raw) {
  if (raw is! List) return const [];
  final out = <PrivateDeck>[];
  for (final d in raw) {
    if (d is Map) {
      out.add(PrivateDeck.fromJson(d.cast<String, Object?>()));
    }
  }
  return out;
}

Map<String, List<Card>> _readOverlayCards(Object? overlay) {
  if (overlay is! Map) return const {};
  final raw = overlay['cards'];
  if (raw is! Map) return const {};
  final out = <String, List<Card>>{};
  raw.forEach((deckId, list) {
    if (deckId is! String || list is! List) return;
    out[deckId] = [
      for (final c in list)
        if (c is Map) _withUserFlag(Card.fromJson(c.cast<String, Object?>())),
    ];
  });
  return out;
}

Map<String, Map<String, Scenario>> _readOverlayScenarios(Object? overlay) {
  if (overlay is! Map) return const {};
  final raw = overlay['scenarios'];
  if (raw is! Map) return const {};
  final out = <String, Map<String, Scenario>>{};
  raw.forEach((deckId, map) {
    if (deckId is! String || map is! Map) return;
    final inner = <String, Scenario>{};
    map.forEach((scnKey, scn) {
      if (scnKey is String && scn is Map) {
        inner[scnKey] = Scenario.fromJson(scn.cast<String, Object?>());
      }
    });
    out[deckId] = inner;
  });
  return out;
}

Map<String, Map<String, ProgressState>> _readProgress(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, Map<String, ProgressState>>{};
  raw.forEach((deckId, inner) {
    if (deckId is! String || inner is! Map) return;
    final cards = <String, ProgressState>{};
    inner.forEach((cardId, state) {
      final parsed = ProgressState.tryParse(state);
      if (cardId is String && parsed != null) {
        cards[cardId] = parsed;
      }
    });
    out[deckId] = cards;
  });
  return out;
}

List<String> _readStringList(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final v in raw)
      if (v is String) v,
  ];
}

Card _withUserFlag(Card c) {
  if (c.userOwned) return c;
  // Force userOwned=true via JSON round-trip with the `user` field set.
  final json = c.toJson()..['user'] = true;
  return Card.fromJson(json);
}
