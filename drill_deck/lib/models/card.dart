import 'package:equatable/equatable.dart';

/// One of the five card types in the wire format.
enum CardType {
  basic('basic'),
  mc('mc'),
  ms('ms'),
  tf('tf'),
  fib('fib');

  const CardType(this.id);
  final String id;

  static CardType? tryParse(Object? raw) {
    if (raw is String) {
      for (final t in values) {
        if (t.id == raw) return t;
      }
    }
    return null;
  }
}

/// Sealed Card hierarchy. Each subclass owns its type-specific fields and
/// answer-checking logic. JSON serialization round-trips through the wire
/// format used by `decks.json` and the legacy localStorage snapshot.
sealed class Card extends Equatable {
  const Card({
    required this.id,
    required this.scn,
    required this.topic,
    required this.q,
    this.why = '',
    this.miss = false,
    this.pick,
    this.image,
    this.userOwned = false,
  });

  /// Discriminating factory. Defaults to `basic` when `type` is missing or
  /// unknown — matches the source-app behavior at `index.html:1469`.
  factory Card.fromJson(Map<String, Object?> json) {
    final type = CardType.tryParse(json['type']) ?? CardType.basic;
    return switch (type) {
      CardType.basic => BasicCard._fromJson(json),
      CardType.mc => MultipleChoiceCard._fromJson(json),
      CardType.ms => MultiSelectCard._fromJson(json),
      CardType.tf => TrueFalseCard._fromJson(json),
      CardType.fib => FillInBlankCard._fromJson(json),
    };
  }

  final String id;
  final String scn;
  final String topic;
  final String q;
  final String why;
  final bool miss;
  final String? pick;
  final String? image;

  /// Local-only flag: true if the card came from the user (private deck or
  /// overlay) rather than the shared library. Drives HTML-escaping policy at
  /// render time.
  final bool userOwned;

  CardType get type;

  /// Common JSON keys. Subclasses extend this with their type-specific fields.
  Map<String, Object?> _baseJson() {
    return {
      'id': id,
      'scn': scn,
      'topic': topic,
      'q': q,
      if (why.isNotEmpty) 'why': why,
      'miss': miss,
      if (pick != null && pick!.isNotEmpty) 'pick': pick,
      if (image != null && image!.isNotEmpty) 'image': image,
      if (type != CardType.basic) 'type': type.id,
    };
  }

  Map<String, Object?> toJson();

  @override
  List<Object?> get props => [
        id,
        scn,
        topic,
        q,
        why,
        miss,
        pick,
        image,
        type,
        userOwned,
      ];

  static String _str(Object? v) => v is String ? v : '';
  static bool _bool(Object? v) => v == true || v == 'true' || v == 1;
}

extension CardCapabilities on Card {
  // Always editable/deletable. Editing a card on a shared deck forks the deck
  // locally first, so availability is never tied to how the card was created.
  bool get canEdit => true;
  bool get canDelete => true;
}

final class BasicCard extends Card {
  const BasicCard({
    required super.id,
    required super.scn,
    required super.topic,
    required super.q,
    required this.a,
    super.why,
    super.miss,
    super.pick,
    super.image,
    super.userOwned,
  });

  factory BasicCard._fromJson(Map<String, Object?> json) => BasicCard(
        id: Card._str(json['id']),
        scn: Card._str(json['scn']),
        topic: Card._str(json['topic']),
        q: Card._str(json['q']),
        a: Card._str(json['a']),
        why: Card._str(json['why']),
        miss: Card._bool(json['miss']),
        pick: json['pick'] as String?,
        image: json['image'] as String?,
        userOwned: Card._bool(json['user']),
      );

  final String a;

  @override
  CardType get type => CardType.basic;

  @override
  Map<String, Object?> toJson() => {..._baseJson(), 'a': a};

  @override
  List<Object?> get props => [...super.props, a];
}

final class MultipleChoiceCard extends Card {
  const MultipleChoiceCard({
    required super.id,
    required super.scn,
    required super.topic,
    required super.q,
    required this.choices,
    required this.correct,
    this.explanation,
    super.why,
    super.miss,
    super.pick,
    super.image,
    super.userOwned,
  });

  factory MultipleChoiceCard._fromJson(Map<String, Object?> json) {
    final choicesRaw = json['choices'];
    final choices = choicesRaw is List
        ? choicesRaw.map((c) => Card._str(c)).toList()
        : <String>[];
    final correctRaw = json['correct'];
    final correct = correctRaw is int
        ? correctRaw
        : (correctRaw is String ? int.tryParse(correctRaw) ?? -1 : -1);
    return MultipleChoiceCard(
      id: Card._str(json['id']),
      scn: Card._str(json['scn']),
      topic: Card._str(json['topic']),
      q: Card._str(json['q']),
      choices: choices,
      correct: correct,
      explanation: json['a'] as String?,
      why: Card._str(json['why']),
      miss: Card._bool(json['miss']),
      pick: json['pick'] as String?,
      image: json['image'] as String?,
      userOwned: Card._bool(json['user']),
    );
  }

  final List<String> choices;
  final int correct;

