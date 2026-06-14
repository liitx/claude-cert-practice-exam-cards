import 'package:drill_deck/models/card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Card.fromJson', () {
    test('defaults to BasicCard when type field is missing', () {
      final card = Card.fromJson(const {
        'id': 'ci1',
        'scn': 'CI',
        'topic': 'Batch Processing',
        'q': 'question?',
        'a': 'answer.',
        'why': 'reason.',
      });
      expect(card, isA<BasicCard>());
      expect(card.type, CardType.basic);
      expect((card as BasicCard).a, 'answer.');
      expect(card.miss, isFalse);
    });

    test('parses BasicCard with miss flag and original pick', () {
      final card = Card.fromJson(const {
        'id': 'ci2',
        'scn': 'CI',
        'topic': 'Topic',
        'q': 'q',
        'a': 'a',
        'miss': true,
        'pick': 'D',
      });
      expect(card.miss, isTrue);
      expect(card.pick, 'D');
    });

    test('parses MultipleChoiceCard', () {
      final card = Card.fromJson(const {
        'id': 'mc1',
        'scn': 'CI',
        'topic': 'Topic',
        'q': 'pick one',
        'type': 'mc',
        'choices': ['A', 'B', 'C'],
        'correct': 1,
      });
      expect(card, isA<MultipleChoiceCard>());
      final mc = card as MultipleChoiceCard;
      expect(mc.choices, ['A', 'B', 'C']);
      expect(mc.correct, 1);
      expect(mc.isCorrect(1), isTrue);
      expect(mc.isCorrect(2), isFalse);
    });

    test('parses MultiSelectCard and sorts correct indices', () {
      final card = Card.fromJson(const {
        'id': 'ms1',
        'scn': 'CI',
        'topic': 'Topic',
        'q': 'pick multiple',
        'type': 'ms',
        'choices': ['A', 'B', 'C', 'D'],
        'correct': [2, 0],
      });
      final ms = card as MultiSelectCard;
      expect(ms.correct, [0, 2]);
      expect(ms.isCorrect([0, 2]), isTrue);
      expect(ms.isCorrect([2, 0]), isTrue);
      expect(ms.isCorrect([0]), isFalse);
      expect(ms.isCorrect([0, 1, 2]), isFalse);
    });

    test('parses TrueFalseCard, coerces truthy string and int', () {
      final tCard = Card.fromJson(const {
        'id': 'tf1',
        'scn': 'CI',
        'topic': 'Topic',
        'q': 'true?',
        'type': 'tf',
        'correct': true,
      });
      final tStringCard = Card.fromJson(const {
        'id': 'tf2',
        'scn': 'CI',
        'topic': 'Topic',
        'q': 'true?',
        'type': 'tf',
        'correct': 'true',
      });
      final tIntCard = Card.fromJson(const {
        'id': 'tf3',
        'scn': 'CI',
        'topic': 'Topic',
        'q': 'true?',
        'type': 'tf',
        'correct': 1,
      });
      expect((tCard as TrueFalseCard).correct, isTrue);
      expect((tStringCard as TrueFalseCard).correct, isTrue);
      expect((tIntCard as TrueFalseCard).correct, isTrue);
    });

    test('parses FillInBlankCard, case-insensitive match', () {
      final card = Card.fromJson(const {
        'id': 'fib1',
        'scn': 'CI',
        'topic': 'Topic',
        'q': 'Fill the ___',
        'type': 'fib',
        'accepted': ['blank', 'Empty'],
      });
      final fib = card as FillInBlankCard;
      expect(fib.accepted, ['blank', 'Empty']);
      expect(fib.isCorrect('Blank'), isTrue);
      expect(fib.isCorrect('  empty  '), isTrue);
      expect(fib.isCorrect('nope'), isFalse);
      expect(fib.isCorrect(''), isFalse);
    });

    test('round-trips through toJson for every type', () {
      final inputs = <Map<String, Object?>>[
        {
          'id': 'b',
          'scn': 'CI',
          'topic': 't',
          'q': 'q',
          'a': 'a',
          'why': 'w',
          'miss': false,
        },
        {
          'id': 'm',
          'scn': 'CI',
          'topic': 't',
          'q': 'q',
          'type': 'mc',
          'choices': ['x', 'y'],
          'correct': 0,
          'miss': false,
        },
        {
          'id': 's',
          'scn': 'CI',
          'topic': 't',
          'q': 'q',
          'type': 'ms',
          'choices': ['x', 'y'],
          'correct': [1],
          'miss': false,
        },
        {
          'id': 't',
          'scn': 'CI',
          'topic': 't',
          'q': 'q',
          'type': 'tf',
          'correct': true,
          'miss': false,
        },
        {
          'id': 'f',
          'scn': 'CI',
          'topic': 't',
          'q': 'q',
          'type': 'fib',
          'accepted': ['x'],
          'miss': false,
        },
      ];
      for (final input in inputs) {
        final card = Card.fromJson(input);
        final roundTripped = Card.fromJson(card.toJson());
        expect(roundTripped, card, reason: 'failed for ${input['id']}');
      }
    });
  });
}
