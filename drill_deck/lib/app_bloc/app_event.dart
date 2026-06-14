part of 'app_bloc.dart';

sealed class AppEvent extends Equatable {
  const AppEvent();
  @override
  List<Object?> get props => const [];
}

final class AppHydrationRequested extends AppEvent {
  const AppHydrationRequested();
}

final class AppSnapshotReceived extends AppEvent {
  const AppSnapshotReceived(this.snapshot);
  final AppStateSnapshot snapshot;
  @override
  List<Object?> get props => [snapshot];
}
