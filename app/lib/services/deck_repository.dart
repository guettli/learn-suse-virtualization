import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import 'storage_service.dart';

class DeckRepository {
  static Map<String, Deck>? _cachedDecks;

  /// Loads all decks from the bundled JSON asset.
  static Future<Map<String, Deck>> loadDecks() async {
    if (_cachedDecks != null) {
      return _cachedDecks!;
    }

    final rawJson = await rootBundle.loadString('assets/cards.json');
    final Map<String, dynamic> data = json.decode(rawJson);
    final Map<String, dynamic> decksMap = data['decks'] as Map<String, dynamic>;

    final result = <String, Deck>{};
    for (final entry in decksMap.entries) {
      result[entry.key] = Deck.fromJson(entry.value as Map<String, dynamic>);
    }

    _cachedDecks = result;
    return result;
  }

  /// Returns cards that are due for study today, up to [maxNewCards] new cards.
  static Future<List<FlashCard>> getDueCards({
    required Deck deck,
    int maxNewCards = 20,
  }) async {
    final progressMap = await StorageService.loadProgress(deck.slug);
    final dueCards = <FlashCard>[];
    final newCards = <FlashCard>[];

    for (final card in deck.cards) {
      final progress = progressMap[card.id];
      if (progress == null || progress.isNew) {
        newCards.add(card);
      } else if (progress.isDue) {
        dueCards.add(card);
      }
    }

    // Combine due review cards first, then append limited new cards
    final result = <FlashCard>[...dueCards];
    result.addAll(newCards.take(maxNewCards));

    // If no due cards are strictly scheduled, offer all cards so user can always study!
    if (result.isEmpty) {
      return List<FlashCard>.from(deck.cards)..shuffle();
    }

    return result;
  }

  /// Calculates statistics for a deck.
  static Future<DeckStats> getDeckStats(Deck deck) async {
    final progressMap = await StorageService.loadProgress(deck.slug);
    int due = 0;
    int learning = 0;
    int mastered = 0;
    int newCards = 0;

    for (final card in deck.cards) {
      final progress = progressMap[card.id];
      if (progress == null || progress.isNew) {
        newCards++;
      } else if (progress.repetitions >= 3) {
        mastered++;
        if (progress.isDue) due++;
      } else {
        learning++;
        if (progress.isDue) due++;
      }
    }

    return DeckStats(
      total: deck.totalCards,
      due: due,
      learning: learning,
      mastered: mastered,
      newCards: newCards,
    );
  }
}

class DeckStats {
  final int total;
  final int due;
  final int learning;
  final int mastered;
  final int newCards;

  const DeckStats({
    required this.total,
    required this.due,
    required this.learning,
    required this.mastered,
    required this.newCards,
  });
}
