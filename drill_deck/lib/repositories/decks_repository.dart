import 'dart:async';

import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/repositories/library_repository.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:rxdart/subjects.dart';

/// Surface for "all decks visible to the user" — shared library decks merged
/// with private decks from local storage. Phase 2 only consumes the shared
/// side; private decks remain an empty list until Phase 4 wires them in.
class DecksRepository {
  DecksRepository({
    required StorageRepository storage,
    required LibraryRepository library,
  })  : _storage = storage,
        _library = library {
    _storage.watch().listen((snapshot) {
      _snapshot = snapshot;
      _emit();
    });
  }

  final StorageRepository _storage;
  final LibraryRepository _library;

  final _decks = BehaviorSubject<List<Deck>>.seeded(const []);
  AppStateSnapshot _snapshot = AppStateSnapshot.initial();
  List<SharedDeck> _shared = const [];
  bool _libraryLoaded = false;

  Stream<List<Deck>> watch() => _decks.stream;
  List<Deck> get current => _decks.value;

  /// Triggers an initial fetch of the shared library. Safe to call more than
  /// once — subsequent calls re-fetch and replace the shared set.
  Future<void> refreshShared() async {
    try {
      _shared = await _library.fetchShared();
      _libraryLoaded = true;
      _emit();
    } catch (_) {
      _libraryLoaded = true; // mark as attempted so we don't block on empty
      _emit();
    }
  }

  bool get libraryLoaded => _libraryLoaded;

  void _emit() {
    final hidden = _snapshot.hiddenDecks.toSet();
    final localIds = _snapshot.userDecks.map((d) => d.id).toSet();
    // Local copies win over shared decks of the same id (fork-on-write), and
    // hidden decks drop out of both sources.
    final shared = _shared.where(
      (d) => !localIds.contains(d.id) && !hidden.contains(d.id),
    );
    final user = _snapshot.userDecks.where((d) => !hidden.contains(d.id));
    _decks.add(<Deck>[...shared, ...user]);
  }

  Future<void> dispose() async {
    await _decks.close();
  }
}
