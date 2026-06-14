import 'package:drill_deck/models/scenario.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart';

class ScenarioChip extends StatelessWidget {
  const ScenarioChip({required this.scenario, super.key});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Color(scenario.argb),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        scenario.label.toUpperCase(),
        style: mono.chip.copyWith(color: AppColors.ink),
      ),
    );
  }
}
