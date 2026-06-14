import 'package:drill_deck/features/study/widgets/scenario_chip.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:flutter/material.dart' hide Card;

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
                      Flexible(
                        child: Text(
                          card.topic,
                          style: mono.topic,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      if (card.miss && !isBack) _missPill(palette, mono),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _missPill(ScenarioPalette palette, MonoTypography mono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: palette.miss),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'YOU MISSED THIS',
        style: mono.chip.copyWith(color: palette.miss, letterSpacing: 0.5),
      ),
    );
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
