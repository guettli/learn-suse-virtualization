import 'package:flutter_test/flutter_test.dart';
import 'package:handsfree_anki/models/card_model.dart';
import 'package:handsfree_anki/services/srs_service.dart';

void main() {
  group('SrsService (SuperMemo-2 Algorithm Tests)', () {
    test('Initial card marked simple advances interval to 1 day and increases ease factor', () {
      final initial = CardProgress(cardId: 'card-1', deckSlug: 'test');
      expect(initial.repetitions, 0);
      expect(initial.easeFactor, 2.5);

      final next = SrsService.calculateNextReview(progress: initial, rating: ReviewRating.simple);
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1);
      expect(next.easeFactor, closeTo(2.6, 0.01)); // 2.5 + 0.1
    });

    test('Second consecutive successful review advances interval to 6 days', () {
      final step1 = CardProgress(
        cardId: 'card-1',
        deckSlug: 'test',
        repetitions: 1,
        intervalDays: 1,
        easeFactor: 2.6,
      );

      final next = SrsService.calculateNextReview(progress: step1, rating: ReviewRating.medium);
      expect(next.repetitions, 2);
      expect(next.intervalDays, 6);
      expect(next.easeFactor, closeTo(2.6, 0.01)); // Medium preserves EF
    });

    test('Third consecutive successful review multiplies interval by ease factor', () {
      final step2 = CardProgress(
        cardId: 'card-1',
        deckSlug: 'test',
        repetitions: 2,
        intervalDays: 6,
        easeFactor: 2.5,
      );

      final next = SrsService.calculateNextReview(progress: step2, rating: ReviewRating.simple);
      expect(next.repetitions, 3);
      // 6 * 2.5 = 15
      expect(next.intervalDays, 15);
      expect(next.easeFactor, closeTo(2.6, 0.01));
    });

    test('Hard rating resets repetitions to 0 and interval to 1 day', () {
      final advanced = CardProgress(
        cardId: 'card-1',
        deckSlug: 'test',
        repetitions: 4,
        intervalDays: 30,
        easeFactor: 2.5,
      );

      final next = SrsService.calculateNextReview(progress: advanced, rating: ReviewRating.hard);
      expect(next.repetitions, 0);
      expect(next.intervalDays, 1);
      expect(next.easeFactor, lessThan(2.5));
    });

    test('Ease factor never drops below 1.3', () {
      var progress = CardProgress(
        cardId: 'card-1',
        deckSlug: 'test',
        easeFactor: 1.35,
      );

      // Repeat hard multiple times
      for (var i = 0; i < 5; i++) {
        progress = SrsService.calculateNextReview(progress: progress, rating: ReviewRating.hard);
      }

      expect(progress.easeFactor, 1.3);
    });
  });
}
