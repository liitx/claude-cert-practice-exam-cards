import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/repositories/decks_repository.dart';
import 'package:drill_deck/repositories/library_repository.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/subjects.dart';

class _MockStorage extends Mock implements StorageRepository {}

class _MockLibrary extends Mock implements LibraryRepository {}

void main() {
  late _MockStorage storage;
  late _MockLibrary library;
  late BehaviorSubject<AppStateSnapshot> storageStream;

  setUp(() {
    storage = _MockStorage();
    library = _MockLibrary();
    storageStream = BehaviorSubject<AppStateSnapshot>.seeded(
      AppStateSnapshot.initial(),
    );
    when(storage.watch).thenAnswer((_) => storageStream.stream);
  });

  tearDown(() async {
    await storageStream.close();
  });

  test('refreshShared loads shared decks and emits merged list', () async {
    final shared = [
      const SharedDeck(id: 's', name: 'Shared', scenarios: {}, cards: []),
    ];
    when(library.fetchShared).thenAnswer((_) async => shared);

    final repo = DecksRepository(storage: storage, library: library);
    await repo.refreshShared();

    expect(repo.current, hasLength(1));
    expect(repo.current.first.id, 's');
    expect(repo.libraryLoaded, isTrue);
    await repo.dispose();
  });

  test('reacts to storage updates by merging user decks', () async {
    when(library.fetchShared).thenAnswer((_) async => const []);
    final repo = DecksRepository(storage: storage, library: library);
    await repo.refreshShared();
    expect(repo.current, isEmpty);

    storageStream.add(
      AppStateSnapshot.initial().copyWith(
        userDecks: const [
          PrivateDeck(id: 'p1', name: 'Mine', scenarios: {}, cards: []),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repo.current, hasLength(1));
    expect(repo.current.first.id, 'p1');
    await repo.dispose();
  });

  test('local deck wins over a shared deck with the same id', () async {
    when(library.fetchShared).thenAnswer(
      (_) async => const [
        SharedDeck(id: 'cca-f', name: 'Library', scenarios: {}, cards: []),
      ],
    );
    final repo = DecksRepository(storage: storage, library: library);
    await repo.refreshShared();
    expect(repo.current.single.name, 'Library');

    storageStream.add(
      AppStateSnapshot.initial().copyWith(
        userDecks: const [
          PrivateDeck(id: 'cca-f', name: 'My Fork', scenarios: {}, cards: []),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final decks = repo.current;
    expect(decks, hasLength(1));
    expect(decks.single, isA<PrivateDeck>());
    expect(decks.single.name, 'My Fork');
    await repo.dispose();
  });

  test('hidden decks drop out of the merged list', () async {
    when(library.fetchShared).thenAnswer(
      (_) async => const [
        SharedDeck(id: 'cca-f', name: 'Library', scenarios: {}, cards: []),
      ],
    );
    final repo = DecksRepository(storage: storage, library: library);
    await repo.refreshShared();

    storageStream.add(
      AppStateSnapshot.initial().copyWith(hiddenDecks: const ['cca-f']),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repo.current, isEmpty);
    await repo.dispose();
  });

  test('library fetch failure leaves libraryLoaded true with empty shared',
      () async {
    when(library.fetchShared).thenThrow(
      const LibraryFetchException('boom'),
    );
    final repo = DecksRepository(storage: storage, library: library);
    await repo.refreshShared();
    expect(repo.libraryLoaded, isTrue);
    expect(repo.current, isEmpty);
    await repo.dispose();
  });
}
