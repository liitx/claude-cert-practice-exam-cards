import 'package:drill_deck/features/ask_claude/view/ask_claude_sheet.dart';
import 'package:drill_deck/features/backup/view/export_sheet.dart';
import 'package:drill_deck/features/backup/view/import_sheet.dart';
import 'package:drill_deck/features/library/share_action.dart';
import 'package:drill_deck/features/study/bloc/study_bloc.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The strip of small action links under the card. Mirrors the static site's
/// deck-meta row (share / export / import / ask claude). Other items
/// (reset progress, subjects, hide / delete, + card / + deck) land in
/// phases 3-4.
class DeckFooter extends StatelessWidget {
  const DeckFooter({required this.deck, super.key});
  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          _FooterLink(
            label: 'share to library',
            color: AppColors.action,
            onTap: () => shareDeckToLibrary(context, deck),
          ),
          _FooterLink(
            label: 'export',
            onTap: () => ExportSheet.show(context, deck),
          ),
          _FooterLink(
            label: 'import',
            onTap: () => ImportSheet.show(context),
          ),
          _FooterLink(
            label: 'ask claude',
            onTap: () => AskClaudeSheet.show(context, deck),
          ),
          _FooterLink(
            label: 'reset progress',
            onTap: () => _confirmReset(context, deck),
          ),
          _FooterLink(
            label: 'subjects (phase 4)',
            disabled: true,
            mono: mono,
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmReset(BuildContext context, Deck deck) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Reset progress?'),
      content: Text(
        'Clears all Review and Got-it marks for "${deck.name}". '
        'Decks and cards stay where they are.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.miss,
            foregroundColor: AppColors.ink,
          ),
          child: const Text('Reset'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    context.read<StudyBloc>().add(const StudyResetProgress());
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    this.onTap,
    this.color,
    this.disabled = false,
    this.mono,
  });
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool disabled;
  final MonoTypography? mono;

  @override
  Widget build(BuildContext context) {
    final style = (mono ?? Theme.of(context).extension<MonoTypography>()!).hint
        .copyWith(
      color: disabled
          ? AppColors.faint
          : (color ?? AppColors.muted),
      decoration:
          disabled ? TextDecoration.none : TextDecoration.underline,
      decorationColor: color ?? AppColors.muted,
    );
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(label, style: style),
      ),
    );
  }
}
