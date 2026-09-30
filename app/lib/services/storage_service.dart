import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';

/// Persists review progress and settings locally.
class StorageService {
  static const String _progressKeyPrefix = 'card_progress_';

  /// Saves progress for a list of cards in a deck.
  static Future<void> saveProgress(String deckSlug, Map<String, CardProgress> progressMap) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = progressMap.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString('$_progressKeyPrefix$deckSlug', json.encode(jsonMap));
  }

  /// Loads all stored progress for a given deck.
  static Future<Map<String, CardProgress>> loadProgress(String deckSlug) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_progressKeyPrefix$deckSlug');
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(
            key,
            CardProgress.fromJson(value as Map<String, dynamic>),
          ));
    } catch (_) {
      return {};
    }
  }

  /// Reset progress for a deck (useful for starting over).
  static Future<void> resetDeckProgress(String deckSlug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_progressKeyPrefix$deckSlug');
  }
}
