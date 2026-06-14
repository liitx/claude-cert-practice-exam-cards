import 'package:drill_deck/models/deck.dart';

enum PromptCardType { basic, mc, ms, tf, fib }

enum PromptTarget { newDeck, currentDeck }

class ClaudePromptInput {
  ClaudePromptInput({
    required this.topic,
    required this.count,
    required this.type,
    required this.target,
    this.deck,
  });

  final String topic;
  final int count;
  final PromptCardType type;
  final PromptTarget target;
  final Deck? deck;

  ClaudePromptInput copyWith({
    String? topic,
    int? count,
    PromptCardType? type,
    PromptTarget? target,
    Deck? deck,
  }) {
    return ClaudePromptInput(
      topic: topic ?? this.topic,
      count: count ?? this.count,
      type: type ?? this.type,
      target: target ?? this.target,
      deck: deck ?? this.deck,
    );
  }
}

abstract final class ClaudePrompt {
  static String build(ClaudePromptInput input) {
    final topic = input.topic.trim().isEmpty ? 'YOUR_TOPIC' : input.topic.trim();
    final n = input.count.clamp(1, 50);
    final tId = _typeId(input.type);
    final schema = StringBuffer();
    final intro = StringBuffer();
    var subjectsHint = '';

    final deck = input.deck;
    if (input.target == PromptTarget.currentDeck && deck != null) {
      final subjectsList = deck.scenarios.entries
          .map((e) => '  ${e.key} = ${e.value.label}')
          .join('\n');
      intro.write(
        'Generate $n flashcards about "$topic" to extend my study deck '
        '"${deck.name}". Return ONE JSON object matching the schema below. '
        'No prose outside the JSON.',
      );
      if (subjectsList.isNotEmpty) {
        subjectsHint =
            'Use ONLY these existing subject keys for the "scn" field. '
            'Do not invent new keys.\n$subjectsList\n\n';
      }
      final firstKey = deck.scenarios.keys.isNotEmpty
          ? deck.scenarios.keys.first
          : 'KEY';
      schema
        ..writeln('{')
        ..writeln('  "kind": "cards-for-deck",')
        ..writeln('  "targetDeckId": "${deck.id}",')
        ..writeln('  "cards": [')
        ..writeln('    ${_example(input.type, firstKey)}')
        ..writeln('  ]')
        ..write('}');
    } else {
      intro.write(
        'Generate $n flashcards about "$topic" for a study app. '
        'Return ONE JSON object matching the schema below. No prose outside the JSON.',
      );
      schema
        ..writeln('{')
        ..writeln('  "kind": "deck",')
        ..writeln('  "deck": {')
        ..writeln('    "name": "$topic",')
        ..writeln('    "scenarios": {')
        ..writeln('      "KEY1": { "label": "Subject name", "color": "#7c83ff" },')
        ..writeln('      "KEY2": { "label": "Another subject", "color": "#5fb89a" }')
        ..writeln('    },')
        ..writeln('    "cards": [')
        ..writeln('      ${_example(input.type, 'KEY1')}')
        ..writeln('    ]')
        ..writeln('  }')
        ..write('}');
    }

    return '''
${intro.toString()}

${subjectsHint}```json
${schema.toString()}
```

Card types and their fields:
- "mc"    multiple choice. fields: "choices" (2-8 strings), "correct" (integer index into choices)
- "ms"    select all that apply. fields: "choices", "correct" (array of integer indices)
- "tf"    true/false. fields: "correct" (boolean), no "choices"
- "fib"   fill in the blank. fields: "accepted" (array of accepted-answer strings)
- "basic" situation + answer. fields: "a" (correct answer text)

Use "$tId" for most cards${input.type != PromptCardType.basic ? '. Mix in other types only when genuinely better for a question.' : '.'}

Every card needs "scn", "topic", "q", "type", and the type's required fields. "why" is a short reasoning blurb and is strongly recommended.

Style:
- Questions should test reasoning or judgment, not pure recall where possible.
- Wrong choices for mc/ms should be plausible distractors, not obvious filler.
- "why" should explain the underlying principle, not restate the answer.
- Keep wording tight.

Constraints:
- Subject keys must be 1-8 alphanumeric characters.
- Colors must be #rrggbb hex.
- "correct" indices for mc/ms must be valid positions in "choices".
''';
  }

  static String _typeId(PromptCardType t) => switch (t) {
        PromptCardType.basic => 'basic',
        PromptCardType.mc => 'mc',
        PromptCardType.ms => 'ms',
        PromptCardType.tf => 'tf',
        PromptCardType.fib => 'fib',
      };

  static String _example(PromptCardType type, String key) {
    return switch (type) {
      PromptCardType.mc => '''{
        "scn": "$key",
        "topic": "Subtopic",
        "q": "Question text.",
        "type": "mc",
        "choices": ["First option", "Second option", "Third option", "Fourth option"],
        "correct": 0,
        "why": "One-sentence reasoning."
      }''',
      PromptCardType.ms => '''{
        "scn": "$key",
        "topic": "Subtopic",
        "q": "Question text.",
        "type": "ms",
        "choices": ["First", "Second", "Third", "Fourth"],
        "correct": [0, 2],
        "why": "One-sentence reasoning."
      }''',
      PromptCardType.tf => '''{
        "scn": "$key",
        "topic": "Subtopic",
        "q": "Statement that is either true or false.",
        "type": "tf",
        "correct": true,
        "why": "One-sentence reasoning."
      }''',
      PromptCardType.fib => '''{
        "scn": "$key",
        "topic": "Subtopic",
        "q": "Question with a ___ to fill in.",
        "type": "fib",
        "accepted": ["primary answer", "alternate spelling"],
        "why": "One-sentence reasoning."
      }''',
      PromptCardType.basic => '''{
        "scn": "$key",
        "topic": "Subtopic",
        "q": "Situation or question.",
        "a": "Correct answer.",
        "why": "One-sentence reasoning."
      }''',
    };
  }
}
