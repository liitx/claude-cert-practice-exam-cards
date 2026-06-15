import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/scenario.dart';
import 'package:equatable/equatable.dart';

/// Sealed deck hierarchy. Shared decks come from `decks.json` and are
/// read-only client-side. Private decks live in localStorage / SharedPreferences
/// and the user can edit them. The `DeckCapabilities` extension lets the UI
/// iterate over what's allowed instead of branching on `d.builtin`.
sealed class Deck extends Equatable {
  const Deck({
    required this.id,
    required this.name,
    required this.scenarios,
    required this.cards,
  });

  final String id;
  final String name;
  final Map<String, Scenario> scenarios;
  final List<Card> cards;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'scenarios': {
          for (final entry in scenarios.entries) entry.key: entry.value.toJson(),
        },
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, name, scenarios, cards];
}

final class SharedDeck extends Deck {
  const SharedDeck({
    required super.id,
    required super.name,
    required super.scenarios,
    required super.cards,
  });

  factory SharedDeck.fromJson(Map<String, Object?> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    return SharedDeck(
      id: id,
      name: name,
      scenarios: _readScenarios(json['scenarios']),
      cards: _readCards(json['cards']),
    );
  }
}

final class PrivateDeck extends Deck {
  const PrivateDeck({
    required super.id,
    required super.name,
    required super.scenarios,
    required super.cards,
    this.hidden = false,
  });

  factory PrivateDeck.fromJson(Map<String, Object?> json) => PrivateDeck(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        scenarios: _readScenarios(json['scenarios']),
        cards: _readCards(json['cards']).map(_markUser).toList(),
        hidden: json['hidden'] == true,
      );

  /// Clones any deck into a private, locally-editable copy. Used for
  /// fork-on-write: the first edit of a shared "lib" deck produces a "mine"
  /// copy that shadows it. Cards are marked user-owned.
  factory PrivateDeck.fork(Deck source) => PrivateDeck(
        id: source.id,
        name: source.name,
        scenarios: Map.of(source.scenarios),
        cards: source.cards.map(_markUser).toList(),
      );

  final bool hidden;

  PrivateDeck copyWith({
    String? id,
    String? name,
    Map<String, Scenario>? scenarios,
    List<Card>? cards,
    bool? hidden,
  }) {
    return PrivateDeck(
      id: id ?? this.id,
      name: name ?? this.name,
      scenarios: scenarios ?? this.scenarios,
      cards: cards ?? this.cards,
      hidden: hidden ?? this.hidden,
    );
  }

  @override
  List<Object?> get props => [...super.props, hidden];
}

extension DeckCapabilities on Deck {
  // All decks are editable/deletable: edits to a shared deck fork it into a
  // local copy (see [PrivateDeck.fork]), so capability is never frozen at
  // creation. `canHide`/`isBuiltin` still distinguish the shared origin.
  bool get canDelete => true;
  bool get canEdit => true;
  bool get canShare => true;
  bool get canHide => this is SharedDeck;
  bool get isBuiltin => this is SharedDeck;
}

Map<String, Scenario> _readScenarios(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, Scenario>{};
  raw.forEach((key, value) {
    if (key is String && value is Map) {
      out[key] = Scenario.fromJson(value.cast<String, Object?>());
    }
  });
  return out;
}

List<Card> _readCards(Object? raw) {
  if (raw is! List) return const [];
  final out = <Card>[];
  for (final c in raw) {
    if (c is Map) {
      try {
        out.add(Card.fromJson(c.cast<String, Object?>()));
      } catch (_) {
        // Skip malformed cards instead of failing the whole deck.
      }
    }
  }
  return out;
}

Card _markUser(Card c) {
  if (c.userOwned) return c;
  return switch (c) {
    BasicCard() => BasicCard(
        id: c.id,
        scn: c.scn,
        topic: c.topic,
        q: c.q,
        a: c.a,
        why: c.why,
        miss: c.miss,
        pick: c.pick,
        image: c.image,
        userOwned: true,
      ),
    MultipleChoiceCard() => MultipleChoiceCard(
        id: c.id,
        scn: c.scn,
        topic: c.topic,
        q: c.q,
        choices: c.choices,
        correct: c.correct,
        explanation: c.explanation,
        why: c.why,
        miss: c.miss,
        pick: c.pick,
        image: c.image,
        userOwned: true,
      ),
    MultiSelectCard() => MultiSelectCard(
        id: c.id,
        scn: c.scn,
        topic: c.topic,
        q: c.q,
        choices: c.choices,
        correct: c.correct,
        explanation: c.explanation,
        why: c.why,
        miss: c.miss,
        pick: c.pick,
        image: c.image,
        userOwned: true,
      ),
    TrueFalseCard() => TrueFalseCard(
        id: c.id,
        scn: c.scn,
        topic: c.topic,
        q: c.q,
        correct: c.correct,
        explanation: c.explanation,
        why: c.why,
        miss: c.miss,
        pick: c.pick,
        image: c.image,
        userOwned: true,
      ),
    FillInBlankCard() => FillInBlankCard(
        id: c.id,
        scn: c.scn,
        topic: c.topic,
        q: c.q,
        accepted: c.accepted,
        explanation: c.explanation,
        why: c.why,
        miss: c.miss,
        pick: c.pick,
        image: c.image,
        userOwned: true,
      ),
  };
}
