import 'package:flutter_test/flutter_test.dart';
import 'package:handsfree_anki/services/study_session_controller.dart';

void main() {
  group('StudySessionController - Voice Keyword Matching', () {
    test('matches "repeat" and common variations accurately', () {
      expect(StudySessionController.hasWord('repeat', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('Repeat', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('REPEAT', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('can you repeat please', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('please repeat that', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('again', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('replay', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('wiederholen', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('nochmal', StudySessionController.repeatKeywords), isTrue);
      expect(StudySessionController.hasWord('noch mal', StudySessionController.repeatKeywords), isTrue);
    });

    test('does not match repeat on unrelated words', () {
      expect(StudySessionController.hasWord('unrepeated', StudySessionController.repeatKeywords), isFalse);
      expect(StudySessionController.hasWord('next', StudySessionController.repeatKeywords), isFalse);
      expect(StudySessionController.hasWord('simple', StudySessionController.repeatKeywords), isFalse);
      expect(StudySessionController.hasWord('hard', StudySessionController.repeatKeywords), isFalse);
    });

    test('repeat does not trigger hard rating', () {
      expect(StudySessionController.hasWord('repeat', StudySessionController.ratingHardKeywords), isFalse);
      expect(StudySessionController.hasWord('again', StudySessionController.ratingHardKeywords), isFalse);
      expect(StudySessionController.hasWord('nochmal', StudySessionController.ratingHardKeywords), isFalse);
      expect(StudySessionController.hasWord('wiederholen', StudySessionController.ratingHardKeywords), isFalse);
    });

    test('hard rating keywords match correctly', () {
      expect(StudySessionController.hasWord('hard', StudySessionController.ratingHardKeywords), isTrue);
      expect(StudySessionController.hasWord('schwer', StudySessionController.ratingHardKeywords), isTrue);
      expect(StudySessionController.hasWord('difficult', StudySessionController.ratingHardKeywords), isTrue);
      expect(StudySessionController.hasWord('that was hard', StudySessionController.ratingHardKeywords), isTrue);
    });

    test('reveal keywords match correctly', () {
      expect(StudySessionController.hasWord('next', StudySessionController.revealKeywords), isTrue);
      expect(StudySessionController.hasWord('ok', StudySessionController.revealKeywords), isTrue);
      expect(StudySessionController.hasWord('okay', StudySessionController.revealKeywords), isTrue);
      expect(StudySessionController.hasWord('show answer', StudySessionController.revealKeywords), isTrue);
      expect(StudySessionController.hasWord('weiter', StudySessionController.revealKeywords), isTrue);
    });

    test('specific question and answer repeat keywords match', () {
      expect(StudySessionController.hasWord('repeat question', StudySessionController.repeatQuestionKeywords), isTrue);
      expect(StudySessionController.hasWord('frage wiederholen', StudySessionController.repeatQuestionKeywords), isTrue);
      expect(StudySessionController.hasWord('repeat answer', StudySessionController.repeatAnswerKeywords), isTrue);
      expect(StudySessionController.hasWord('antwort wiederholen', StudySessionController.repeatAnswerKeywords), isTrue);
    });
  });
}
