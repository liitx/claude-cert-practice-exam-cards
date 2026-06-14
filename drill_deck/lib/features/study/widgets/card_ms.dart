import 'package:drill_deck/features/study/widgets/card_chrome.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:drill_deck/widgets/inline_html_text.dart';
import 'package:flutter/material.dart' hide Card;

class MultiSelectCardFront extends StatelessWidget {
  const MultiSelectCardFront({
    required this.card,
    required this.scenario,
    super.key,
  });
  final MultiSelectCard card;
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    _MSChoice(
                      letter: String.fromCharCode(65 + i),
                      text: card.choices[i],
                    ),
                ],
              ),
            ),
          ),
          const FlipHint('tap to reveal which apply'),
        ],
      ),
    );
  }
}

class MultiSelectCardBack extends StatelessWidget {
  const MultiSelectCardBack({
    required this.card,
    required this.scenario,
    super.key,
  });
  final MultiSelectCard card;
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final correctSet = card.correct.toSet();
    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FaceLabel('CORRECT SELECTIONS'),
            for (var i = 0; i < card.choices.length; i++)
              _MSChoice(
                letter: String.fromCharCode(65 + i),
                text: card.choices[i],
                isCorrect: correctSet.contains(i),
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
}

class _MSChoice extends StatelessWidget {
  const _MSChoice({
    required this.letter,
    required this.text,
    this.isCorrect,
  });
  final String letter;
  final String text;
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ScenarioPalette>()!;
    final mono = Theme.of(context).extension<MonoTypography>()!;
    final correct = isCorrect == true;
    final wrong = isCorrect == false;
    final borderColor =
        correct ? palette.got : (wrong ? AppColors.line : AppColors.line);
    final bg = correct
        ? palette.got.withValues(alpha: 0.12)
        : AppColors.ink;
    final letterBg = correct ? palette.got : AppColors.surface2;
    final letterFg = correct ? AppColors.ink : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(11),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: letterBg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                correct ? '✓' : letter,
                style: mono.chip.copyWith(
                  fontSize: 12.5,
                  color: letterFg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InlineHtmlText(
                  text,
                  baseStyle: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: correct ? Colors.white : AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
