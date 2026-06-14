import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

class DeckSelector extends StatelessWidget {
  const DeckSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyBloc, StudyState>(
      buildWhen: (a, b) => a.allDecks != b.allDecks || a.deck != b.deck,
      builder: (context, state) {
        if (state.allDecks.length < 2) {
          return const SizedBox.shrink();
        }
        final currentId = state.deck?.id;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentId,
              dropdownColor: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              iconEnabledColor: AppColors.muted,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: [
                for (final d in state.allDecks)
                  DropdownMenuItem(
                    value: d.id,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          _DeckBadge(deck: d),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              d.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              onChanged: (id) {
                if (id != null) {
                  context.read<StudyBloc>().add(StudyDeckRequested(id));
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _DeckBadge extends StatelessWidget {
  const _DeckBadge({required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final isShared = deck is SharedDeck;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isShared
            ? AppColors.action.withValues(alpha: 0.18)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isShared ? AppColors.action : AppColors.line,
          width: 0.8,
        ),
      ),
      child: Text(
        isShared ? 'lib' : 'mine',
        style: TextStyle(
          fontSize: 9.5,
          color: isShared ? AppColors.action : AppColors.muted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          fontFamilyFallback: const ['SF Mono', 'Menlo', 'Consolas'],
        ),
      ),
    );
  }
}
