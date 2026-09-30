enum ReviewRating {
  hard,   // Failed or difficult recall (quality = 1 or 2)
  medium, // Correct with hesitation / moderate effort (quality = 3 or 4)
  simple, // Perfect, easy recall (quality = 5)
}

class FlashCard {
  final String id;
  final String deckSlug;
  final String tag;
  final String question;
  final String answer;
  final String spokenQuestion;
  final String spokenAnswer;

  const FlashCard({
    required this.id,
    required this.deckSlug,
    required this.tag,
    required this.question,
    required this.answer,
    required this.spokenQuestion,
    required this.spokenAnswer,
  });

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      id: json['id'] as String,
      deckSlug: json['deck_slug'] as String,
      tag: json['tag'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      spokenQuestion: json['spoken_question'] as String,
      spokenAnswer: json['spoken_answer'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deck_slug': deckSlug,
    'tag': tag,
    'question': question,
    'answer': answer,
    'spoken_question': spokenQuestion,
    'spoken_answer': spokenAnswer,
  };
}

class CardProgress {
  final String cardId;
  final String deckSlug;
  int repetitions;
  int intervalDays;
  double easeFactor;
  DateTime dueDate;
  DateTime? lastReviewedAt;

  CardProgress({
    required this.cardId,
    required this.deckSlug,
    this.repetitions = 0,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    DateTime? dueDate,
    this.lastReviewedAt,
  }) : dueDate = dueDate ?? DateTime.now();

  bool get isDue => DateTime.now().isAfter(dueDate);
  bool get isNew => repetitions == 0 && lastReviewedAt == null;

  factory CardProgress.fromJson(Map<String, dynamic> json) {
    return CardProgress(
      cardId: json['cardId'] as String,
      deckSlug: json['deckSlug'] as String? ?? '',
      repetitions: json['repetitions'] as int? ?? 0,
      intervalDays: json['intervalDays'] as int? ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : DateTime.now(),
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'deckSlug': deckSlug,
    'repetitions': repetitions,
    'intervalDays': intervalDays,
    'easeFactor': easeFactor,
    'dueDate': dueDate.toIso8601String(),
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
  };
}

class Deck {
  final String slug;
  final String name;
  final String description;
  final int totalCards;
  final List<FlashCard> cards;

  const Deck({
    required this.slug,
    required this.name,
    required this.description,
    required this.totalCards,
    required this.cards,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    final cardList = (json['cards'] as List<dynamic>?)
            ?.map((c) => FlashCard.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];
    return Deck(
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      totalCards: json['total_cards'] as int? ?? cardList.length,
      cards: cardList,
    );
  }
}
