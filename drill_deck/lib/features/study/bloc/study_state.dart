part of 'study_bloc.dart';

enum StudyStatus { initial, loading, ready, empty, failure }

final class StudyState extends Equatable {
  const StudyState({
    required this.status,
    this.deck,
    this.cards = const [],
    this.idx = 0,
    this.flipped = false,
    this.allDecks = const [],
    this.errorMessage,
  });

  const StudyState.initial() : this(status: StudyStatus.initial);

  final StudyStatus status;
  final Deck? deck;
  final List<Card> cards;
  final int idx;
  final bool flipped;
  final List<Deck> allDecks;
  final String? errorMessage;

  Card? get currentCard =>
      (cards.isNotEmpty && idx >= 0 && idx < cards.length) ? cards[idx] : null;

  StudyState copyWith({
    StudyStatus? status,
    Deck? deck,
    List<Card>? cards,
    int? idx,
    bool? flipped,
    List<Deck>? allDecks,
    String? errorMessage,
  }) {
    return StudyState(
      status: status ?? this.status,
      deck: deck ?? this.deck,
      cards: cards ?? this.cards,
      idx: idx ?? this.idx,
      flipped: flipped ?? this.flipped,
      allDecks: allDecks ?? this.allDecks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, deck, cards, idx, flipped, allDecks, errorMessage];
}
