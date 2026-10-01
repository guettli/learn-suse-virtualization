import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/card_model.dart';
import 'audio_cue_service.dart';
import 'srs_service.dart';
import 'storage_service.dart';

enum SessionState {
  initial,
  speakingQuestion,
  waitingForRevealVoice,
  speakingAnswer,
  waitingForRatingVoice,
  paused,
  completed,
}

class StudySessionController extends ChangeNotifier {
  final Deck deck;
  final List<FlashCard> cards;
  int currentIndex = 0;

  SessionState _state = SessionState.initial;
  SessionState get state => _state;

  String _lastRecognizedText = '';
  String get lastRecognizedText => _lastRecognizedText;

  bool _isListening = false;
  bool get isListening => _isListening;

  FlashCard? get currentCard =>
      (currentIndex >= 0 && currentIndex < cards.length) ? cards[currentIndex] : null;

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _speechInitialized = false;

  Map<String, CardProgress> _progressMap = {};
  Timer? _listenTimeoutTimer;
  int _consecutiveTimeouts = 0;
  bool _isDisposed = false;

  StudySessionController({
    required this.deck,
    required this.cards,
  });

  Future<void> initialize() async {
    _progressMap = await StorageService.loadProgress(deck.slug);

    // Initialize TTS
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setCompletionHandler(() {
      if (_isDisposed) return;
      _onTtsComplete();
    });

    _tts.setErrorHandler((msg) {
      debugPrint("TTS error: $msg");
      if (_isDisposed) return;
      // In case of error, continue forward
      _onTtsComplete();
    });

    // Initialize STT
    try {
      _speechInitialized = await _stt.initialize(
        onStatus: (status) {
          debugPrint("STT Status: $status");
          if (_isDisposed) return;
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            notifyListeners();
            _onListeningStopped();
          }
        },
        onError: (errorNotification) {
          debugPrint("STT Error: ${errorNotification.errorMsg}");
          if (_isDisposed) return;
          _isListening = false;
          notifyListeners();
          _onListeningStopped();
        },
      );
    } catch (e) {
      debugPrint("Failed to initialize STT: $e");
    }

