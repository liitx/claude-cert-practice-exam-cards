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
    this.picked,
    this.onPick,
    super.key,
  });
  final TrueFalseCard card;
  final Scenario scenario;
  final bool? picked;
  final ValueChanged<bool>? onPick;

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
          InlineHtmlText(
            card.q,
            baseStyle:
                (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
              fontSize: 17,
              height: 1.45,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _TFButton(
                  label: 'True',
                  selected: picked == true,
                  onTap: onPick == null ? null : () => onPick!(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TFButton(
                  label: 'False',
                  selected: picked == false,
                  onTap: onPick == null ? null : () => onPick!(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FlipHint(
            picked == null
                ? 'pick one — then tap card to reveal'
                : 'tap card to reveal',
          ),
        ],
      ),
    );
  }
}

class TrueFalseCardBack extends StatelessWidget {
  const TrueFalseCardBack({
    required this.card,
    required this.scenario,
    this.picked,
    super.key,
  });
  final TrueFalseCard card;
  final Scenario scenario;
  final bool? picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final isCorrect = picked != null && picked == card.correct;
    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (picked != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect ? palette.got : palette.danger,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isCorrect ? 'CORRECT' : 'WRONG',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        fontFamilyFallback: [
                          'SF Mono',
                          'Menlo',
                          'Consolas',
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const FaceLabel('CORRECT ANSWER'),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
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
                    card.correct ? 'True' : 'False',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (picked != null && !isCorrect) ...[
              const SizedBox(height: 10),
              Text(
                'you picked ${picked! ? 'True' : 'False'}',
                style: TextStyle(
                  color: palette.danger,
                  fontSize: 13,
                  fontFamilyFallback: const [
                    'SF Mono',
                    'Menlo',
                    'Consolas',
                  ],
                ),
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

class _TFButton extends StatelessWidget {
  const _TFButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ScenarioPalette>()!;
    final borderColor = selected ? palette.action : AppColors.line;
    final bg = selected
        ? palette.action.withValues(alpha: 0.12)
        : AppColors.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
