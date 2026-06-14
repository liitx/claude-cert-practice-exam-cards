import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/repositories/decks_repository.dart';
import 'package:drill_deck/repositories/library_repository.dart';
import 'package:drill_deck/repositories/progress_repository.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:drill_deck/routing/app_router.dart';
import 'package:drill_deck/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatefulWidget {
  const App({
    required this.storageRepository,
    required this.libraryRepository,
    required this.decksRepository,
    required this.progressRepository,
    super.key,
  });

  final StorageRepository storageRepository;
  final LibraryRepository libraryRepository;
  final DecksRepository decksRepository;
  final ProgressRepository progressRepository;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.storageRepository),
        RepositoryProvider.value(value: widget.libraryRepository),
        RepositoryProvider.value(value: widget.decksRepository),
        RepositoryProvider.value(value: widget.progressRepository),
      ],
      child: BlocProvider(
        create: (_) => AppBloc(storageRepository: widget.storageRepository)
          ..add(const AppHydrationRequested()),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Drill Deck',
          theme: AppTheme.dark,
          routerConfig: _router,
        ),
      ),
    );
  }
}
