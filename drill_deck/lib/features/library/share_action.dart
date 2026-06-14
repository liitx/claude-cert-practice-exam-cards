import 'package:drill_deck/features/library/share_payload.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Click handler for "share to library". Opens the prefilled GitHub issue
/// URL in a new tab. If the URL is too long, copies the body to the
/// clipboard and shows a hint via [SnackBar] before opening the empty form.
Future<void> shareDeckToLibrary(
  BuildContext context,
  Deck deck,
) async {
  final payload = SharePayload.forDeck(deck);
  final messenger = ScaffoldMessenger.maybeOf(context);

  if (payload.clipboardFallback) {
    await Clipboard.setData(ClipboardData(text: payload.body));
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Deck too large for the URL — JSON copied. Paste into the issue body.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

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