    notifyListeners();
  }

  /// Start the hands-free session
  Future<void> start() async {
    if (cards.isEmpty) {
      _state = SessionState.completed;
      notifyListeners();
      return;
    }
    currentIndex = 0;
    _speakQuestion();
  }

  void pause() {
    _state = SessionState.paused;
    _tts.stop();
    _stopListening();
    _listenTimeoutTimer?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_state == SessionState.paused) {
      _speakQuestion();
    }
  }

  Future<void> repeat() async {
    if (_isDisposed) return;
    if (_state == SessionState.paused) {
      _state = SessionState.waitingForRevealVoice;
    }

    if (_state == SessionState.waitingForRatingVoice || _state == SessionState.speakingAnswer) {
      await _speakAnswer();
    } else {
      await _speakQuestion();
    }
  }

  void manualRevealAnswer() {
    _tts.stop();
    _stopListening();
    _speakAnswer();
  }

  void manualSubmitRating(ReviewRating rating) {
    _applyRatingAndProceed(rating);
  }

  // --- TTS Actions ---

  Future<void> _speakQuestion() async {
    if (_isDisposed) return;
    final card = currentCard;
    if (card == null) return;

    _state = SessionState.speakingQuestion;
    _consecutiveTimeouts = 0;
    await _stopListening();
    await _tts.stop();
    notifyListeners();

    await _tts.speak("Question: ${card.spokenQuestion}");
  }

  Future<void> _speakAnswer() async {
    if (_isDisposed) return;
    final card = currentCard;
    if (card == null) return;

    _state = SessionState.speakingAnswer;
    _consecutiveTimeouts = 0;
    await _stopListening();
    await _tts.stop();
    notifyListeners();

    await _tts.speak("Answer: ${card.spokenAnswer}");
  }

  void _onTtsComplete() {
    if (_isDisposed || _state == SessionState.paused) return;
    if (_state == SessionState.speakingQuestion) {
      _startListeningForReveal();
    } else if (_state == SessionState.speakingAnswer) {
      _startListeningForRating();
    }
  }

  // --- STT Keywords & Actions ---

  static const List<String> repeatKeywords = [
    'repeat',
    'repeat that',
    'repeat please',
    'please repeat',
    'again',
    'once more',
    'replay',
    'wiederholen',
    'wiederhole',
    'wiederhol',
    'nochmal',
    'noch mal',
  ];

  static const List<String> repeatQuestionKeywords = [
    'repeat question',
    'question again',
    'frage wiederholen',
    'frage nochmal',
  ];

  static const List<String> repeatAnswerKeywords = [
    'repeat answer',
    'answer again',
    'antwort wiederholen',
    'antwort nochmal',
  ];

  static const List<String> revealKeywords = [
    'next',
    'ok',
    'okay',
    'show',
    'show answer',
    'answer',
    'weiter',
    'yes',
    'ja',
    'aufdecken',
  ];

  static const List<String> ratingSimpleKeywords = [
    'simple',
    'easy',
    'einfach',
    'good',
    'gut',
    'leicht',
  ];

  static const List<String> ratingMediumKeywords = [
    'medium',
    'mittel',
    'normal',
    'fine',
    'geht so',
  ];

  static const List<String> ratingHardKeywords = [
    'hard',
    'schwer',
    'difficult',
    'schwierig',
    'nicht gewusst',
    'fail',
  ];

  static const List<String> pauseKeywords = [
    'pause',
    'stop',
    'anhalten',
    'stopp',
  ];

  static bool hasWord(String text, List<String> words) {
    final lowerText = text.toLowerCase();
    for (final word in words) {
      final lowerWord = word.toLowerCase().trim();
      if (lowerWord.isEmpty) continue;
      // Match with non-alphanumeric boundaries to support English, German umlauts, and punctuation
      final escaped = RegExp.escape(lowerWord);
      final pattern = '(^|[^a-zA-Z0-9äöüßÄÖÜ])$escaped(\$|[^a-zA-Z0-9äöüßÄÖÜ])';
      if (RegExp(pattern).hasMatch(lowerText)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _startListeningForReveal() async {
    if (_isDisposed || _state == SessionState.paused) return;
    _state = SessionState.waitingForRevealVoice;
    _lastRecognizedText = '';
    notifyListeners();

    await _listenWithHandler((spoken) async {
      if (_state != SessionState.waitingForRevealVoice) return;

      if (hasWord(spoken, pauseKeywords)) {
        pause();
        return;
      }
      if (hasWord(spoken, repeatKeywords) || hasWord(spoken, repeatQuestionKeywords)) {
        await repeat();
        return;
      }
      if (hasWord(spoken, revealKeywords)) {
        await _stopListening();
        await _speakAnswer();
      }
    });
  }

  Future<void> _startListeningForRating() async {
    if (_isDisposed || _state == SessionState.paused) return;
    _state = SessionState.waitingForRatingVoice;
    _lastRecognizedText = '';
    notifyListeners();

    await _listenWithHandler((spoken) async {
      if (_state != SessionState.waitingForRatingVoice) return;

      if (hasWord(spoken, pauseKeywords)) {
        pause();
        return;
      }
      if (hasWord(spoken, repeatQuestionKeywords)) {
        await _speakQuestion();
        return;
      }
      if (hasWord(spoken, repeatKeywords) || hasWord(spoken, repeatAnswerKeywords)) {
        await repeat();
        return;
      }

      if (hasWord(spoken, ratingSimpleKeywords)) {
        await _stopListening();
        await _applyRatingAndProceed(ReviewRating.simple);
      } else if (hasWord(spoken, ratingMediumKeywords)) {
        await _stopListening();
        await _applyRatingAndProceed(ReviewRating.medium);
      } else if (hasWord(spoken, ratingHardKeywords)) {
        await _stopListening();
        await _applyRatingAndProceed(ReviewRating.hard);
      }
    });
  }

  Future<void> _listenWithHandler(Future<void> Function(String) onResult) async {
    if (!_speechInitialized) {
      debugPrint("Speech recognition not available");
      return;
    }

    await _stopListening();

    try {
      _isListening = true;
      notifyListeners();

      await AudioCueService.playListenCue();

      await _stt.listen(
        onResult: (result) async {
          _lastRecognizedText = result.recognizedWords;
          notifyListeners();
          await onResult(result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint("Error starting STT listen: $e");
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> _stopListening() async {
    _listenTimeoutTimer?.cancel();
    if (_stt.isListening) {
      await _stt.stop();
      // Brief pause to allow Android audio session to release microphone before TTS starts
      await Future.delayed(const Duration(milliseconds: 150));
    }
    _isListening = false;
  }

  bool _isProcessingRating = false;

  void _onListeningStopped() {
    if (_isDisposed || _state == SessionState.paused) return;
    if (_state != SessionState.waitingForRevealVoice && _state != SessionState.waitingForRatingVoice) return;

    _listenTimeoutTimer?.cancel();
    _listenTimeoutTimer = Timer(const Duration(milliseconds: 1200), () {
      if (_isDisposed || _state == SessionState.paused) return;
      _consecutiveTimeouts++;
      if (_state == SessionState.waitingForRevealVoice) {
        if (_consecutiveTimeouts >= 3) {
          _consecutiveTimeouts = 0;
          _tts.speak("Say next or ok").then((_) => _startListeningForReveal());
        } else {
          _startListeningForReveal();
        }
      } else if (_state == SessionState.waitingForRatingVoice) {
        if (_consecutiveTimeouts >= 3) {
          _consecutiveTimeouts = 0;
          _tts.speak("Say simple, medium, or hard").then((_) => _startListeningForRating());
        } else {
          _startListeningForRating();
        }
      }
    });
  }

  Future<void> _applyRatingAndProceed(ReviewRating rating) async {
    if (_isProcessingRating || _isDisposed) return;
    final card = currentCard;
    if (card == null) return;

    _isProcessingRating = true;
    _stopListening();

    try {
      // SM-2 calculation
      final currentProgress = _progressMap[card.id] ??
          CardProgress(
            cardId: card.id,
            deckSlug: card.deckSlug,
          );

      final updatedProgress = SrsService.calculateNextReview(
        progress: currentProgress,
        rating: rating,
      );

      _progressMap[card.id] = updatedProgress;
      await StorageService.saveProgress(deck.slug, _progressMap);

      // If marked hard, we optionally re-queue it at the end of this session for practice
      if (rating == ReviewRating.hard) {
        cards.add(card);
      }

      currentIndex++;
      if (currentIndex < cards.length) {
        // Short pause before reading next question
        await Future.delayed(const Duration(milliseconds: 800));
        if (!_isDisposed && _state != SessionState.paused) {
          _speakQuestion();
        }
      } else {
        _state = SessionState.completed;
        notifyListeners();
        await _tts.speak("Study session completed. Well done!");
      }
    } finally {
      _isProcessingRating = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _listenTimeoutTimer?.cancel();
    _tts.stop();
    _stopListening();
    super.dispose();
  }
}
