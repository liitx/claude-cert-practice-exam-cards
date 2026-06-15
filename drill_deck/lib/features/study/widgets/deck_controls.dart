import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/models/study_sort.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ordering controls for the current (already-filtered) card set: shuffle and
/// review/got-first sorting. Sorting runs after the filter, so shuffle
/// randomizes only the cards in view.
class DeckControls extends StatelessWidget {
  const DeckControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyBloc, StudyState>(
      buildWhen: (a, b) => a.sort != b.sort,
      builder: (context, state) {
        final mono = Theme.of(context).extension<MonoTypography>()!;
        final bloc = context.read<StudyBloc>();
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Pill(
              label: 'Shuffle',
              icon: Icons.shuffle,
              selected: state.sort == StudySort.shuffle,
              onTap: () => bloc.add(const StudyShuffled()),
              mono: mono,
            ),
            _Pill(
              label: 'Review first',
              selected: state.sort == StudySort.reviewFirst,
              onTap: () =>
                  bloc.add(const StudySortChanged(StudySort.reviewFirst)),
              mono: mono,
            ),
            _Pill(
              label: 'Got first',
              selected: state.sort == StudySort.gotFirst,
              onTap: () => bloc.add(const StudySortChanged(StudySort.gotFirst)),
              mono: mono,
            ),
            if (state.sort != StudySort.original)
              _Pill(
                label: 'Reset order',
                selected: false,
                onTap: () =>
                    bloc.add(const StudySortChanged(StudySort.original)),
                mono: mono,
              ),
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.mono,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final MonoTypography mono;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.action : AppColors.line;
    final textColor = selected ? AppColors.text : AppColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: textColor),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: mono.chip.copyWith(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
