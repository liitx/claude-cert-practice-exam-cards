import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/models/progress_state.dart';
import 'package:drill_deck/models/study_filter.dart';
import 'package:drill_deck/repositories/decks_repository.dart';
import 'package:drill_deck/repositories/progress_repository.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:equatable/equatable.dart';

part 'study_event.dart';
part 'study_state.dart';

class StudyBloc extends Bloc<StudyEvent, StudyState> {
  StudyBloc({
    required DecksRepository decksRepository,
    required ProgressRepository progressRepository,
    required StorageRepository storageRepository,
    String? initialDeckId,
  })  : _decks = decksRepository,
        _progress = progressRepository,
        _storage = storageRepository,
        _requestedDeckId = initialDeckId ??
            storageRepository.current?.currentDeckId,
        super(
          StudyState(
            status: StudyStatus.initial,
            filter:
                storageRepository.current?.filter ?? StudyFilter.miss,
          ),
        ) {
    on<StudyStarted>(_onStarted);
    on<StudyDeckRequested>(_onDeckRequested);
    on<StudyDecksReceived>(_onDecksReceived);
    on<StudyProgressReceived>(_onProgressReceived);
    on<StudyFilterChanged>(_onFilterChanged);
    on<StudyFlipped>(_onFlipped);
    on<StudyNext>(_onNext);
    on<StudyPrev>(_onPrev);
    on<StudyMarkReview>(_onMarkReview);
    on<StudyMarkGot>(_onMarkGot);
    on<StudyResetProgress>(_onResetProgress);
    on<StudyAnswerPicked>(_onAnswerPicked);
    on<StudyMultiSelectToggled>(_onMultiSelectToggled);
    on<StudyAnswerCleared>(_onAnswerCleared);

    _decksSub = _decks.watch().listen(
          (decks) => add(StudyDecksReceived(decks)),
        );
  }

