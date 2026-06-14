import 'package:flutter/material.dart';

/// Renders a string that may contain `<code>...</code>` spans and the common
/// HTML entities (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`).
///
/// The original card content was authored as HTML for the static site. This
/// widget reproduces the inline-code styling (monospace, slight tint, rounded
/// background) without pulling in a full HTML rendering package.
class InlineHtmlText extends StatelessWidget {
  const InlineHtmlText(
    this.text, {
    required this.baseStyle,
    super.key,
  });

  final String text;
  final TextStyle baseStyle;

  static const _codePattern = r'<code>([\s\S]*?)<\/code>';
  static final _re = RegExp(_codePattern);

  static String _decodeEntities(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var idx = 0;
    for (final m in _re.allMatches(text)) {
      if (m.start > idx) {
        spans.add(TextSpan(text: _decodeEntities(text.substring(idx, m.start))));
      }
      spans.add(_codeSpan(_decodeEntities(m.group(1) ?? '')));
      idx = m.end;
    }
    if (idx < text.length) {
      spans.add(TextSpan(text: _decodeEntities(text.substring(idx))));
    }
    return Text.rich(
      TextSpan(children: spans, style: baseStyle),
      style: baseStyle,
    );
  }

  WidgetSpan _codeSpan(String code) {
    final size = (baseStyle.fontSize ?? 14) * 0.88;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1014),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          code,
          style: baseStyle.copyWith(
            fontSize: size,
            color: const Color(0xFFC7CAD6),
            fontFamilyFallback: const ['SF Mono', 'Menlo', 'Consolas'],
            letterSpacing: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
