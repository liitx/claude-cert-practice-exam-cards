import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Phase 1 placeholder. Confirms that the legacy migration round-tripped
/// localStorage into SharedPreferences by reporting the headline counts.
class MigrationSummaryPage extends StatelessWidget {
  const MigrationSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return switch (state.status) {
            AppStatus.initial || AppStatus.loading => const _Loading(),
            AppStatus.failure =>
              _Failure(message: state.errorMessage ?? 'Unknown error'),
            AppStatus.ready => _Summary(snapshot: state.snapshot!),
          };
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ScenarioPalette>()!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Hydration failed: $message',
          style: TextStyle(color: palette.danger),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.snapshot});
  final AppStateSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    final palette = Theme.of(context).extension<ScenarioPalette>()!;
    final theme = Theme.of(context);

    final privateDeckCount = snapshot.userDecks.length;
    final overlayCardCount = snapshot.overlayCards.values
        .fold<int>(0, (sum, list) => sum + list.length);
    final overlaySubjectCount = snapshot.overlayScenarios.values
        .fold<int>(0, (sum, map) => sum + map.length);
    final progressEntryCount = snapshot.progress.values
        .fold<int>(0, (sum, map) => sum + map.length);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.got,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'FLUTTER WEB · phase 1',
                  style: mono.chip.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'drill_deck',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: palette.action,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'If you see this page, the Flutter Web build is live. '
                'The static index.html on main is no longer being served. '
                'This is the Phase 1 placeholder showing the migration '
                'round-trip from localStorage into SharedPreferences.',
                style: mono.hint.copyWith(height: 1.55),
              ),
              const SizedBox(height: 28),
              _SummaryRow(
                label: 'current deck',
                value: snapshot.currentDeckId,
                mono: mono,
                theme: theme,
              ),
              _SummaryRow(
                label: 'private decks',
                value: '$privateDeckCount',
                mono: mono,
                theme: theme,
              ),
              _SummaryRow(
                label: 'overlay cards',
                value: '$overlayCardCount',
                mono: mono,
                theme: theme,
              ),
              _SummaryRow(
                label: 'overlay subjects',
                value: '$overlaySubjectCount',
                mono: mono,
                theme: theme,
              ),
              _SummaryRow(
                label: 'progress marks',
                value: '$progressEntryCount',
                mono: mono,
                theme: theme,
              ),
              _SummaryRow(
                label: 'hidden decks',
                value: '${snapshot.hiddenDecks.length}',
                mono: mono,
                theme: theme,
              ),
              _SummaryRow(
                label: 'view filter',
                value: snapshot.filter.id,
                mono: mono,
                theme: theme,
              ),
              const SizedBox(height: 24),
              Text(
                'Phase 2 plugs in the deck library and the study view.',
                style: mono.hint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.mono,
    required this.theme,
  });

  final String label;
  final String value;
  final MonoTypography mono;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: mono.topic)),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
