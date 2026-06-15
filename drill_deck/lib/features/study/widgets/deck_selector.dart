import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/features/editing/view/deck_name_sheet.dart';
import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/features/study/widgets/deck_group_sheet.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/widgets/entity_actions.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

class DeckSelector extends StatelessWidget {
  const DeckSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyBloc, StudyState>(
      buildWhen: (a, b) =>
          a.allDecks != b.allDecks ||
          a.deck != b.deck ||
          a.selectedDeckIds != b.selectedDeckIds,
      builder: (context, state) {
        final deck = state.deck;
        return Row(
          children: [
            Expanded(
              child: state.allDecks.length < 2
                  ? _CurrentDeckLabel(deck: deck)
                  : _Dropdown(decks: state.allDecks, currentId: deck?.id),
            ),
            const SizedBox(width: 2),
            IconButton(
              icon: Icon(
                Icons.library_add_check_outlined,
                color: state.selectedDeckIds.length > 1
                    ? AppColors.action
                    : AppColors.muted,
              ),
              tooltip: 'Study multiple decks',
              onPressed: () => DeckGroupSheet.show(context),
            ),
            if (deck != null) ...[
              const SizedBox(width: 2),
              _ManageMenu(deck: deck),
            ],
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.muted),
              tooltip: 'New deck',
              onPressed: () => DeckNameSheet.show(context),
            ),
          ],
        );
      },
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.decks, required this.currentId});
  final List<Deck> decks;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
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
            for (final d in decks)
              DropdownMenuItem(
                value: d.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _DeckBadge(deck: d),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(d.name, overflow: TextOverflow.ellipsis),
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
  }
}

class _CurrentDeckLabel extends StatelessWidget {
  const _CurrentDeckLabel({required this.deck});
  final Deck? deck;

  @override
  Widget build(BuildContext context) {
    if (deck == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _DeckBadge(deck: deck!),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              deck!.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rename/delete for the current deck via the generic [EntityActions] menu.
class _ManageMenu extends StatelessWidget {
  const _ManageMenu({required this.deck});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    return EntityActions(
      style: EntityActionStyle.menu,
      actions: [
        if (deck.canEdit)
          EntityAction(
            label: 'Rename',
            icon: Icons.edit_outlined,
            onTap: () => DeckNameSheet.show(
              context,
              deckId: deck.id,
              initialName: deck.name,
            ),
          ),
        if (deck.canDelete)
          EntityAction(
            label: deck.canHide ? 'Remove from my list' : 'Delete deck',
            icon: Icons.delete_outline,
            danger: true,
            onTap: () => _confirmDelete(context),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<AppBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(deck.canHide ? 'Remove "${deck.name}"?' : 'Delete "${deck.name}"?'),
        content: Text(
          deck.canHide
              ? 'It will be hidden from your list. Library decks can be restored later.'
              : 'This permanently removes the deck and its cards from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(deck.canHide ? 'Remove' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok ?? false) bloc.add(DeckDeleted(deck.id));
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
