import 'package:drill_deck/features/study/widgets/card_chrome.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:flutter/material.dart' hide Card;

class BasicCardFront extends StatelessWidget {
  const BasicCardFront({required this.card, required this.scenario, super.key});
  final BasicCard card;
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
          const FaceLabel('SITUATION'),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                card.q,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  height: 1.45,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const FlipHint('tap or press space to reveal'),
        ],
      ),
    );
  }
}

class BasicCardBack extends StatelessWidget {
  const BasicCardBack({required this.card, required this.scenario, super.key});
  final BasicCard card;
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<ScenarioPalette>()!;
    return CardFace(
      card: card,
      scenario: scenario,
      isBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaceLabel('CORRECT APPROACH'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.a,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16.5,
                      height: 1.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (card.why.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      card.why,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                  if (card.miss && card.pick != null && card.pick!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: _OriginalPick(pick: card.pick!, palette: palette),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OriginalPick extends StatelessWidget {
  const _OriginalPick({required this.pick, required this.palette});
  final String pick;
  final ScenarioPalette palette;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: palette.miss,
        fontFamilyFallback: const ['SF Mono', 'Menlo', 'Consolas'],
        fontSize: 12.5,
      ),
      child: Row(
        children: [
          const Text('you originally picked '),
          Text(
            pick,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
