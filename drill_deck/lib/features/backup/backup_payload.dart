import 'dart:convert';

import 'package:drill_deck/models/app_state_snapshot.dart';
import 'package:drill_deck/models/card.dart';
import 'package:drill_deck/models/deck.dart';
import 'package:drill_deck/models/scenario.dart';

/// Builds the JSON exports the user can copy/download and consumes the
/// matching shapes on import. Wire-compatible with the static site's
/// buildExportThisDeck / buildExportEverything / doImport flow so users can
/// move data between the two implementations.
abstract final class BackupPayload {
  static String thisDeck(Deck deck, AppStateSnapshot snapshot) {
    final progress =
        snapshot.progress[deck.id]?.map((k, v) => MapEntry(k, v.id)) ?? {};
    final Map<String, Object?> body;
    if (deck is PrivateDeck) {
      body = {
        'version': 1,
        'kind': 'deck',
        'deck': deck.toJson(),
        'progress': progress,
      };
    } else {
      final overlayCards =
          (snapshot.overlayCards[deck.id] ?? const <Card>[])
              .map((c) => c.toJson())
              .toList();
      final overlayScenarios = snapshot.overlayScenarios[deck.id] ??
          const <String, Scenario>{};
      body = {
        'version': 1,
        'kind': 'overlay',
        'targetDeckId': deck.id,
        'cards': overlayCards,
        'scenarios': {
          for (final e in overlayScenarios.entries) e.key: e.value.toJson(),
        },
        'progress': progress,
      };
    }
    return const JsonEncoder.withIndent('  ').convert(body);
  }

  static String everything(AppStateSnapshot snapshot) {
    final body = {
      'version': 1,
      'kind': 'all',
      'userDecks': snapshot.userDecks.map((d) => d.toJson()).toList(),
      'overlay': {
        'cards': {
          for (final e in snapshot.overlayCards.entries)
            e.key: e.value.map((c) => c.toJson()).toList(),
        },
        'scenarios': {
          for (final e in snapshot.overlayScenarios.entries)
            e.key: {
              for (final s in e.value.entries) s.key: s.value.toJson(),
            },
        },
      },
      'progress': {
        for (final e in snapshot.progress.entries)
          e.key: {
            for (final p in e.value.entries) p.key: p.value.id,
          },
      },
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(body);
  }
}

/// Result of attempting to merge an imported payload into the local state.
class ImportResult {
  ImportResult({required this.snapshot, this.warnings = const []});
  final AppStateSnapshot snapshot;
  final List<String> warnings;
}

abstract final class BackupImport {
  /// Strips a single Markdown code fence around the payload if Claude (or
  /// any other source) left one in. Handles ```json / ``` / ~~~ variants
  /// plus surrounding whitespace.
  static String stripFences(String input) {
    var s = input.trim();
    final start =
        RegExp(r'^(?:`{3,}|~{3,})\s*(?:json|JSON)?\s*\r?\n');
    s = s.replaceFirst(start, '');
    final end = RegExp(r'\r?\n(?:`{3,}|~{3,})\s*$');
    s = s.replaceFirst(end, '');
    return s.trim();
  }

  static ImportResult merge(
    String jsonString,
    AppStateSnapshot current,
  ) {
    final cleaned = stripFences(jsonString);
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) {
      throw const FormatException('JSON must be an object');
    }
    final data = decoded.cast<String, Object?>();
    final kind = data['kind'];
    return switch (kind) {
      'deck' || 'new-deck' => _mergeDeck(data, current),
      'overlay' || 'cards-for-deck' => _mergeOverlay(data, current),
      'all' => _mergeAll(data, current),
      _ => throw FormatException('Unknown kind: $kind'),
    };
  }

  static ImportResult _mergeDeck(
    Map<String, Object?> data,
    AppStateSnapshot current,
  ) {
    final deckMap = data['deck'];
    if (deckMap is! Map) {
      throw const FormatException('deck object missing');
    }
    final ids = current.userDecks.map((d) => d.id).toSet();
    final imported = PrivateDeck.fromJson(deckMap.cast<String, Object?>());
    var id = imported.id.isEmpty ? _randomId() : imported.id;
    while (ids.contains(id)) {
      id = '$id-${_randomSuffix()}';
    }
    final fixed = imported.copyWith(id: id);
    final newDecks = [...current.userDecks, fixed];
    final newProgress = Map<String, Map<String, dynamic>>.from(current.progress)
        .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    final progressMap = data['progress'];
    if (progressMap is Map) {
      final translated = <String, dynamic>{};
      progressMap.forEach((cardId, state) {
        if (cardId is String && state is String) translated[cardId] = state;
      });
      // Will be reparsed via snapshot.fromJson on next save round-trip.
      newProgress[id] = translated;
    }
    final mergedJson = current.toJson();
    mergedJson['userDecks'] =
        newDecks.map((d) => d.toJson()).toList();
    mergedJson['progress'] = {
      ...mergedJson['progress']! as Map,
      if (progressMap is Map) id: progressMap,
    };
    return ImportResult(
      snapshot: AppStateSnapshot.fromJson(mergedJson),
    );
  }

