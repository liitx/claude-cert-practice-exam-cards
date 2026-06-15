import 'package:bloc_test/bloc_test.dart';
import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/repositories/decks_repository.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageRepository {}

class _MockDecks extends Mock implements DecksRepository {}

void main() {
  late StorageRepository storage;
  late DecksRepository decks;
  late AppStateSnapshot initial;

  AppBloc buildBloc() =>
      AppBloc(storageRepository: storage, decksRepository: decks);

  setUpAll(() {
    registerFallbackValue(AppStateSnapshot.initial());
  });

  setUp(() {
    storage = _MockStorage();
    decks = _MockDecks();
    initial = AppStateSnapshot.initial();
    when(storage.watch).thenAnswer((_) => const Stream.empty());
    when(storage.hydrate).thenAnswer((_) async => initial);
    when(() => storage.save(any())).thenAnswer((_) async {});
    when(() => decks.current).thenReturn(const []);
  });

  group('AppBloc', () {
    blocTest<AppBloc, AppState>(
      'emits loading then ready on AppHydrationRequested',
      build: buildBloc,
      act: (bloc) => bloc.add(const AppHydrationRequested()),
      expect: () => [
        const AppState.loading(),
        AppState.ready(initial),
      ],
    );

    blocTest<AppBloc, AppState>(
      'emits failure when hydrate throws',
      setUp: () {
        when(storage.hydrate).thenThrow(StateError('boom'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AppHydrationRequested()),
      expect: () => [
        const AppState.loading(),
        isA<AppState>().having(
          (s) => s.status,
          'status',
          AppStatus.failure,
        ),
      ],
    );

    blocTest<AppBloc, AppState>(
      'AppSnapshotReceived emits ready with new snapshot',
      build: buildBloc,
      seed: () => AppState.ready(initial),
      act: (bloc) {
        final next = initial.copyWith(cardIndex: 5);
        bloc.add(AppSnapshotReceived(next));
      },
      expect: () => [
        AppState.ready(initial.copyWith(cardIndex: 5)),
      ],
    );
  });

  group('AppBloc mutations', () {
    AppStateSnapshot lastSaved() {
      final captured = verify(() => storage.save(captureAny())).captured;
      return captured.last as AppStateSnapshot;
    }

    blocTest<AppBloc, AppState>(
      'DeckCreated adds a private deck and selects it',
      build: buildBloc,
      seed: () => AppState.ready(initial),
      act: (bloc) => bloc.add(const DeckCreated('My New Deck')),
      verify: (_) {
        final saved = lastSaved();
        expect(saved.userDecks, hasLength(1));
        expect(saved.userDecks.first.name, 'My New Deck');
        expect(saved.currentDeckId, saved.userDecks.first.id);
      },
    );

    blocTest<AppBloc, AppState>(
      'CardUpserted forks a shared deck into a local editable copy',
      setUp: () {
        when(() => decks.current).thenReturn([
          const SharedDeck(
            id: 'cca-f',
            name: 'Shared',
            scenarios: {},
            cards: [BasicCard(id: 'c1', scn: 'S', topic: 't', q: 'q', a: 'a')],
          ),
        ]);
      },
      build: buildBloc,
      seed: () => AppState.ready(initial),
      act: (bloc) => bloc.add(
        const CardUpserted(
          'cca-f',
          BasicCard(
            id: 'c2',
            scn: 'S',
            topic: 't',
            q: 'new',
            a: 'a',
            userOwned: true,
          ),
        ),
      ),
      verify: (_) {
        final saved = lastSaved();
        expect(saved.userDecks, hasLength(1));
        final forked = saved.userDecks.first;
        expect(forked.id, 'cca-f');
        // Original card carried over + the new one.
        expect(forked.cards.map((c) => c.id), containsAll(['c1', 'c2']));
        expect(forked.cards.every((c) => c.userOwned), isTrue);
      },
    );

    blocTest<AppBloc, AppState>(
      'CardDeleted removes a card from the local copy',
      build: buildBloc,
      seed: () => AppState.ready(
        initial.copyWith(
          userDecks: [
            const PrivateDeck(
              id: 'mine',
              name: 'Mine',
              scenarios: {},
              cards: [
                BasicCard(id: 'a', scn: 'S', topic: 't', q: 'q', a: 'a'),
                BasicCard(id: 'b', scn: 'S', topic: 't', q: 'q', a: 'a'),
              ],
            ),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const CardDeleted('mine', 'a')),
      verify: (_) {
        final saved = lastSaved();
        expect(saved.userDecks.first.cards.map((c) => c.id), ['b']);
      },
    );

    blocTest<AppBloc, AppState>(
      'DeckDeleted hides a shared deck and drops any local copy',
      setUp: () {
        when(() => decks.current).thenReturn([
          const SharedDeck(id: 'cca-f', name: 'Shared', scenarios: {}, cards: []),
        ]);
      },
      build: buildBloc,
      seed: () => AppState.ready(
        initial.copyWith(
          userDecks: [
            const PrivateDeck(id: 'cca-f', name: 'Fork', scenarios: {}, cards: []),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const DeckDeleted('cca-f')),
      verify: (_) {
        final saved = lastSaved();
        expect(saved.userDecks, isEmpty);
        expect(saved.hiddenDecks, contains('cca-f'));
      },
    );
  });
}
