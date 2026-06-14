part of 'study_bloc.dart';

enum StudyStatus { initial, loading, ready, empty, failure }

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
    this.cards = const [],
    this.idx = 0,
    this.flipped = false,
    this.allDecks = const [],
    this.progress = const {},
    this.filter = StudyFilter.all,
    this.counts = const StudyCounts.zero(),
    this.userAnswers = const {},
    this.errorMessage,
  });

  const StudyState.initial() : this(status: StudyStatus.initial);

  final StudyStatus status;
  final Deck? deck;

  /// Cards filtered by [filter]. Use [allCards] via deck.cards when you
  /// need the full set.
  final List<Card> cards;

  final int idx;
  final bool flipped;
  final List<Deck> allDecks;
  final Map<String, ProgressState> progress;
  final StudyFilter filter;
  final StudyCounts counts;

  /// In-memory map of card id -> the user's current pick on that card.
  /// Value type varies by card type (int for MC, List<int> for MS, bool for
  /// TF, String for FIB). Not persisted across sessions.
  final Map<String, Object?> userAnswers;

  final String? errorMessage;

  Card? get currentCard =>
      (cards.isNotEmpty && idx >= 0 && idx < cards.length) ? cards[idx] : null;

  ProgressState? get currentCardProgress {
    final c = currentCard;
    if (c == null) return null;
    return progress[c.id];
  }

  Object? get currentCardAnswer {
    final c = currentCard;
    if (c == null) return null;
    return userAnswers[c.id];
  }

  StudyState copyWith({
    StudyStatus? status,
    Deck? deck,
    List<Card>? cards,
    int? idx,
    bool? flipped,
    List<Deck>? allDecks,
    Map<String, ProgressState>? progress,
    StudyFilter? filter,
    StudyCounts? counts,
    Map<String, Object?>? userAnswers,
    String? errorMessage,
  }) {
    return StudyState(
      status: status ?? this.status,
      deck: deck ?? this.deck,
      cards: cards ?? this.cards,
      idx: idx ?? this.idx,
      flipped: flipped ?? this.flipped,
      allDecks: allDecks ?? this.allDecks,
      progress: progress ?? this.progress,
      filter: filter ?? this.filter,
      counts: counts ?? this.counts,
      userAnswers: userAnswers ?? this.userAnswers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        deck,
        cards,
        idx,
        flipped,
        allDecks,
        progress,
        filter,
        counts,
        userAnswers,
        errorMessage,
      ];
}
