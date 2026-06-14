import 'package:drill_deck/features/study/widgets/card_chrome.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:drill_deck/widgets/inline_html_text.dart';
import 'package:flutter/material.dart' hide Card;

class FillInBlankCardFront extends StatefulWidget {
  const FillInBlankCardFront({
    required this.card,
    required this.scenario,
    this.picked,
    this.onChanged,
    super.key,
  });
  final FillInBlankCard card;
  final Scenario scenario;
  final String? picked;
  final ValueChanged<String>? onChanged;

  @override
  State<FillInBlankCardFront> createState() => _FillInBlankCardFrontState();
}

class _FillInBlankCardFrontState extends State<FillInBlankCardFront> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.picked ?? '');
  }

  @override
  void didUpdateWidget(covariant FillInBlankCardFront old) {
    super.didUpdateWidget(old);
    if (widget.card.id != old.card.id &&
        _controller.text != (widget.picked ?? '')) {
      _controller.text = widget.picked ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CardFace(
      card: widget.card,
      scenario: widget.scenario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaceLabel('FILL IN THE BLANK'),
          InlineHtmlText(
            widget.card.q,
            baseStyle:
                (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
              fontSize: 17,
              height: 1.45,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              autofocus: false,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
                hintText: 'Type your answer',
                filled: true,
                fillColor: AppColors.ink,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(11)),
                ),
              ),
            ),
          ),
          const Spacer(),
          FlipHint(
            (widget.picked == null || widget.picked!.trim().isEmpty)
                ? 'type an answer — then tap card to reveal'
                : 'tap card to reveal',
          ),
        ],
      ),
    );
  }
}

class FillInBlankCardBack extends StatelessWidget {
  const FillInBlankCardBack({
    required this.card,
    required this.scenario,
    this.picked,
    super.key,
  });
  final FillInBlankCard card;
  final Scenario scenario;
  final String? picked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    final mono = theme.extension<MonoTypography>()!;
    final accepted = card.accepted;
    final isCorrect = picked != null && card.isCorrect(picked!);
    final answered = picked != null && picked!.trim().isNotEmpty;
    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (answered)
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
            if (answered && !isCorrect) ...[
              const SizedBox(height: 12),
              Text(
                'you typed: ${picked!.trim()}',
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
