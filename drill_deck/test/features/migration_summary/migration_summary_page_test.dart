import 'package:bloc_test/bloc_test.dart';
import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/features/migration_summary/view/migration_summary_page.dart';
import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

void main() {
  late _MockAppBloc bloc;

  setUp(() {
    bloc = _MockAppBloc();
  });

  Future<void> pump(WidgetTester tester, AppState state) async {
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.fromIterable([state]), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BlocProvider<AppBloc>.value(
          value: bloc,
          child: const MigrationSummaryPage(),
        ),
      ),
    );
  }

  testWidgets('shows progress indicator while loading', (tester) async {
    await pump(tester, const AppState.loading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows summary counts when ready', (tester) async {
    final snapshot = AppStateSnapshot.fromJson(const {
      'currentDeckId': 'cca-f',
      'progress': {
        'cca-f': {'ci1': 'review', 'ci2': 'got'},
      },
      'hiddenDecks': ['gone'],
    });
    await pump(tester, AppState.ready(snapshot));
    expect(find.text('drill_deck'), findsOneWidget);
    expect(find.text('current deck'), findsOneWidget);
    expect(find.text('cca-f'), findsOneWidget);
    expect(find.text('progress marks'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('hidden decks'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows failure message when status is failure', (tester) async {
    await pump(tester, const AppState.failure('disk full'));
    expect(find.textContaining('disk full'), findsOneWidget);
  });
}
