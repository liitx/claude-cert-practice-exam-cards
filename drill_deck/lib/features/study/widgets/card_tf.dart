import 'package:drill_deck/features/study/widgets/card_chrome.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:drill_deck/widgets/inline_html_text.dart';
import 'package:flutter/material.dart' hide Card;

class TrueFalseCardFront extends StatelessWidget {
  const TrueFalseCardFront({
    required this.card,
    required this.scenario,
    super.key,
  });
  final TrueFalseCard card;
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
          const FaceLabel('TRUE OR FALSE'),
          Expanded(
            child: SingleChildScrollView(
              child: InlineHtmlText(
                card.q,
                baseStyle:
                    (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                  fontSize: 18,
                  height: 1.45,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const FlipHint('tap to reveal the answer'),
        ],
      ),
    );
  }
}

class TrueFalseCardBack extends StatelessWidget {
  const TrueFalseCardBack({
    required this.card,
    required this.scenario,
    super.key,
  });
  final TrueFalseCard card;
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final isTrue = card.correct;
    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FaceLabel('CORRECT ANSWER'),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: palette.got.withValues(alpha: 0.12),
                border: Border.all(color: palette.got, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.got,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isTrue ? 'True' : 'False',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (card.explanation != null && card.explanation!.isNotEmpty) ...[
              const SizedBox(height: 14),
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
          ],
        ),
      ),
    );
  }
}
