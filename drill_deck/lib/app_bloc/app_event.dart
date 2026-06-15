part of 'app_bloc.dart';

sealed class AppEvent extends Equatable {
  const AppEvent();
  @override
  List<Object?> get props => const [];
}

final class AppHydrationRequested extends AppEvent {
  const AppHydrationRequested();
}

final class AppSnapshotReceived extends AppEvent {
  const AppSnapshotReceived(this.snapshot);
  final AppStateSnapshot snapshot;
  @override
  List<Object?> get props => [snapshot];
}

/// Creates a new empty private deck and selects it.
final class DeckCreated extends AppEvent {
  const DeckCreated(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

/// Renames a deck (forks a shared deck into a local copy first).
final class DeckRenamed extends AppEvent {
  const DeckRenamed(this.deckId, this.name);
  final String deckId;
  final String name;
  @override
  List<Object?> get props => [deckId, name];
}

/// Deletes a local deck; hides it if it has a shared origin.
final class DeckDeleted extends AppEvent {
  const DeckDeleted(this.deckId);
  final String deckId;
  @override
  List<Object?> get props => [deckId];
}

/// Inserts or replaces a card in a deck (forks a shared deck first). Matches
/// by card id; a new id appends.
final class CardUpserted extends AppEvent {
  const CardUpserted(this.deckId, this.card);
  final String deckId;
  final Card card;
  @override
  List<Object?> get props => [deckId, card];
}

/// Removes a card from a deck (forks a shared deck first).
final class CardDeleted extends AppEvent {
  const CardDeleted(this.deckId, this.cardId);
  final String deckId;
  final String cardId;
  @override
  List<Object?> get props => [deckId, cardId];
}
