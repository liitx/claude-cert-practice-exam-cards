import 'package:drill_deck/features/study/widgets/card_chrome.dart';
import 'package:drill_deck/features/study/widgets/card_mc.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:drill_deck/widgets/inline_html_text.dart';
import 'package:flutter/material.dart' hide Card;

class MultiSelectCardFront extends StatelessWidget {
  const MultiSelectCardFront({
    required this.card,
    required this.scenario,
    this.picked = const [],
    this.onToggle,
    super.key,
  });
  final MultiSelectCard card;
  final Scenario scenario;
  final List<int> picked;
  final ValueChanged<int>? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickedSet = picked.toSet();
    return CardFace(
      card: card,
      scenario: scenario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaceLabel('SELECT ALL THAT APPLY'),
          InlineHtmlText(
            card.q,
            baseStyle:
                (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
              fontSize: 17,
              height: 1.4,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < card.choices.length; i++)
                    ChoiceRow(
                      letter: String.fromCharCode(65 + i),
                      text: card.choices[i],
                      kind: pickedSet.contains(i)
                          ? ChoiceKind.picked
                          : ChoiceKind.idle,
                      onTap: onToggle == null ? null : () => onToggle!(i),
                    ),
                ],
              ),
            ),
          ),
          FlipHint(
            picked.isEmpty
                ? 'tap any that apply — then tap card to reveal'
                : 'tap card to reveal',
          ),
        ],
      ),
    );
  }
}

class MultiSelectCardBack extends StatelessWidget {
  const MultiSelectCardBack({
    required this.card,
    required this.scenario,
    this.picked = const [],
    super.key,
  });
  final MultiSelectCard card;
  final Scenario scenario;
  final List<int> picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final correctSet = card.correct.toSet();
    final pickedSet = picked.toSet();
    final answered = picked.isNotEmpty;
    final isCorrect = answered &&
        correctSet.length == pickedSet.length &&
        correctSet.containsAll(pickedSet);

    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (answered) _ResultBadge(correct: isCorrect),
            const FaceLabel('CORRECT SELECTIONS'),
            for (var i = 0; i < card.choices.length; i++)
              ChoiceRow(
                letter: String.fromCharCode(65 + i),
                text: card.choices[i],
                kind: _kindFor(i, correctSet, pickedSet),
              ),
            if (card.explanation != null && card.explanation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InlineHtmlText(
                card.explanation!,
                baseStyle:
                    (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
            ],
            if (card.why.isNotEmpty) ...[
              const SizedBox(height: 10),
              InlineHtmlText(
                card.why,
                baseStyle:
                    (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
            ],
            if (card.miss && card.pick != null && card.pick!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  'you originally picked ${card.pick}',
                  style: TextStyle(
                    color: palette.miss,
                    fontSize: 12.5,
                    fontFamilyFallback: const ['SF Mono', 'Menlo', 'Consolas'],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ChoiceKind _kindFor(int i, Set<int> correct, Set<int> picked) {
    if (correct.contains(i)) return ChoiceKind.correct;
    if (picked.contains(i)) return ChoiceKind.wrong;
    return ChoiceKind.idle;
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.correct});
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ScenarioPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: correct ? palette.got : palette.danger,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            correct ? 'CORRECT' : 'WRONG',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              fontFamilyFallback: ['SF Mono', 'Menlo', 'Consolas'],
            ),
          ),
        ),
      ),
    );
  }
}
