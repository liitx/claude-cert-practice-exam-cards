import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:drill_deck/app/view/app.dart';
import 'package:drill_deck/repositories/migration/legacy_migrator.dart';
import 'package:drill_deck/repositories/storage_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('${bloc.runtimeType}: $change');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType} error', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap() async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = _AppBlocObserver();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageRepository(
        prefs: prefs,
        legacyMigrator: LegacyMigrator(),
      );
      runApp(App(storageRepository: storage));
    },
    (error, stackTrace) {
      log('uncaught error', error: error, stackTrace: stackTrace);
    },
  );
}
