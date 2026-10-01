import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service providing audible earcon cues (chimes/beeps) to signal hands-free state transitions,
/// such as when TTS speech ends and the microphone begins listening for user commands.
class AudioCueService {
  static const MethodChannel _channel = MethodChannel('com.guettli.handsfree_anki/audio_cue');

  /// Master switch to enable or disable audio earcon feedback.
  static bool isEnabled = true;

  /// Plays a subtle beep tone to notify the user that speech recognition is active.
  static Future<void> playListenCue() async {
    if (!isEnabled) return;
    try {
      await _channel.invokeMethod('playListenCue');
    } catch (e) {
      debugPrint('AudioCueService: unable to play listen cue: $e');
    }
  }
}
