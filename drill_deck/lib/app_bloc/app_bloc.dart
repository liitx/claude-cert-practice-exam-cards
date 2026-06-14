import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:equatable/equatable.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({required StorageRepository storageRepository})
      : _storage = storageRepository,
        super(const AppState.initial()) {
    on<AppHydrationRequested>(_onHydrate);
    on<AppSnapshotReceived>(_onSnapshot);
    _subscription = _storage.watch().listen(
          (snapshot) => add(AppSnapshotReceived(snapshot)),
        );
  }

  final StorageRepository _storage;
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

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
