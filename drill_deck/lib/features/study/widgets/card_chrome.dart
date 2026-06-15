import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/features/editing/view/card_editor_sheet.dart';
import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/features/study/widgets/scenario_chip.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:drill_deck/widgets/entity_actions.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shared face shell: rounded card, scenario stripe down the left,
/// topic + scenario chip header, optional MISSED pill. Children fill the
/// remaining space.
class CardFace extends StatelessWidget {
  const CardFace({
    required this.card,
    required this.scenario,
    required this.child,
    this.isBack = false,
    super.key,
  });

  final Card card;
  final Scenario scenario;
  final Widget child;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.extension<MonoTypography>()!;
    final palette = theme.extension<ScenarioPalette>()!;
    final accent = Color(scenario.argb);
    // "YOU MISSED THIS" reflects the static import flag until the user resolves
    // the card (got it / review) — then it tones down, matching the miss count.
    // Resolve progress via the card's owning deck for group sessions.
    final studyState = context.watch<StudyBloc>().state;
    final ownerId = studyState.currentDeck?.id;
    final progress = studyState.progressByDeck[ownerId]?[card.id];
    final resolved = progress != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isBack ? AppColors.surface2 : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: ColoredBox(color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ScenarioChip(scenario: scenario),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          card.topic,
                          style: mono.topic,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (card.miss && !isBack)
                        _missPill(palette, mono, dimmed: resolved),
                      if (!isBack) const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(child: child),
                ],
              ),
            ),
            if (!isBack)
              Positioned(
                top: 12,
                right: 12,
                child: _CardActions(card: card, color: accent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _missPill(
    ScenarioPalette palette,
    MonoTypography mono, {
    bool dimmed = false,
  }) {
    final color = dimmed ? AppColors.muted : palette.miss;
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          'YOU MISSED THIS',
          style: mono.chip.copyWith(color: color, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

/// Adapter: turns the generic [EntityActions] into card edit/delete wired to
/// the current deck. Capability is derived from the card at render time
/// ([CardCapabilities]), so every card gets the same actions regardless of age.
class _CardActions extends StatelessWidget {
  const _CardActions({required this.card, required this.color});
  final Card card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Owning deck of the current card (may differ from primary in a group).
    final deckId = context.read<StudyBloc>().state.currentDeck?.id;
    if (deckId == null) return const SizedBox.shrink();
    return EntityActions(
      style: EntityActionStyle.menu,
      iconColor: color,
      actions: [
        if (card.canEdit)
          EntityAction(
            label: 'Edit card',
            icon: Icons.edit_outlined,
            onTap: () =>
                CardEditorSheet.show(context, deckId: deckId, card: card),
          ),
        if (card.canDelete)
          EntityAction(
            label: 'Delete card',
            icon: Icons.delete_outline,
            danger: true,
            onTap: () => _confirmDelete(context, deckId),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String deckId) async {
    final bloc = context.read<AppBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Delete this card?'),
        content: Text(card.q, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok ?? false) bloc.add(CardDeleted(deckId, card.id));
  }
}

/// Tiny label used above the question / answer body ("SITUATION", "QUESTION",
/// "CORRECT APPROACH"). Matches the static site's uppercase mono tag.
class FaceLabel extends StatelessWidget {
  const FaceLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: mono.chip.copyWith(
          letterSpacing: 1.2,
          color: const Color(0xFF5B606D),
        ),
      ),
    );
  }
}

class FlipHint extends StatelessWidget {
  const FlipHint(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(text, style: mono.hint),
      ),
    );
  }
}
