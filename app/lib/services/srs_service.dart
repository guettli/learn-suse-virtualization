import 'dart:math';
import '../models/card_model.dart';

/// Implements SuperMemo-2 (SM-2) spaced repetition algorithm.
class SrsService {
  /// Updates [progress] based on the user's [rating].
  static CardProgress calculateNextReview({
    required CardProgress progress,
    required ReviewRating rating,
  }) {
    final now = DateTime.now();
    int q;
    switch (rating) {
      case ReviewRating.hard:
        q = 2; // Below pass threshold (3)
        break;
      case ReviewRating.medium:
        q = 4; // Good recall
        break;
      case ReviewRating.simple:
        q = 5; // Perfect recall
        break;
    }

    int nextRepetitions = progress.repetitions;
    int nextInterval = progress.intervalDays;
    double nextEase = progress.easeFactor;

    if (q < 3) {
      // Failed recall: reset repetitions and schedule for tomorrow
      nextRepetitions = 0;
      nextInterval = 1;
    } else {
      // Successful recall
      if (nextRepetitions == 0) {
        nextInterval = 1;
      } else if (nextRepetitions == 1) {
        nextInterval = 6;
      } else {
        nextInterval = (nextInterval * nextEase).round();
      }
      nextRepetitions += 1;
    }

    // Update ease factor: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final double easeDiff = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
    nextEase = max(1.3, nextEase + easeDiff);

    final nextDueDate = now.add(Duration(days: nextInterval));

    return CardProgress(
      cardId: progress.cardId,
      deckSlug: progress.deckSlug,
      repetitions: nextRepetitions,
      intervalDays: nextInterval,
      easeFactor: nextEase,
      dueDate: nextDueDate,
      lastReviewedAt: now,
    );
  }
}
