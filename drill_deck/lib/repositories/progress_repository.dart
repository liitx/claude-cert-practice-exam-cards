import 'dart:async';

import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/progress_state.dart';
import 'package:drill_deck/repositories/storage_repository.dart';

/// Read/write surface for per-deck card progress. All writes round-trip
/// through the snapshot in `StorageRepository` so they persist and any
/// other Bloc subscribed to the storage stream picks them up too.
class ProgressRepository {
  ProgressRepository({required StorageRepository storage}) : _storage = storage;

  final StorageRepository _storage;

  /// Stream of `{cardId: state}` for a single deck.
  Stream<Map<String, ProgressState>> watch(String deckId) {
    return _storage.watch().map((snapshot) => snapshot.progress[deckId] ?? {});
  }

  Map<String, ProgressState> current(String deckId) {
    final snapshot = _storage.current;
    if (snapshot == null) return const {};
    return snapshot.progress[deckId] ?? const {};
  }

  /// Stream of `{deckId: {cardId: state}}` for several decks at once — used by
  /// group study so one subscription covers every selected deck.
  Stream<Map<String, Map<String, ProgressState>>> watchMany(
    Set<String> deckIds,
  ) {
    return _storage.watch().map((snapshot) => currentManyFrom(snapshot, deckIds));
  }

  Map<String, Map<String, ProgressState>> currentMany(Set<String> deckIds) {
    final snapshot = _storage.current;
    if (snapshot == null) {
      return {for (final id in deckIds) id: const {}};
    }
    return currentManyFrom(snapshot, deckIds);
  }

  Map<String, Map<String, ProgressState>> currentManyFrom(
    AppStateSnapshot snapshot,
    Set<String> deckIds,
  ) {
    return {for (final id in deckIds) id: snapshot.progress[id] ?? const {}};
  }

  /// Toggle the state for a card. If `state` matches what's already stored,
  /// the entry is removed (so tapping the same mark twice clears it).
  Future<void> toggle(
    String deckId,
    String cardId,
    ProgressState state,
  ) async {
    final snapshot = _storage.current ?? AppStateSnapshot.initial();
    final progressForDeck =
        Map<String, ProgressState>.from(snapshot.progress[deckId] ?? const {});
    if (progressForDeck[cardId] == state) {
      progressForDeck.remove(cardId);
    } else {
      progressForDeck[cardId] = state;
    }
    final newProgress = Map<String, Map<String, ProgressState>>.from(snapshot.progress)
      ..[deckId] = progressForDeck;
    await _storage.save(snapshot.copyWith(progress: newProgress));
  }

  /// Clear all progress for a deck.
  Future<void> resetDeck(String deckId) async {
    final snapshot = _storage.current ?? AppStateSnapshot.initial();
    final newProgress = Map<String, Map<String, ProgressState>>.from(snapshot.progress)
      ..remove(deckId);
    await _storage.save(snapshot.copyWith(progress: newProgress));
  }
}
