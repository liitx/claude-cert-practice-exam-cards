import 'package:drill_deck/features/study/widgets/card_chrome.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/widgets/inline_html_text.dart';
import 'package:flutter/material.dart' hide Card;

class FillInBlankCardFront extends StatelessWidget {
  const FillInBlankCardFront({
    required this.card,
    required this.scenario,
    super.key,
  });
  final FillInBlankCard card;
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
          const FaceLabel('FILL IN THE BLANK'),
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
          const FlipHint('tap to reveal accepted answers'),
        ],
      ),
    );
  }
}

class FillInBlankCardBack extends StatelessWidget {
  const FillInBlankCardBack({
    required this.card,
    required this.scenario,
    super.key,
  });
  final FillInBlankCard card;
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.extension<MonoTypography>()!;
    final accepted = card.accepted;
    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaceLabel(
              accepted.length > 1 ? 'ACCEPTED ANSWERS' : 'ACCEPTED ANSWER',
            ),
            if (accepted.isNotEmpty)
              InlineHtmlText(
                accepted.first,
                baseStyle:
                    (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                  fontSize: 16.5,
                  height: 1.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (accepted.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                'also: ${accepted.skip(1).join(', ')}',
                style: mono.hint,
              ),
            ],
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
