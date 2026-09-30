import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/card_model.dart';
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

  void repeat() {
    if (_state == SessionState.waitingForRevealVoice || _state == SessionState.speakingQuestion) {
      _speakQuestion();
    } else if (_state == SessionState.waitingForRatingVoice || _state == SessionState.speakingAnswer) {
      _speakAnswer();
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
    _stopListening();
    notifyListeners();

    await _tts.speak("Question: ${card.spokenQuestion}");
  }

  Future<void> _speakAnswer() async {
    if (_isDisposed) return;
    final card = currentCard;
    if (card == null) return;

    _state = SessionState.speakingAnswer;
    _consecutiveTimeouts = 0;
    _stopListening();
    notifyListeners();

    await _tts.speak("Answer: ${card.spokenAnswer}");
  }

  void _onTtsComplete() {
    if (_state == SessionState.speakingQuestion) {
      _startListeningForReveal();
    } else if (_state == SessionState.speakingAnswer) {
      _startListeningForRating();
    }
  }

  // --- STT Actions ---

  bool _hasWord(String text, List<String> words) {
    final pattern = '\\b(${words.map(RegExp.escape).join('|')})\\b';
    return RegExp(pattern, caseSensitive: false).hasMatch(text);
  }

  Future<void> _startListeningForReveal() async {
    if (_isDisposed || _state == SessionState.paused) return;
    _state = SessionState.waitingForRevealVoice;
    _lastRecognizedText = '';
    notifyListeners();

    await _listenWithHandler((spoken) {
      if (_hasWord(spoken, ['pause', 'stop'])) {
        pause();
        return;
      }
      if (_hasWord(spoken, ['repeat', 'again'])) {
        _speakQuestion();
        return;
      }
      if (_hasWord(spoken, ['next', 'ok', 'okay', 'show', 'answer', 'weiter', 'yes'])) {
        _stopListening();
        _speakAnswer();
      }
    });
  }

  Future<void> _startListeningForRating() async {
    if (_isDisposed || _state == SessionState.paused) return;
    _state = SessionState.waitingForRatingVoice;
    _lastRecognizedText = '';
    notifyListeners();

    await _listenWithHandler((spoken) {
      if (_hasWord(spoken, ['pause', 'stop'])) {
        pause();
        return;
      }
      if (_hasWord(spoken, ['repeat'])) {
        _speakAnswer();
        return;
      }

      if (_hasWord(spoken, ['simple', 'easy', 'einfach', 'good', 'gut'])) {
        _stopListening();
        _applyRatingAndProceed(ReviewRating.simple);
      } else if (_hasWord(spoken, ['medium', 'mittel', 'normal', 'fine'])) {
        _stopListening();
        _applyRatingAndProceed(ReviewRating.medium);
      } else if (_hasWord(spoken, ['hard', 'schwer', 'difficult', 'again', 'nochmal'])) {
        _stopListening();
        _applyRatingAndProceed(ReviewRating.hard);
      }
    });
  }

  Future<void> _listenWithHandler(Function(String) onResult) async {
    if (!_speechInitialized) {
      debugPrint("Speech recognition not available");
      return;
    }

    _stopListening();

    try {
      _isListening = true;
      notifyListeners();

      await _stt.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;
          notifyListeners();
          onResult(result.recognizedWords);
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

  void _stopListening() {
    _listenTimeoutTimer?.cancel();
    if (_stt.isListening) {
      _stt.stop();
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
