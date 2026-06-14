import 'package:drill_deck/features/study/widgets/card_chrome.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:drill_deck/widgets/inline_html_text.dart';
import 'package:flutter/material.dart' hide Card;

class MultipleChoiceCardFront extends StatelessWidget {
  const MultipleChoiceCardFront({
    required this.card,
    required this.scenario,
    this.picked,
    this.onPick,
    super.key,
  });
  final MultipleChoiceCard card;
  final Scenario scenario;
  final int? picked;
  final ValueChanged<int>? onPick;

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
          InlineHtmlText(
            card.q,
            baseStyle: (theme.textTheme.titleMedium ?? const TextStyle())
                .copyWith(
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
                      kind: i == picked
                          ? ChoiceKind.picked
                          : ChoiceKind.idle,
                      onTap: onPick == null ? null : () => onPick!(i),
                    ),
                ],
              ),
            ),
          ),
          FlipHint(
            picked == null
                ? 'pick a choice — tap card to reveal'
                : 'tap card to reveal',
          ),
        ],
      ),
    );
  }
}

class MultipleChoiceCardBack extends StatelessWidget {
  const MultipleChoiceCardBack({
    required this.card,
    required this.scenario,
    this.picked,
    super.key,
  });
  final MultipleChoiceCard card;
  final Scenario scenario;
  final int? picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final correctIdx = card.correct;
    final correctSafe = correctIdx >= 0 && correctIdx < card.choices.length;
    final wasCorrect = picked == correctIdx;
    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (picked != null) _ResultBadge(correct: wasCorrect),
            const FaceLabel('CORRECT ANSWER'),
            if (correctSafe)
              InlineHtmlText(
                '${String.fromCharCode(65 + correctIdx)} · ${card.choices[correctIdx]}',
                baseStyle: (theme.textTheme.titleMedium ?? const TextStyle())
                    .copyWith(
                  fontSize: 16.5,
                  height: 1.45,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 18),
            for (var i = 0; i < card.choices.length; i++)
              ChoiceRow(
                letter: String.fromCharCode(65 + i),
                text: card.choices[i],
                kind: _kindFor(i),
              ),
            if (card.explanation != null && card.explanation!.isNotEmpty) ...[
              const SizedBox(height: 14),
              InlineHtmlText(
                card.explanation!,
                baseStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
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
                baseStyle: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
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

  ChoiceKind _kindFor(int i) {
    if (i == card.correct) return ChoiceKind.correct;
    if (i == picked) return ChoiceKind.wrong;
    return ChoiceKind.idle;
  }
}

enum ChoiceKind { idle, picked, correct, wrong }

/// Reusable row used by both MC and MS card faces.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    required this.letter,
    required this.text,
    required this.kind,
    this.onTap,
    super.key,
  });

  final String letter;
  final String text;
  final ChoiceKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final mono = theme.extension<MonoTypography>()!;
    final colors = _colorsFor(kind, palette);

    final row = Container(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border.all(color: colors.border, width: 1.5),
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
              color: colors.letterBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              colors.letterText ?? letter,
              style: mono.chip.copyWith(
                fontSize: 12.5,
                color: colors.letterFg,
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
                  color: colors.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final wrapped = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: row,
    );

    if (onTap == null) return wrapped;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }

  _ChoiceColors _colorsFor(ChoiceKind k, ScenarioPalette palette) {
    switch (k) {
      case ChoiceKind.idle:
        return _ChoiceColors(
          bg: AppColors.ink,
          border: AppColors.line,
          letterBg: AppColors.surface2,
          letterFg: AppColors.muted,
          textColor: AppColors.text,
        );
      case ChoiceKind.picked:
        return _ChoiceColors(
          bg: AppColors.action.withValues(alpha: 0.1),
          border: AppColors.action,
          letterBg: AppColors.action,
          letterFg: Colors.white,
          textColor: AppColors.text,
        );
      case ChoiceKind.correct:
        return _ChoiceColors(
          bg: palette.got.withValues(alpha: 0.12),
          border: palette.got,
          letterBg: palette.got,
          letterFg: AppColors.ink,
          textColor: Colors.white,
          letterText: '✓',
        );
      case ChoiceKind.wrong:
        return _ChoiceColors(
          bg: palette.danger.withValues(alpha: 0.1),
          border: palette.danger,
          letterBg: palette.danger,
          letterFg: Colors.white,
          textColor: AppColors.text,
          letterText: '×',
        );
    }
  }
}

class _ChoiceColors {
  _ChoiceColors({
    required this.bg,
    required this.border,
    required this.letterBg,
    required this.letterFg,
    required this.textColor,
    this.letterText,
  });
  final Color bg;
  final Color border;
  final Color letterBg;
  final Color letterFg;
  final Color textColor;
  final String? letterText;
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.correct});
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ScenarioPalette>()!;
    final mono = Theme.of(context).extension<MonoTypography>()!;
    final bg = correct ? palette.got : palette.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            correct ? 'CORRECT' : 'WRONG',
            style: mono.chip.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