  final DecksRepository _decks;
  final ProgressRepository _progress;
  final StorageRepository _storage;
  String? _requestedDeckId;
  StreamSubscription<List<Deck>>? _decksSub;
  StreamSubscription<Map<String, ProgressState>>? _progressSub;

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
    final deck = _pickDeck(state.allDecks);
    _switchProgressSubscription(deck?.id);
    _emitForDeck(emit, state.allDecks, deck, resetIdx: true);
    _persistViewState(deckId: event.deckId);
  }

  void _onDecksReceived(
    StudyDecksReceived event,
    Emitter<StudyState> emit,
  ) {
    final decks = event.decks;
    final deck = _pickDeck(decks);
    final isNewDeck = deck?.id != state.deck?.id;
    if (isNewDeck) _switchProgressSubscription(deck?.id);
    _emitForDeck(emit, decks, deck, resetIdx: isNewDeck);
  }

  void _onProgressReceived(
    StudyProgressReceived event,
    Emitter<StudyState> emit,
  ) {
    _emitForDeck(
      emit,
      state.allDecks,
      state.deck,
      progressOverride: event.progress,
    );
  }

  void _onFilterChanged(
    StudyFilterChanged event,
    Emitter<StudyState> emit,
  ) {
    if (event.filter == state.filter) return;
    _emitForDeck(
      emit,
      state.allDecks,
      state.deck,
      filterOverride: event.filter,
      resetIdx: true,
    );
    _persistViewState(filter: event.filter);
  }

  Future<void> _persistViewState({String? deckId, StudyFilter? filter}) async {
    final snapshot = _storage.current;
    if (snapshot == null) return;
    final next = snapshot.copyWith(
      currentDeckId: deckId ?? snapshot.currentDeckId,
      filter: filter ?? snapshot.filter,
    );
    if (next == snapshot) return;
    await _storage.save(next);
  }

  void _switchProgressSubscription(String? deckId) {
    _progressSub?.cancel();
    if (deckId == null) {
      _progressSub = null;
      return;
    }
    _progressSub = _progress.watch(deckId).listen(
          (p) => add(StudyProgressReceived(p)),
        );
  }

  void _emitForDeck(
    Emitter<StudyState> emit,
    List<Deck> allDecks,
    Deck? deck, {
    Map<String, ProgressState>? progressOverride,
    StudyFilter? filterOverride,
    bool resetIdx = false,
  }) {
    if (deck == null) {
      emit(
        state.copyWith(
          status: allDecks.isEmpty ? StudyStatus.loading : StudyStatus.empty,
          allDecks: allDecks,
          progress: progressOverride ?? const {},
          counts: const StudyCounts.zero(),
        ),
      );
      return;
    }
    final progress = progressOverride ??
        (deck.id == state.deck?.id
            ? state.progress
            : _progress.current(deck.id));
    final filter = filterOverride ?? state.filter;
    final filtered = _filterCards(deck.cards, filter, progress);
    final counts = _countCards(deck.cards, progress);
    final newIdx = resetIdx
        ? 0
        : (filtered.isEmpty ? 0 : state.idx.clamp(0, filtered.length - 1));
    final newFlipped = resetIdx ? false : state.flipped;
    emit(
      state.copyWith(
        status: filtered.isEmpty ? StudyStatus.empty : StudyStatus.ready,
        deck: deck,
        cards: filtered,
        idx: newIdx,
        flipped: newFlipped,
        allDecks: allDecks,
        progress: progress,
        filter: filter,
        counts: counts,
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

  List<Card> _filterCards(
    List<Card> all,
    StudyFilter filter,
    Map<String, ProgressState> progress,
  ) {
    return switch (filter) {
      StudyFilter.all => all,
      StudyFilter.miss => all.where((c) => c.miss).toList(),
      StudyFilter.review =>
        all.where((c) => progress[c.id] == ProgressState.review).toList(),
      StudyFilter.got =>
        all.where((c) => progress[c.id] == ProgressState.got).toList(),
    };
  }

  StudyCounts _countCards(
    List<Card> all,
    Map<String, ProgressState> progress,
  ) {
    var review = 0;
    var got = 0;
    var miss = 0;
    for (final c in all) {
      final p = progress[c.id];
      if (p == ProgressState.review) review++;
      if (p == ProgressState.got) got++;
      if (c.miss) miss++;
    }
    return StudyCounts(all: all.length, miss: miss, review: review, got: got);
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

  Future<void> _onMarkReview(
    StudyMarkReview event,
    Emitter<StudyState> emit,
  ) async {
    final card = state.currentCard;
    final deck = state.deck;
    if (card == null || deck == null) return;
    await _progress.toggle(deck.id, card.id, ProgressState.review);
  }

  Future<void> _onMarkGot(
    StudyMarkGot event,
    Emitter<StudyState> emit,
  ) async {
    final card = state.currentCard;
    final deck = state.deck;
    if (card == null || deck == null) return;
    await _progress.toggle(deck.id, card.id, ProgressState.got);
  }

  Future<void> _onResetProgress(
    StudyResetProgress event,
    Emitter<StudyState> emit,
  ) async {
    final deck = state.deck;
    if (deck == null) return;
    await _progress.resetDeck(deck.id);
  }

  void _onAnswerPicked(
    StudyAnswerPicked event,
    Emitter<StudyState> emit,
  ) {
    final card = state.currentCard;
    if (card == null) return;
    final next = Map<String, Object?>.from(state.userAnswers);
    next[card.id] = event.answer;
    emit(state.copyWith(userAnswers: next));
  }

  void _onMultiSelectToggled(
    StudyMultiSelectToggled event,
    Emitter<StudyState> emit,
  ) {
    final card = state.currentCard;
    if (card == null) return;
    final current = state.userAnswers[card.id];
    final picks = current is List
        ? List<int>.from(current.whereType<int>())
        : <int>[];
    if (picks.contains(event.choiceIndex)) {
      picks.remove(event.choiceIndex);
    } else {
      picks
        ..add(event.choiceIndex)
        ..sort();
    }
    final next = Map<String, Object?>.from(state.userAnswers);
    next[card.id] = picks;
    emit(state.copyWith(userAnswers: next));
  }

  void _onAnswerCleared(
    StudyAnswerCleared event,
    Emitter<StudyState> emit,
  ) {
    final card = state.currentCard;
    if (card == null) return;
    if (!state.userAnswers.containsKey(card.id)) return;
    final next = Map<String, Object?>.from(state.userAnswers)
      ..remove(card.id);
    emit(state.copyWith(userAnswers: next));
  }

  @override
  Future<void> close() async {
    await _decksSub?.cancel();
    await _progressSub?.cancel();
    return super.close();
  }
}
