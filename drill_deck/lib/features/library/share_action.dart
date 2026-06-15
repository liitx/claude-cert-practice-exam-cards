import 'package:drill_deck/features/library/share_payload.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/theme/app_colors.dart';
import 'package:drill_deck/theme/mono_typography.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Click handler for "share to library". Opens the prefilled GitHub issue
/// URL in a new tab. If the deck is too large for the URL, shows a sheet that
/// walks the user through copy-then-paste instead of silently opening an empty
/// form.
Future<void> shareDeckToLibrary(
  BuildContext context,
  Deck deck,
) async {
  final payload = SharePayload.forDeck(deck);

  if (payload.clipboardFallback) {
    await _ShareFallbackSheet.show(context, payload);
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (!await launchUrl(
    payload.uri,
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: '_blank',
  )) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Could not open the share URL.')),
    );
  }
}

/// Shown when the deck JSON is too long to prefill the GitHub issue URL.
/// Lets the user copy the JSON and open the (empty) issue form, with the
/// paste step spelled out so the empty form doesn't read as broken.
class _ShareFallbackSheet extends StatefulWidget {
  const _ShareFallbackSheet({required this.payload});
  final SharePayload payload;

  static Future<void> show(BuildContext context, SharePayload payload) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => _ShareFallbackSheet(payload: payload),
    );
  }

  @override
  State<_ShareFallbackSheet> createState() => _ShareFallbackSheetState();
}

class _ShareFallbackSheetState extends State<_ShareFallbackSheet> {
  String? _note;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.payload.body));
    setState(() => _note = 'Copied. Now open the issue and paste into the body.');
  }

  Future<void> _openIssue() async {
    final ok = await launchUrl(
      widget.payload.uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!ok && mounted) {
      setState(() => _note = 'Could not open the issue URL.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.extension<MonoTypography>()!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share to library', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'This deck is too big for a one-click prefill, so the issue form '
              'opens empty. Copy the JSON and paste it into the body:',
              style: mono.hint,
            ),
            const SizedBox(height: 14),
            Text('1. Copy JSON', style: mono.hint),
            Text('2. Open the GitHub issue', style: mono.hint),
            Text('3. Paste into the body, then Create', style: mono.hint),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _copy,
                    child: const Text('Copy JSON'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openIssue,
                    child: const Text('Open GitHub issue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }
}
