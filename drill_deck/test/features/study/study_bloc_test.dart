import 'package:bloc_test/bloc_test.dart';
import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/models/progress_state.dart';
import 'package:drill_deck/models/study_filter.dart';
import 'package:drill_deck/repositories/decks_repository.dart';
import 'package:drill_deck/repositories/progress_repository.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/subjects.dart';

class _MockDecks extends Mock implements DecksRepository {}

class _MockProgress extends Mock implements ProgressRepository {}

class _MockStorage extends Mock implements StorageRepository {}

void _registerFallbacks() {
  registerFallbackValue(ProgressState.review);
  registerFallbackValue(AppStateSnapshot.initial());
}

void main() {
  late _MockDecks repo;
  late _MockProgress progress;
  late _MockStorage storage;
  late BehaviorSubject<List<Deck>> stream;

  const deck = SharedDeck(
    id: 'd1',
    name: 'Deck 1',
    scenarios: {},
    cards: [
      BasicCard(id: 'c1', scn: '', topic: '', q: 'Q1', a: 'A1'),
      BasicCard(id: 'c2', scn: '', topic: '', q: 'Q2', a: 'A2'),
    ],
  );

  setUpAll(_registerFallbacks);

  setUp(() {
    repo = _MockDecks();
    progress = _MockProgress();
    storage = _MockStorage();
    stream = BehaviorSubject<List<Deck>>.seeded(const []);
    when(repo.watch).thenAnswer((_) => stream.stream);
    when(() => repo.libraryLoaded).thenReturn(true);
    when(repo.refreshShared).thenAnswer((_) async {});
    when(() => progress.watch(any())).thenAnswer((_) => const Stream.empty());
    when(() => progress.current(any())).thenReturn(<String, ProgressState>{});
    when(() => progress.toggle(any(), any(), any()))
        .thenAnswer((_) async {});
    when(() => progress.resetDeck(any())).thenAnswer((_) async {});
    when(() => storage.current).thenReturn(
      AppStateSnapshot.initial().copyWith(filter: StudyFilter.all),
    );
    when(() => storage.save(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await stream.close();
  });

  group('StudyBloc', () {
    blocTest<StudyBloc, StudyState>(
      'becomes ready when decks arrive and picks the first deck by default',
      build: () => StudyBloc(decksRepository: repo, progressRepository: progress, storageRepository: storage),
      act: (bloc) async {
        bloc.add(const StudyStarted());
        stream.add(const [deck]);
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state.status, StudyStatus.ready);
        expect(bloc.state.deck?.id, 'd1');
        expect(bloc.state.cards, hasLength(2));
        expect(bloc.state.idx, 0);
        expect(bloc.state.flipped, isFalse);
      },
    );

    blocTest<StudyBloc, StudyState>(
      'StudyFlipped toggles flipped only when ready',
      build: () => StudyBloc(decksRepository: repo, progressRepository: progress, storageRepository: storage),
      act: (bloc) async {
        bloc.add(const StudyStarted());
        stream.add(const [deck]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StudyFlipped());
        bloc.add(const StudyFlipped());
      },
      verify: (bloc) {
        expect(bloc.state.flipped, isFalse);
      },
    );

    blocTest<StudyBloc, StudyState>(
      'StudyNext / StudyPrev wrap around',
      build: () => StudyBloc(decksRepository: repo, progressRepository: progress, storageRepository: storage),
      act: (bloc) async {
        bloc.add(const StudyStarted());
        stream.add(const [deck]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StudyNext());
        bloc.add(const StudyNext()); // wraps
        bloc.add(const StudyPrev()); // back to 1
      },
      verify: (bloc) {
        expect(bloc.state.idx, 1);
      },
    );

    blocTest<StudyBloc, StudyState>(
      'StudyDeckRequested switches to the requested deck if present',
      build: () => StudyBloc(decksRepository: repo, progressRepository: progress, storageRepository: storage),
      act: (bloc) async {
        bloc.add(const StudyStarted());
        const second = SharedDeck(
          id: 'd2',
          name: 'Deck 2',
          scenarios: {},
          cards: [BasicCard(id: 'x', scn: '', topic: '', q: 'q', a: 'a')],
        );
        stream.add(const [deck, second]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StudyDeckRequested('d2'));
      },
      verify: (bloc) {
        expect(bloc.state.deck?.id, 'd2');
        expect(bloc.state.cards, hasLength(1));
      },
    );
  });
}
