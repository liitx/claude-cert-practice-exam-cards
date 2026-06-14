import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/models/progress_state.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/scenario_palette.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

class StudyControls extends StatelessWidget {
  const StudyControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyBloc, StudyState>(
      buildWhen: (a, b) =>
          a.currentCardProgress != b.currentCardProgress ||
          a.cards.length != b.cards.length,
      builder: (context, state) {
        final palette = Theme.of(context).extension<ScenarioPalette>()!;
        final p = state.currentCardProgress;
        final canNav = state.cards.length > 1;
        final canMark = state.cards.isNotEmpty;
        return Row(
          children: [
            _NavButton(
              icon: '←',
              onPressed:
                  canNav ? () => context.read<StudyBloc>().add(const StudyPrev()) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MarkButton(
                label: '⟲ Review',
                fg: palette.miss,
                bg: const Color(0x33E0A458),
                active: p == ProgressState.review,
                activeFg: AppColors.ink,
                activeBg: palette.miss,
                onPressed: canMark
                    ? () =>
                        context.read<StudyBloc>().add(const StudyMarkReview())
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MarkButton(
                label: '✓ Got it',
                fg: palette.got,
                bg: const Color(0x335FB89A),
                active: p == ProgressState.got,
                activeFg: AppColors.ink,
                activeBg: palette.got,
                onPressed: canMark
                    ? () => context.read<StudyBloc>().add(const StudyMarkGot())
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            _NavButton(
              icon: '→',
              onPressed:
                  canNav ? () => context.read<StudyBloc>().add(const StudyNext()) : null,
            ),
          ],
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});
  final String icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.muted,
        side: const BorderSide(color: AppColors.line),
        backgroundColor: AppColors.surface,
        minimumSize: const Size(58, 48),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.label,
    required this.fg,
    required this.bg,
    required this.active,
    required this.activeFg,
    required this.activeBg,
    required this.onPressed,
  });
  final String label;
  final Color fg;
  final Color bg;
  final bool active;
  final Color activeFg;
  final Color activeBg;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: active ? activeFg : fg,
        backgroundColor: active ? activeBg : bg,
        minimumSize: const Size.fromHeight(48),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}
