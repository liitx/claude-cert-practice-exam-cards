part of 'study_bloc.dart';

sealed class StudyEvent extends Equatable {
  const StudyEvent();
  @override
  List<Object?> get props => const [];
}

final class StudyStarted extends StudyEvent {
  const StudyStarted();
}

/// Selects exactly one deck (replaces the current selection).
final class StudyDeckRequested extends StudyEvent {
  const StudyDeckRequested(this.deckId);
  final String deckId;
  @override
  List<Object?> get props => [deckId];
}

/// Adds or removes a deck from the group selection. Never empties it.
final class StudyDeckToggled extends StudyEvent {
  const StudyDeckToggled(this.deckId);
  final String deckId;
  @override
  List<Object?> get props => [deckId];
}

final class StudyDecksReceived extends StudyEvent {
  const StudyDecksReceived(this.decks);
  final List<Deck> decks;
  @override
  List<Object?> get props => [decks];
}

final class StudyProgressReceived extends StudyEvent {
  const StudyProgressReceived(this.progressByDeck);
  final Map<String, Map<String, ProgressState>> progressByDeck;
  @override
  List<Object?> get props => [progressByDeck];
}

final class StudyFilterChanged extends StudyEvent {
  const StudyFilterChanged(this.filter);
  final StudyFilter filter;
  @override
  List<Object?> get props => [filter];
}

/// Re-randomizes the order of the currently filtered cards.
final class StudyShuffled extends StudyEvent {
  const StudyShuffled();
}

/// Changes the ordering applied after filtering.
final class StudySortChanged extends StudyEvent {
  const StudySortChanged(this.sort);
  final StudySort sort;
  @override
  List<Object?> get props => [sort];
}

final class StudyFlipped extends StudyEvent {
  const StudyFlipped();
}

final class StudyNext extends StudyEvent {
  const StudyNext();
}

final class StudyPrev extends StudyEvent {
  const StudyPrev();
}

final class StudyMarkReview extends StudyEvent {
  const StudyMarkReview();
}

final class StudyMarkGot extends StudyEvent {
  const StudyMarkGot();
}

final class StudyResetProgress extends StudyEvent {
  const StudyResetProgress();
}

/// Records a single-value pick on the current card (MC index, TF bool,
/// FIB text). The bloc keys it by the current card's id.
final class StudyAnswerPicked extends StudyEvent {
  const StudyAnswerPicked(this.answer);
  final Object? answer;
  @override
  List<Object?> get props => [answer];
}

/// Toggles a single index in/out of the current card's MultiSelect pick set.
final class StudyMultiSelectToggled extends StudyEvent {
  const StudyMultiSelectToggled(this.choiceIndex);
  final int choiceIndex;
  @override
  List<Object?> get props => [choiceIndex];
}

final class StudyAnswerCleared extends StudyEvent {
  const StudyAnswerCleared();
}
