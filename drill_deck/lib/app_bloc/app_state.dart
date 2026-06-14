part of 'app_bloc.dart';

enum AppStatus { initial, loading, ready, failure }

final class AppState extends Equatable {
  const AppState({
    required this.status,
    this.snapshot,
    this.errorMessage,
  });

  const AppState.initial() : this(status: AppStatus.initial);
  const AppState.loading() : this(status: AppStatus.loading);
  const AppState.ready(AppStateSnapshot snapshot)
      : this(status: AppStatus.ready, snapshot: snapshot);
  const AppState.failure(String message)
      : this(status: AppStatus.failure, errorMessage: message);

  final AppStatus status;
  final AppStateSnapshot? snapshot;
  final String? errorMessage;

  AppState copyWith({
    AppStatus? status,
    AppStateSnapshot? snapshot,
    String? errorMessage,
  }) {
    return AppState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, errorMessage];
}
