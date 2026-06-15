import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/models/progress_state.dart';
import 'package:drill_deck/models/study_filter.dart';
import 'package:drill_deck/models/study_sort.dart';
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
        super(
          StudyState(
            status: StudyStatus.initial,
            filter: storageRepository.current?.filter ?? StudyFilter.miss,
          ),
        ) {
    final snap = storageRepository.current;
    _requestedDeckId = initialDeckId ?? snap?.currentDeckId;
    if (initialDeckId != null) {
      _selectedIds = {initialDeckId};
    } else if ((snap?.selectedDeckIds ?? const []).isNotEmpty) {
      _selectedIds = snap!.selectedDeckIds.toSet();
    } else if (_requestedDeckId != null) {
      _selectedIds = {_requestedDeckId!};
    } else {
      _selectedIds = {};
    }

    on<StudyStarted>(_onStarted);
    on<StudyDeckRequested>(_onDeckRequested);
    on<StudyDeckToggled>(_onDeckToggled);
    on<StudyDecksReceived>(_onDecksReceived);
    on<StudyProgressReceived>(_onProgressReceived);
    on<StudyFilterChanged>(_onFilterChanged);
    on<StudyShuffled>(_onShuffled);
    on<StudySortChanged>(_onSortChanged);
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
    _subscribeProgress();
  }

  final DecksRepository _decks;
  final ProgressRepository _progress;
  final StorageRepository _storage;
  String? _requestedDeckId;
  late Set<String> _selectedIds;
  StreamSubscription<List<Deck>>? _decksSub;
  StreamSubscription<Map<String, Map<String, ProgressState>>>? _progressSub;

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
    _selectedIds = {event.deckId};
    _subscribeProgress();
    _rebuild(emit, filterOverride: StudyFilter.all, resetIdx: true);
    _persistViewState(
      deckId: event.deckId,
      filter: StudyFilter.all,
      selectedDeckIds: _selectedIds.toList(),
    );
  }

  void _onDeckToggled(
    StudyDeckToggled event,
    Emitter<StudyState> emit,
  ) {
    final next = {..._selectedIds};
    if (next.contains(event.deckId)) {
      if (next.length == 1) return; // never empty the selection
      next.remove(event.deckId);
    } else {
      next.add(event.deckId);
    }
    _selectedIds = next;
    if (!next.contains(_requestedDeckId)) {
      _requestedDeckId = next.isNotEmpty ? next.first : null;
    }
    _subscribeProgress();
    _rebuild(emit, resetIdx: true);
    _persistViewState(selectedDeckIds: next.toList());
  }

  void _onDecksReceived(
    StudyDecksReceived event,
    Emitter<StudyState> emit,
  ) {
    final decks = event.decks;
    if (_selectedIds.isEmpty && decks.isNotEmpty) {
      final picked = _pickDeck(decks);
      if (picked != null) {
        _selectedIds = {picked.id};
        _subscribeProgress();
      }
    }
    final selected = _resolveSelectedDecks(decks);
    final primary = selected.isEmpty ? null : selected.first;
    final isNewPrimary = primary?.id != state.deck?.id;
    _rebuild(emit, decksOverride: decks, resetIdx: isNewPrimary);
  }

  void _onProgressReceived(
    StudyProgressReceived event,
    Emitter<StudyState> emit,
  ) {
    _rebuild(emit, progressOverride: event.progressByDeck);
  }

  void _onFilterChanged(
    StudyFilterChanged event,
    Emitter<StudyState> emit,
  ) {
    if (event.filter == state.filter) return;
    _rebuild(emit, filterOverride: event.filter, resetIdx: true);
    _persistViewState(filter: event.filter);
  }

  void _onShuffled(StudyShuffled event, Emitter<StudyState> emit) {
    _rebuild(
      emit,
      sortOverride: StudySort.shuffle,
      seedOverride: state.shuffleSeed + 1,
      resetIdx: true,
    );
  }

  void _onSortChanged(StudySortChanged event, Emitter<StudyState> emit) {
    if (event.sort == state.sort && event.sort != StudySort.shuffle) return;
    _rebuild(emit, sortOverride: event.sort, resetIdx: true);
  }

  Future<void> _persistViewState({
    String? deckId,
    StudyFilter? filter,
    List<String>? selectedDeckIds,
  }) async {
    final snapshot = _storage.current;
    if (snapshot == null) return;
    final next = snapshot.copyWith(
      currentDeckId: deckId ?? snapshot.currentDeckId,
      filter: filter ?? snapshot.filter,
      selectedDeckIds: selectedDeckIds ?? snapshot.selectedDeckIds,
    );
    if (next == snapshot) return;
    await _storage.save(next);
  }

  void _subscribeProgress() {
    _progressSub?.cancel();
    if (_selectedIds.isEmpty) {
      _progressSub = null;
      return;
    }
    _progressSub = _progress.watchMany(_selectedIds).listen(
          (p) => add(StudyProgressReceived(p)),
        );
  }

  /// Decks currently selected, in [allDecks] order. Seeds the selection to the
  /// picked deck if it's empty so toggles always have a baseline.
  List<Deck> _resolveSelectedDecks(List<Deck> allDecks) {
    if (allDecks.isEmpty) return const [];
    final out = [
      for (final d in allDecks)
        if (_selectedIds.contains(d.id)) d,
    ];
    if (out.isNotEmpty) return out;
    final picked = _pickDeck(allDecks);
    if (picked == null) return const [];
    _selectedIds = {picked.id};
    return [picked];
  }

  void _rebuild(
    Emitter<StudyState> emit, {
    List<Deck>? decksOverride,
    Map<String, Map<String, ProgressState>>? progressOverride,
    StudyFilter? filterOverride,
    StudySort? sortOverride,
    int? seedOverride,
    bool resetIdx = false,
  }) {
    final allDecks = decksOverride ?? state.allDecks;
    final selectedDecks = _resolveSelectedDecks(allDecks);
    if (selectedDecks.isEmpty) {
      final stillLoading = allDecks.isEmpty && !_decks.libraryLoaded;
      emit(
        state.copyWith(
          status: stillLoading ? StudyStatus.loading : StudyStatus.empty,
          entries: const [],
          allDecks: allDecks,
          selectedDeckIds: _selectedIds,
          progressByDeck: progressOverride ?? const {},
          counts: const StudyCounts.zero(),
        ),
      );
      return;
    }
    final primary = selectedDecks.first;
    final progressByDeck = progressOverride ?? _progress.currentMany(_selectedIds);
    final filter = filterOverride ?? state.filter;
    final sort = sortOverride ?? state.sort;
    final seed = seedOverride ?? state.shuffleSeed;

    final all = <StudyEntry>[
      for (final d in selectedDecks)
        for (final c in d.cards) StudyEntry(deck: d, card: c),
    ];
    final filtered = _filterEntries(all, filter, progressByDeck);
    final ordered = _orderEntries(filtered, sort, progressByDeck, seed);
    final counts = _countEntries(all, progressByDeck);
    final newIdx = resetIdx
        ? 0
        : (ordered.isEmpty ? 0 : state.idx.clamp(0, ordered.length - 1));
    final newFlipped = resetIdx ? false : state.flipped;

    emit(
      state.copyWith(
        status: ordered.isEmpty ? StudyStatus.empty : StudyStatus.ready,
        deck: primary,
        entries: ordered,
        idx: newIdx,
        flipped: newFlipped,
        allDecks: allDecks,
        selectedDeckIds: _selectedIds,
        progressByDeck: progressByDeck,
        filter: filter,
        sort: sort,
        shuffleSeed: seed,
        counts: counts,
      ),
    );
  }

  List<StudyEntry> _filterEntries(
    List<StudyEntry> all,
    StudyFilter filter,
    Map<String, Map<String, ProgressState>> progress,
  ) {
    ProgressState? stateOf(StudyEntry e) => progress[e.deck.id]?[e.card.id];
    return switch (filter) {
      StudyFilter.all => all,
      // A flagged miss drops out once it's marked got or review.
      StudyFilter.miss =>
        all.where((e) => e.card.miss && stateOf(e) == null).toList(),
      StudyFilter.review =>
        all.where((e) => stateOf(e) == ProgressState.review).toList(),
      StudyFilter.got =>
        all.where((e) => stateOf(e) == ProgressState.got).toList(),
    };
  }

  List<StudyEntry> _orderEntries(
    List<StudyEntry> entries,
    StudySort sort,
    Map<String, Map<String, ProgressState>> progress,
    int seed,
  ) {
    switch (sort) {
      case StudySort.original:
        return entries;
      case StudySort.shuffle:
        return [...entries]..shuffle(Random(seed));
      case StudySort.reviewFirst:
        return _stateFirst(entries, progress, ProgressState.review);
      case StudySort.gotFirst:
        return _stateFirst(entries, progress, ProgressState.got);
    }
  }

  /// Stable partition: entries in [target] state keep their relative order at
  /// the front, everything else follows in original order.
  List<StudyEntry> _stateFirst(
    List<StudyEntry> entries,
    Map<String, Map<String, ProgressState>> progress,
    ProgressState target,
  ) {
    final match = <StudyEntry>[];
    final rest = <StudyEntry>[];
    for (final e in entries) {
      (progress[e.deck.id]?[e.card.id] == target ? match : rest).add(e);
    }
    return [...match, ...rest];
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

  StudyCounts _countEntries(
    List<StudyEntry> all,
    Map<String, Map<String, ProgressState>> progress,
  ) {
    var review = 0;
    var got = 0;
    var miss = 0;
    for (final e in all) {
      final p = progress[e.deck.id]?[e.card.id];
      if (p == ProgressState.review) review++;
      if (p == ProgressState.got) got++;
      // Outstanding misses only: a card you've marked got/review is resolved.
      if (e.card.miss && p == null) miss++;
    }
    return StudyCounts(all: all.length, miss: miss, review: review, got: got);
  }

  void _onFlipped(StudyFlipped event, Emitter<StudyState> emit) {
    if (state.status != StudyStatus.ready) return;
    emit(state.copyWith(flipped: !state.flipped));
  }

  void _onNext(StudyNext event, Emitter<StudyState> emit) {
    if (state.entries.isEmpty) return;
    final next = (state.idx + 1) % state.entries.length;
    emit(state.copyWith(idx: next, flipped: false));
  }

  void _onPrev(StudyPrev event, Emitter<StudyState> emit) {
    if (state.entries.isEmpty) return;
    final prev =
        (state.idx - 1 + state.entries.length) % state.entries.length;
    emit(state.copyWith(idx: prev, flipped: false));
  }

  Future<void> _onMarkReview(
    StudyMarkReview event,
    Emitter<StudyState> emit,
  ) async {
    final entry = state.currentEntry;
    if (entry == null) return;
    await _progress.toggle(entry.deck.id, entry.card.id, ProgressState.review);
  }

  Future<void> _onMarkGot(
    StudyMarkGot event,
    Emitter<StudyState> emit,
  ) async {
    final entry = state.currentEntry;
    if (entry == null) return;
    await _progress.toggle(entry.deck.id, entry.card.id, ProgressState.got);
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
