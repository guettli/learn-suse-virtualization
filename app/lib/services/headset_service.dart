import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum HeadsetAction {
  playPause,
  next,
  previous,
}

/// Service that interfaces with Android MediaSession to capture Bluetooth/headset
/// media button clicks (Play/Pause, Next Track, Previous Track) even with the screen off.
class HeadsetService {
  static const MethodChannel _channel = MethodChannel('com.guettli.handsfree_anki/media');
  static void Function(HeadsetAction action)? _listener;

  /// Registers listener callback for headset button events.
  static void initialize({required void Function(HeadsetAction action) onAction}) {
    _listener = onAction;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Activates the native Android MediaSession.
  static Future<void> startSession() async {
    try {
      await _channel.invokeMethod('startMediaSession');
    } catch (e) {
      debugPrint("Error starting media session: $e");
    }
  }

  /// Deactivates the native Android MediaSession.
  static Future<void> stopSession() async {
    try {
      await _channel.invokeMethod('stopMediaSession');
    } catch (e) {
      debugPrint("Error stopping media session: $e");
    }
  }

  /// Cleans up listeners and releases media session.
  static void dispose() {
    _listener = null;
    _channel.setMethodCallHandler(null);
    stopSession();
  }

  @visibleForTesting
  static Future<void> handleMethodCallForTesting(MethodCall call) => _handleMethodCall(call);

  static Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onMediaAction') {
      final actionStr = call.arguments as String?;
      switch (actionStr) {
        case 'play_pause':
          _listener?.call(HeadsetAction.playPause);
          break;
        case 'next':
          _listener?.call(HeadsetAction.next);
          break;
        case 'previous':
          _listener?.call(HeadsetAction.previous);
          break;
      }
    }
  }
}
