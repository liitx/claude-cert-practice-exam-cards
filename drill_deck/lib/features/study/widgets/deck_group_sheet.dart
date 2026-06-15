import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Checklist of all decks for building a group study session. Toggling a deck
/// dispatches [StudyDeckToggled]; the session always keeps at least one deck.
class DeckGroupSheet extends StatelessWidget {
  const DeckGroupSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<StudyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const DeckGroupSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: BlocBuilder<StudyBloc, StudyState>(
          buildWhen: (a, b) =>
              a.allDecks != b.allDecks || a.selectedDeckIds != b.selectedDeckIds,
          builder: (context, state) {
            final selected = state.selectedDeckIds;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Text(
                    'Study decks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Pick one or more decks to study together.',
                    style: mono.hint,
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final d in state.allDecks)
                        CheckboxListTile(
                          value: selected.contains(d.id),
                          onChanged: (_) =>
                              context.read<StudyBloc>().add(StudyDeckToggled(d.id)),
                          activeColor: AppColors.action,
                          title: Text(
                            d.name,
                            style: const TextStyle(color: AppColors.text),
                          ),
                          secondary: _Badge(deck: d),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final isShared = deck is SharedDeck;
    return Text(
      isShared ? 'lib' : 'mine',
      style: TextStyle(
        fontSize: 10,
        color: isShared ? AppColors.action : AppColors.muted,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: const ['SF Mono', 'Menlo', 'Consolas'],
      ),
    );
  }
}
