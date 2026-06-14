import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/repositories/decks_repository.dart';
import 'package:equatable/equatable.dart';

part 'study_event.dart';
part 'study_state.dart';

class StudyBloc extends Bloc<StudyEvent, StudyState> {
  StudyBloc({
    required DecksRepository decksRepository,
    String? initialDeckId,
  })  : _decks = decksRepository,
        _requestedDeckId = initialDeckId,
        super(const StudyState.initial()) {
    on<StudyStarted>(_onStarted);
    on<StudyDeckRequested>(_onDeckRequested);
    on<StudyDecksReceived>(_onDecksReceived);
    on<StudyFlipped>(_onFlipped);
    on<StudyNext>(_onNext);
    on<StudyPrev>(_onPrev);

    _subscription = _decks.watch().listen(
          (decks) => add(StudyDecksReceived(decks)),
        );
  }

  final DecksRepository _decks;
  String? _requestedDeckId;
  StreamSubscription<List<Deck>>? _subscription;

  Future<void> _onStarted(
    StudyStarted event,
    Emitter<StudyState> emit,
  ) async {
    emit(state.copyWith(status: StudyStatus.loading));
    if (!_decks.libraryLoaded) {
      await _decks.refreshShared();
    }
  }

  void _onDeckRequested(
    StudyDeckRequested event,
    Emitter<StudyState> emit,
  ) {
    _requestedDeckId = event.deckId;
    final decks = state.allDecks;
    final deck = _pickDeck(decks);
    _emitForDeck(emit, decks, deck);
  }

  void _onDecksReceived(
    StudyDecksReceived event,
    Emitter<StudyState> emit,
  ) {
    final decks = event.decks;
    final deck = _pickDeck(decks);
    _emitForDeck(emit, decks, deck);
  }

  void _emitForDeck(Emitter<StudyState> emit, List<Deck> allDecks, Deck? deck) {
    if (deck == null) {
      emit(
        state.copyWith(
          status: allDecks.isEmpty ? StudyStatus.loading : StudyStatus.empty,
          allDecks: allDecks,
        ),
      );
      return;
    }
    final cards = deck.cards;
    final clampedIdx = cards.isEmpty ? 0 : state.idx.clamp(0, cards.length - 1);
    emit(
      state.copyWith(
        status: cards.isEmpty ? StudyStatus.empty : StudyStatus.ready,
        deck: deck,
        cards: cards,
        idx: clampedIdx,
        flipped: false,
        allDecks: allDecks,
      ),
    );
  }

  Deck? _pickDeck(List<Deck> decks) {
    if (decks.isEmpty) return null;
    final wanted = _requestedDeckId;
    if (wanted != null) {
      for (final d in decks) {
        if (d.id == wanted) return d;
      }
    }
    return decks.first;
  }

  void _onFlipped(StudyFlipped event, Emitter<StudyState> emit) {
    if (state.status != StudyStatus.ready) return;
    emit(state.copyWith(flipped: !state.flipped));
  }

  void _onNext(StudyNext event, Emitter<StudyState> emit) {
    if (state.cards.isEmpty) return;
    final next = (state.idx + 1) % state.cards.length;
    emit(state.copyWith(idx: next, flipped: false));
  }

  void _onPrev(StudyPrev event, Emitter<StudyState> emit) {
    if (state.cards.isEmpty) return;
    final prev = (state.idx - 1 + state.cards.length) % state.cards.length;
    emit(state.copyWith(idx: prev, flipped: false));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
