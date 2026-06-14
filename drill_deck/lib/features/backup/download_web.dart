import 'package:web/web.dart' as web;

/// Triggers a browser file download by creating an anchor with a data URL.
void downloadJson(String filename, String content) {
  final encoded = Uri.encodeComponent(content);
  final href = 'data:application/json;charset=utf-8,$encoded';
  final anchor = web.HTMLAnchorElement()
    ..href = href
    ..download = filename
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
