import 'package:drill_deck/features/study/widgets/card_chrome.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:flutter/material.dart' hide Card;

class MultipleChoiceCardFront extends StatelessWidget {
  const MultipleChoiceCardFront({
    required this.card,
    required this.scenario,
    super.key,
  });
  final MultipleChoiceCard card;
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
          const FaceLabel('QUESTION'),
          Text(
            card.q,
            style: theme.textTheme.titleMedium?.copyWith(
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
                    _ChoiceRow(
                      letter: String.fromCharCode(65 + i),
                      text: card.choices[i],
                    ),
                ],
              ),
            ),
          ),
          const FlipHint('tap to reveal the correct answer'),
        ],
      ),
    );
  }
}

class MultipleChoiceCardBack extends StatelessWidget {
  const MultipleChoiceCardBack({
    required this.card,
    required this.scenario,
    super.key,
  });
  final MultipleChoiceCard card;
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final correctIdx = card.correct;
    final correctSafe = correctIdx >= 0 && correctIdx < card.choices.length;
    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FaceLabel('CORRECT ANSWER'),
            if (correctSafe)
              Text(
                '${String.fromCharCode(65 + correctIdx)} · ${card.choices[correctIdx]}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16.5,
                  height: 1.45,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 18),
            for (var i = 0; i < card.choices.length; i++)
              _ChoiceRow(
                letter: String.fromCharCode(65 + i),
                text: card.choices[i],
                highlight: i == correctIdx ? _ChoiceHighlight.correct : null,
              ),
            if (card.explanation != null && card.explanation!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                card.explanation!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
            ],
            if (card.why.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                card.why,
                style: theme.textTheme.bodyMedium?.copyWith(
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

enum _ChoiceHighlight { correct }

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.letter,
    required this.text,
    this.highlight,
  });
  final String letter;
  final String text;
  final _ChoiceHighlight? highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final mono = theme.extension<MonoTypography>()!;
    final isCorrect = highlight == _ChoiceHighlight.correct;
    final borderColor = isCorrect ? palette.got : AppColors.line;
    final bg = isCorrect
        ? palette.got.withValues(alpha: 0.12)
        : AppColors.ink;
    final letterBg = isCorrect ? palette.got : AppColors.surface2;
    final letterFg = isCorrect ? AppColors.ink : AppColors.muted;

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
                letter,
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
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isCorrect ? Colors.white : AppColors.text,
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