  /// Optional explanation text shown on the back alongside the structured
  /// correct answer. Stored as `a` in the wire format.
  final String? explanation;

  @override
  CardType get type => CardType.mc;

  @override
  Map<String, Object?> toJson() => {
        ..._baseJson(),
        'choices': choices,
        'correct': correct,
        if (explanation != null && explanation!.isNotEmpty) 'a': explanation,
      };

  bool isCorrect(int pick) => pick == correct;

  @override
  List<Object?> get props => [...super.props, choices, correct, explanation];
}

final class MultiSelectCard extends Card {
  const MultiSelectCard({
    required super.id,
    required super.scn,
    required super.topic,
    required super.q,
    required this.choices,
    required this.correct,
    this.explanation,
    super.why,
    super.miss,
    super.pick,
    super.image,
    super.userOwned,
  });

  factory MultiSelectCard._fromJson(Map<String, Object?> json) {
    final choicesRaw = json['choices'];
    final choices = choicesRaw is List
        ? choicesRaw.map((c) => Card._str(c)).toList()
        : <String>[];
    final correctRaw = json['correct'];
    final correct = correctRaw is List
        ? correctRaw.whereType<int>().toList()
        : <int>[];
    correct.sort();
    return MultiSelectCard(
      id: Card._str(json['id']),
      scn: Card._str(json['scn']),
      topic: Card._str(json['topic']),
      q: Card._str(json['q']),
      choices: choices,
      correct: correct,
      explanation: json['a'] as String?,
      why: Card._str(json['why']),
      miss: Card._bool(json['miss']),
      pick: json['pick'] as String?,
      image: json['image'] as String?,
      userOwned: Card._bool(json['user']),
    );
  }

  final List<String> choices;
  final List<int> correct;
  final String? explanation;

  @override
  CardType get type => CardType.ms;

  @override
  Map<String, Object?> toJson() => {
        ..._baseJson(),
        'choices': choices,
        'correct': correct,
        if (explanation != null && explanation!.isNotEmpty) 'a': explanation,
      };

  bool isCorrect(Iterable<int> picks) {
    final sortedPicks = picks.toList()..sort();
    if (sortedPicks.length != correct.length) return false;
    for (var i = 0; i < correct.length; i++) {
      if (sortedPicks[i] != correct[i]) return false;
    }
    return true;
  }

  @override
  List<Object?> get props => [...super.props, choices, correct, explanation];
}

final class TrueFalseCard extends Card {
  const TrueFalseCard({
    required super.id,
    required super.scn,
    required super.topic,
    required super.q,
    required this.correct,
    this.explanation,
    super.why,
    super.miss,
    super.pick,
    super.image,
    super.userOwned,
  });

  factory TrueFalseCard._fromJson(Map<String, Object?> json) => TrueFalseCard(
        id: Card._str(json['id']),
        scn: Card._str(json['scn']),
        topic: Card._str(json['topic']),
        q: Card._str(json['q']),
        correct: Card._bool(json['correct']),
        explanation: json['a'] as String?,
        why: Card._str(json['why']),
        miss: Card._bool(json['miss']),
        pick: json['pick'] as String?,
        image: json['image'] as String?,
        userOwned: Card._bool(json['user']),
      );

  final bool correct;
  final String? explanation;

  @override
  CardType get type => CardType.tf;

  @override
  Map<String, Object?> toJson() => {
        ..._baseJson(),
        'correct': correct,
        if (explanation != null && explanation!.isNotEmpty) 'a': explanation,
      };

  bool isCorrect(bool pick) => pick == correct;

  @override
  List<Object?> get props => [...super.props, correct, explanation];
}

final class FillInBlankCard extends Card {
  const FillInBlankCard({
    required super.id,
    required super.scn,
    required super.topic,
    required super.q,
    required this.accepted,
    this.explanation,
    super.why,
    super.miss,
    super.pick,
    super.image,
    super.userOwned,
  });

  factory FillInBlankCard._fromJson(Map<String, Object?> json) {
    final acceptedRaw = json['accepted'];
    final accepted = acceptedRaw is List
        ? acceptedRaw.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    return FillInBlankCard(
      id: Card._str(json['id']),
      scn: Card._str(json['scn']),
      topic: Card._str(json['topic']),
      q: Card._str(json['q']),
      accepted: accepted,
      explanation: json['a'] as String?,
      why: Card._str(json['why']),
      miss: Card._bool(json['miss']),
      pick: json['pick'] as String?,
      image: json['image'] as String?,
      userOwned: Card._bool(json['user']),
    );
  }

  final List<String> accepted;
  final String? explanation;

  @override
  CardType get type => CardType.fib;

  @override
  Map<String, Object?> toJson() => {
        ..._baseJson(),
        'accepted': accepted,
        if (explanation != null && explanation!.isNotEmpty) 'a': explanation,
      };

  bool isCorrect(String input) {
    final norm = _norm(input);
    if (norm.isEmpty) return false;
    return accepted.any((a) => _norm(a) == norm);
  }

  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  @override
  List<Object?> get props => [...super.props, accepted, explanation];
}