  static ImportResult _mergeOverlay(
    Map<String, Object?> data,
    AppStateSnapshot current,
  ) {
    final targetId = data['targetDeckId'];
    if (targetId is! String) {
      throw const FormatException('targetDeckId required');
    }
    final cards = data['cards'];
    final scenarios = data['scenarios'];

    final mergedJson = current.toJson();
    final overlay = Map<String, Object?>.from(
      (mergedJson['overlay'] as Map?)?.cast<String, Object?>() ?? const {},
    );
    final overlayCards =
        Map<String, Object?>.from(
          (overlay['cards'] as Map?)?.cast<String, Object?>() ?? const {},
        );
    final overlayScn =
        Map<String, Object?>.from(
          (overlay['scenarios'] as Map?)?.cast<String, Object?>() ?? const {},
        );

    if (cards is List) {
      final existing = (overlayCards[targetId] as List?)?.toList() ?? [];
      overlayCards[targetId] = [...existing, ...cards];
    }
    if (scenarios is Map) {
      final existing =
          (overlayScn[targetId] as Map?)?.cast<String, Object?>() ??
              <String, Object?>{};
      overlayScn[targetId] = {...existing, ...scenarios};
    }

    overlay['cards'] = overlayCards;
    overlay['scenarios'] = overlayScn;
    mergedJson['overlay'] = overlay;

    final progress = data['progress'];
    if (progress is Map) {
      final progressMap =
          Map<String, Object?>.from(
        (mergedJson['progress'] as Map?)?.cast<String, Object?>() ?? const {},
      );
      final existing =
          (progressMap[targetId] as Map?)?.cast<String, Object?>() ??
              <String, Object?>{};
      progressMap[targetId] = {...existing, ...progress};
      mergedJson['progress'] = progressMap;
    }

    return ImportResult(snapshot: AppStateSnapshot.fromJson(mergedJson));
  }

  static ImportResult _mergeAll(
    Map<String, Object?> data,
    AppStateSnapshot current,
  ) {
    final out = current.toJson();
    final ids = current.userDecks.map((d) => d.id).toSet();
    final imported = data['userDecks'];
    if (imported is List) {
      final outDecks = (out['userDecks'] as List?)?.toList() ?? [];
      for (final raw in imported) {
        if (raw is! Map) continue;
        final deck = PrivateDeck.fromJson(raw.cast<String, Object?>());
        var id = deck.id.isEmpty ? _randomId() : deck.id;
        while (ids.contains(id)) {
          id = '$id-${_randomSuffix()}';
        }
        ids.add(id);
        outDecks.add(deck.copyWith(id: id).toJson());
      }
      out['userDecks'] = outDecks;
    }
    final overlayRaw = data['overlay'];
    if (overlayRaw is Map) {
      final mergedOverlay = Map<String, Object?>.from(
        (out['overlay'] as Map?)?.cast<String, Object?>() ?? const {},
      );
      final cards = Map<String, Object?>.from(
        (mergedOverlay['cards'] as Map?)?.cast<String, Object?>() ?? const {},
      );
      final scenarios = Map<String, Object?>.from(
        (mergedOverlay['scenarios'] as Map?)?.cast<String, Object?>() ??
            const {},
      );
      final inCards = overlayRaw['cards'];
      if (inCards is Map) {
        inCards.forEach((k, v) {
          if (k is String && v is List) {
            cards[k] = [...((cards[k] as List?) ?? const []), ...v];
          }
        });
      }
      final inScn = overlayRaw['scenarios'];
      if (inScn is Map) {
        inScn.forEach((k, v) {
          if (k is String && v is Map) {
            scenarios[k] = {
              ...((scenarios[k] as Map?)?.cast<String, Object?>() ??
                  const {}),
              ...v.cast<String, Object?>(),
            };
          }
        });
      }
      mergedOverlay['cards'] = cards;
      mergedOverlay['scenarios'] = scenarios;
      out['overlay'] = mergedOverlay;
    }
    final progressRaw = data['progress'];
    if (progressRaw is Map) {
      final outProgress = Map<String, Object?>.from(
        (out['progress'] as Map?)?.cast<String, Object?>() ?? const {},
      );
      progressRaw.forEach((deckId, prog) {
        if (deckId is String && prog is Map) {
          final existing =
              (outProgress[deckId] as Map?)?.cast<String, Object?>() ??
                  const {};
          outProgress[deckId] = {...existing, ...prog.cast<String, Object?>()};
        }
      });
      out['progress'] = outProgress;
    }
    return ImportResult(snapshot: AppStateSnapshot.fromJson(out));
  }
}

String _randomId() => 'imported-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
String _randomSuffix() =>
    (DateTime.now().microsecondsSinceEpoch % 36).toRadixString(36);
