import 'package:drill_deck/app_bloc/app_bloc.dart';
import 'package:drill_deck/features/backup/backup_payload.dart';
import 'package:drill_deck/features/backup/download_web.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExportSheet extends StatefulWidget {
  const ExportSheet({required this.deck, super.key});
  final Deck deck;

  static Future<void> show(BuildContext context, Deck deck) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => ExportSheet(deck: deck),
    );
  }

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  String? _note;

  void _setNote(String text) {
    setState(() => _note = text);
  }

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return SafeArea(
      top: false,
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          final snapshot = state.snapshot;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                _Section(
                  label: 'this deck',
                  description: 'Just ${widget.deck.name} and your progress on it.',
                  copyLabel: 'Copy JSON',
                  downloadLabel: 'Download .json',
                  onCopy: snapshot == null
                      ? null
                      : () => _copy(
                            BackupPayload.thisDeck(widget.deck, snapshot),
                          ),
                  onDownload: snapshot == null
                      ? null
                      : () => _download(
                            'this-deck',
                            BackupPayload.thisDeck(widget.deck, snapshot),
                          ),
                ),
                const SizedBox(height: 18),
                _Section(
                  label: 'everything you\'ve made',
                  description: 'All private decks, overlays, and progress.',
                  copyLabel: 'Copy JSON',
                  downloadLabel: 'Download .json',
                  onCopy: snapshot == null
                      ? null
                      : () => _copy(BackupPayload.everything(snapshot)),
                  onDownload: snapshot == null
                      ? null
                      : () => _download(
                            'drill-deck-all',
                            BackupPayload.everything(snapshot),
                          ),
                ),
                const SizedBox(height: 18),
                Text(
                  _note ?? ' ',
                  style: mono.hint.copyWith(color: AppColors.got),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _copy(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    _setNote('Copied to clipboard.');
  }

  void _download(String prefix, String content) {
    final stamp = DateTime.now().toIso8601String().split('T').first;
    downloadJson('$prefix-$stamp.json', content);
    _setNote('Download started.');
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.description,
    required this.copyLabel,
    required this.downloadLabel,
    required this.onCopy,
    required this.onDownload,
  });
  final String label;
  final String description;
  final String copyLabel;
  final String downloadLabel;
  final VoidCallback? onCopy;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<MonoTypography>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: mono.chip.copyWith(letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(description, style: mono.hint),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: onCopy, child: Text(copyLabel)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: onDownload,
                child: Text(downloadLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
