import 'package:bloc_test/bloc_test.dart';
import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageRepository {}

void main() {
  late StorageRepository storage;
  late AppStateSnapshot initial;

  setUp(() {
    storage = _MockStorage();
    initial = AppStateSnapshot.initial();
    when(storage.watch).thenAnswer((_) => const Stream.empty());
    when(storage.hydrate).thenAnswer((_) async => initial);
  });

  group('AppBloc', () {
    blocTest<AppBloc, AppState>(
      'emits loading then ready on AppHydrationRequested',
      build: () => AppBloc(storageRepository: storage),
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
      build: () => AppBloc(storageRepository: storage),
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
      build: () => AppBloc(storageRepository: storage),
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
}
