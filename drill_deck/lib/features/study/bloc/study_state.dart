part of 'study_bloc.dart';

enum StudyStatus { initial, loading, ready, empty, failure }

/// One card in the working set, tagged with the deck that owns it. In a group
/// session cards come from several decks, so the owning deck travels with each
/// card for scenario lookup, progress, and editing.
class StudyEntry extends Equatable {
  const StudyEntry({required this.deck, required this.card});
  final Deck deck;
  final Card card;

  @override
  List<Object?> get props => [deck.id, card];
}

class StudyCounts extends Equatable {
  const StudyCounts({
    required this.all,
    required this.miss,
    required this.review,
    required this.got,
  });

  const StudyCounts.zero() : this(all: 0, miss: 0, review: 0, got: 0);

  final int all;
  final int miss;
  final int review;
  final int got;

  int forFilter(StudyFilter f) => switch (f) {
        StudyFilter.all => all,
        StudyFilter.miss => miss,
        StudyFilter.review => review,
        StudyFilter.got => got,
      };

  @override
  List<Object?> get props => [all, miss, review, got];
}

final class StudyState extends Equatable {
  const StudyState({
    required this.status,
    this.deck,
    this.entries = const [],
    this.idx = 0,
    this.flipped = false,
    this.allDecks = const [],
    this.selectedDeckIds = const {},
    this.progressByDeck = const {},
    this.filter = StudyFilter.all,
    this.sort = StudySort.original,
    this.shuffleSeed = 0,
    this.counts = const StudyCounts.zero(),
    this.userAnswers = const {},
    this.errorMessage,
  });

  const StudyState.initial() : this(status: StudyStatus.initial);

  final StudyStatus status;

  /// Primary deck: drives the title and footer actions. First of the selected
  /// decks. Null while loading / empty.
  final Deck? deck;

  /// Filtered + ordered working set across all selected decks.
  final List<StudyEntry> entries;

  final int idx;
  final bool flipped;
  final List<Deck> allDecks;

  /// Decks currently combined into the session.
  final Set<String> selectedDeckIds;

  /// Progress keyed by deckId -> {cardId: state}, covering every selected deck.
  final Map<String, Map<String, ProgressState>> progressByDeck;

  final StudyFilter filter;
  final StudySort sort;

  /// Bumped on each shuffle so the random permutation is stable across
  /// rebuilds but re-rolls when the user shuffles again.
  final int shuffleSeed;

  final StudyCounts counts;

  /// In-memory map of card id -> the user's current pick on that card.
  final Map<String, Object?> userAnswers;

  final String? errorMessage;

  /// Cards in working-set order (owning deck stripped). Built per call.
  List<Card> get cards => [for (final e in entries) e.card];

  StudyEntry? get currentEntry =>
      (entries.isNotEmpty && idx >= 0 && idx < entries.length)
          ? entries[idx]
          : null;

  Card? get currentCard => currentEntry?.card;

  /// Owning deck of the current card (may differ from [deck] in a group).
  Deck? get currentDeck => currentEntry?.deck;

  ProgressState? progressFor(StudyEntry entry) =>
      progressByDeck[entry.deck.id]?[entry.card.id];

  ProgressState? get currentCardProgress {
    final e = currentEntry;
    return e == null ? null : progressFor(e);
  }

  Object? get currentCardAnswer {
    final c = currentCard;
    if (c == null) return null;
    return userAnswers[c.id];
  }

  StudyState copyWith({
    StudyStatus? status,
    Deck? deck,
    List<StudyEntry>? entries,
    int? idx,
    bool? flipped,
    List<Deck>? allDecks,
    Set<String>? selectedDeckIds,
    Map<String, Map<String, ProgressState>>? progressByDeck,
    StudyFilter? filter,
    StudySort? sort,
    int? shuffleSeed,
    StudyCounts? counts,
    Map<String, Object?>? userAnswers,
    String? errorMessage,
  }) {
    return StudyState(
      status: status ?? this.status,
      deck: deck ?? this.deck,
      entries: entries ?? this.entries,
      idx: idx ?? this.idx,
      flipped: flipped ?? this.flipped,
      allDecks: allDecks ?? this.allDecks,
      selectedDeckIds: selectedDeckIds ?? this.selectedDeckIds,
      progressByDeck: progressByDeck ?? this.progressByDeck,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      shuffleSeed: shuffleSeed ?? this.shuffleSeed,
      counts: counts ?? this.counts,
      userAnswers: userAnswers ?? this.userAnswers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        deck,
        entries,
        idx,
        flipped,
        allDecks,
        selectedDeckIds,
        progressByDeck,
        filter,
        sort,
        shuffleSeed,
        counts,
        userAnswers,
        errorMessage,
      ];
}
