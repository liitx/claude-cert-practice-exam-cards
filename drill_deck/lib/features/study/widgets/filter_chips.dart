import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/models/study_filter.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyBloc, StudyState>(
      buildWhen: (a, b) =>
          a.filter != b.filter || a.counts != b.counts,
      builder: (context, state) {
        final mono = Theme.of(context).extension<MonoTypography>()!;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final entry in const [
              MapEntry(StudyFilter.miss, 'My misses'),
              MapEntry(StudyFilter.all, 'All'),
              MapEntry(StudyFilter.review, 'Review'),
              MapEntry(StudyFilter.got, 'Got it'),
            ])
              _Chip(
                label: entry.value,
                count: state.counts.forFilter(entry.key),
                selected: state.filter == entry.key,
                onTap: () => context
                    .read<StudyBloc>()
                    .add(StudyFilterChanged(entry.key)),
                mono: mono,
              ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.mono,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final MonoTypography mono;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.action : AppColors.line;
    final bg = selected ? AppColors.surface2 : Colors.transparent;
    final textColor = selected ? AppColors.text : AppColors.muted;
    final countColor = selected ? AppColors.action : AppColors.faint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: mono.chip.copyWith(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: mono.chip.copyWith(
                color: countColor,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
