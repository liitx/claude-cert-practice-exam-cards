import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/features/migration_summary/view/migration_summary_page.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:drill_deck/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({required this.storageRepository, super.key});

  final StorageRepository storageRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: storageRepository,
      child: BlocProvider(
        create: (_) =>
            AppBloc(storageRepository: storageRepository)
              ..add(const AppHydrationRequested()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Drill Deck',
          theme: AppTheme.dark,
          home: const MigrationSummaryPage(),
        ),
      ),
    );
  }
}
