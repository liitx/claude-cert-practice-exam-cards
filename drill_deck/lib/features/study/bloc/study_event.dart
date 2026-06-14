part of 'study_bloc.dart';

sealed class StudyEvent extends Equatable {
  const StudyEvent();
  @override
  List<Object?> get props => const [];
}

final class StudyStarted extends StudyEvent {
  const StudyStarted();
}

final class StudyDeckRequested extends StudyEvent {
  const StudyDeckRequested(this.deckId);
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

final class StudyFlipped extends StudyEvent {
  const StudyFlipped();
}

final class StudyNext extends StudyEvent {
  const StudyNext();
}

final class StudyPrev extends StudyEvent {
  const StudyPrev();
}
