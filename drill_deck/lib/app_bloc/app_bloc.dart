import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/repositories/decks_repository.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:equatable/equatable.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required StorageRepository storageRepository,
    required DecksRepository decksRepository,
  })  : _storage = storageRepository,
        _decks = decksRepository,
        super(const AppState.initial()) {
    on<AppHydrationRequested>(_onHydrate);
    on<AppSnapshotReceived>(_onSnapshot);
    on<DeckCreated>(_onDeckCreated);
    on<DeckRenamed>(_onDeckRenamed);
    on<DeckDeleted>(_onDeckDeleted);
    on<CardUpserted>(_onCardUpserted);
    on<CardDeleted>(_onCardDeleted);
    _subscription = _storage.watch().listen(
          (snapshot) => add(AppSnapshotReceived(snapshot)),
        );
  }

  final StorageRepository _storage;
  final DecksRepository _decks;
  StreamSubscription<AppStateSnapshot>? _subscription;

  Future<void> _onHydrate(
    AppHydrationRequested event,
    Emitter<AppState> emit,
  ) async {
    emit(const AppState.loading());
    try {
      final snapshot = await _storage.hydrate();
      emit(AppState.ready(snapshot));
    } catch (e, _) {
      emit(AppState.failure(e.toString()));
    }
  }

  void _onSnapshot(AppSnapshotReceived event, Emitter<AppState> emit) {
    emit(AppState.ready(event.snapshot));
  }

  Future<void> _onDeckCreated(DeckCreated event, Emitter<AppState> emit) async {
    final snap = state.snapshot;
    if (snap == null) return;
    final name = event.name.trim().isEmpty ? 'Untitled deck' : event.name.trim();
    final ids = snap.userDecks.map((d) => d.id).toSet();
    var id = _slugId(name);
    while (ids.contains(id) || _decks.current.any((d) => d.id == id)) {
      id = '$id-${_suffix()}';
    }
    final deck = PrivateDeck(id: id, name: name, scenarios: const {}, cards: const []);
    await _storage.save(
      snap.copyWith(userDecks: [...snap.userDecks, deck], currentDeckId: id),
    );
  }

  Future<void> _onDeckRenamed(DeckRenamed event, Emitter<AppState> emit) async {
    final snap = state.snapshot;
    if (snap == null || event.name.trim().isEmpty) return;
    final decks = _mutateDeck(snap, event.deckId, (d) => d.copyWith(name: event.name.trim()));
    if (decks == null) return;
    await _storage.save(snap.copyWith(userDecks: decks));
  }

  Future<void> _onDeckDeleted(DeckDeleted event, Emitter<AppState> emit) async {
    final snap = state.snapshot;
    if (snap == null) return;
    final userDecks =
        snap.userDecks.where((d) => d.id != event.deckId).toList();
    final hasShared = _decks.current.any(
      (d) => d.id == event.deckId && d is SharedDeck,
    );
    final hidden = hasShared && !snap.hiddenDecks.contains(event.deckId)
        ? [...snap.hiddenDecks, event.deckId]
        : snap.hiddenDecks;
    await _storage.save(
      snap.copyWith(userDecks: userDecks, hiddenDecks: hidden),
    );
  }

  Future<void> _onCardUpserted(CardUpserted event, Emitter<AppState> emit) async {
    final snap = state.snapshot;
    if (snap == null) return;
    final decks = _mutateDeck(snap, event.deckId, (d) {
      final cards = [...d.cards];
      final i = cards.indexWhere((c) => c.id == event.card.id);
      if (i == -1) {
        cards.add(event.card);
      } else {
        cards[i] = event.card;
      }
      return d.copyWith(cards: cards);
    });
    if (decks == null) return;
    await _storage.save(snap.copyWith(userDecks: decks));
  }

  Future<void> _onCardDeleted(CardDeleted event, Emitter<AppState> emit) async {
    final snap = state.snapshot;
    if (snap == null) return;
    final decks = _mutateDeck(snap, event.deckId, (d) {
      final cards = d.cards.where((c) => c.id != event.cardId).toList();
      return d.copyWith(cards: cards);
    });
    if (decks == null) return;
    await _storage.save(snap.copyWith(userDecks: decks));
  }

  /// Applies [transform] to the deck [deckId], forking a shared deck into a
  /// local copy first. Returns the new `userDecks` list, or null if the deck
  /// can't be found.
  List<PrivateDeck>? _mutateDeck(
    AppStateSnapshot snap,
    String deckId,
    PrivateDeck Function(PrivateDeck) transform,
  ) {
    PrivateDeck? local;
    for (final d in snap.userDecks) {
      if (d.id == deckId) {
        local = d;
        break;
      }
    }
    if (local == null) {
      Deck? source;
      for (final d in _decks.current) {
        if (d.id == deckId) {
          source = d;
          break;
        }
      }
      if (source == null) return null;
      local = PrivateDeck.fork(source);
    }
    final updated = transform(local);
    final out = [...snap.userDecks];
    final i = out.indexWhere((d) => d.id == deckId);
    if (i == -1) {
      out.add(updated);
    } else {
      out[i] = updated;
    }
    return out;
  }

  String _slugId(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return base.isEmpty ? 'deck-${_suffix()}' : base;
  }

  String _suffix() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
