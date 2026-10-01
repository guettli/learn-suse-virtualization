import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/card_model.dart';
import '../services/foreground_service.dart';
import '../services/headset_service.dart';
import '../services/study_session_controller.dart';

class StudyScreen extends StatefulWidget {
  final Deck deck;
  final List<FlashCard> cards;

  const StudyScreen({
    super.key,
    required this.deck,
    required this.cards,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late final StudySessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudySessionController(
      deck: widget.deck,
      cards: List.from(widget.cards),
    );

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    HeadsetService.initialize(onAction: _handleHeadsetAction);
    HeadsetService.startSession();

    _startSession();
  }

  void _handleHeadsetAction(HeadsetAction action) {
    if (!mounted) return;
    if (_controller.state == SessionState.completed ||
        _controller.state == SessionState.initial) {
      return;
    }
    switch (action) {
      case HeadsetAction.playPause:
        if (_controller.state == SessionState.waitingForRevealVoice) {
          _controller.manualRevealAnswer();
        } else if (_controller.state == SessionState.waitingForRatingVoice) {
          _controller.repeat();
        } else if (_controller.state == SessionState.paused) {
          _controller.resume();
        } else {
          _controller.pause();
        }
        break;
      case HeadsetAction.next:
        if (_controller.state == SessionState.waitingForRevealVoice) {
          _controller.manualRevealAnswer();
        } else if (_controller.state == SessionState.waitingForRatingVoice) {
          _controller.manualSubmitRating(ReviewRating.simple);
        }
        break;
      case HeadsetAction.previous:
        _controller.repeat();
        break;
    }
  }

  Future<void> _startSession() async {
    try {
      // 1. Request microphone permission for voice commands
      final micStatus = await Permission.microphone.request();

      // 2. Request notification permission (needed on Android 13+)
      if (await Permission.notification.status.isDenied) {
        await Permission.notification.request();
      }

      if (!mounted) return;

      // 3. Start Android foreground service to allow continuous listening with screen off
      if (micStatus.isGranted) {
        await ForegroundServiceManager.startSessionService(deckName: widget.deck.name);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission not granted. Use on-screen buttons to study.'),
            duration: Duration(seconds: 4),
          ),
        );
      }

      if (!mounted) return;

      // 4. Initialize speech controller (TTS & STT)
      await _controller.initialize();

      if (!mounted) return;

      // 5. Start speaking the first question
      await _controller.start();
    } catch (e, stack) {
      debugPrint("Error in _startSession: $e\n$stack");
    }
  }

  @override
  void dispose() {
    HeadsetService.dispose();
    ForegroundServiceManager.stopSessionService();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = _controller.currentCard;

    if (_controller.state == SessionState.completed || card == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deck.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                const SizedBox(height: 20),
                Text(
                  'Session Completed!',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Great job! All scheduled cards in this round have been reviewed.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Decks'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAnswerRevealed = _controller.state == SessionState.speakingAnswer ||
        _controller.state == SessionState.waitingForRatingVoice;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.deck.name} (${_controller.currentIndex + 1}/${_controller.cards.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Repeat audio',
            onPressed: () => _controller.repeat(),
          ),
          IconButton(
            icon: Icon(_controller.state == SessionState.paused ? Icons.play_arrow : Icons.pause),
            tooltip: _controller.state == SessionState.paused ? 'Resume' : 'Pause',
            onPressed: () {
              if (_controller.state == SessionState.paused) {
                _controller.resume();
              } else {
                _controller.pause();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Voice status indicator bar
            _buildVoiceStatusBar(theme),

            // Card content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tag chip
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(card.tag),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Question Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUESTION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card.question,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Answer Card (revealed or hidden)
                    if (isAnswerRevealed)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ANSWER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              MarkdownBody(
                                data: card.answer,
                                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                                  p: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.mic, size: 36, color: theme.colorScheme.primary),
                              const SizedBox(height: 12),
                              Text(
                                'Say "OK" or "NEXT" to reveal answer',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom manual action controls
            _buildBottomControls(theme, isAnswerRevealed),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceStatusBar(ThemeData theme) {
    String statusTitle = '';
    String statusSubtitle = '';
    Color statusColor = Colors.blue;
    IconData statusIcon = Icons.record_voice_over;

    switch (_controller.state) {
      case SessionState.speakingQuestion:
        statusTitle = 'Speaking Question...';
        statusSubtitle = 'Listen carefully';
        statusColor = Colors.blue;
        statusIcon = Icons.volume_up;
        break;
      case SessionState.waitingForRevealVoice:
        statusTitle = 'Listening for "OK" or "NEXT"...';
        statusSubtitle = _controller.lastRecognizedText.isNotEmpty
            ? 'Heard: "${_controller.lastRecognizedText}"'
            : 'Waiting for your command';
        statusColor = Colors.deepOrange;
        statusIcon = Icons.mic;
        break;
      case SessionState.speakingAnswer:
        statusTitle = 'Speaking Answer...';
        statusSubtitle = 'Answer revealed';
        statusColor = Colors.teal;
        statusIcon = Icons.volume_up;
        break;
      case SessionState.waitingForRatingVoice:
        statusTitle = 'Listening for Rating...';
        statusSubtitle = _controller.lastRecognizedText.isNotEmpty
            ? 'Heard: "${_controller.lastRecognizedText}"'
            : 'Say "Simple", "Medium", or "Hard"';
        statusColor = Colors.purple;
        statusIcon = Icons.mic;
        break;
      case SessionState.paused:
        statusTitle = 'Paused';
        statusSubtitle = 'Tap Resume or say "Resume"';
        statusColor = Colors.grey;
        statusIcon = Icons.pause;
        break;
      default:
        statusTitle = 'Preparing session...';
        statusSubtitle = '';
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_top;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 14,
                  ),
                ),
                if (statusSubtitle.isNotEmpty)
                  Text(
                    statusSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme, bool isAnswerRevealed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: isAnswerRevealed
          ? Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _controller.manualSubmitRating(ReviewRating.hard),
                    child: const Text('Hard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _controller.manualSubmitRating(ReviewRating.medium),
                    child: const Text('Medium', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _controller.manualSubmitRating(ReviewRating.simple),
                    child: const Text('Simple', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility),
                label: const Text('Show Answer (or say "OK")', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _controller.manualRevealAnswer(),
              ),
            ),
    );
  }
}
