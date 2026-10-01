import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handsfree_anki/services/audio_cue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioCueService Tests', () {
    const channel = MethodChannel('com.guettli.handsfree_anki/audio_cue');
    final methodCalls = <String>[];

    setUp(() {
      methodCalls.clear();
      AudioCueService.isEnabled = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call.method);
        return true;
      });
    });

    tearDown(() {
      AudioCueService.isEnabled = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('playListenCue invokes platform method when enabled', () async {
      await AudioCueService.playListenCue();
      expect(methodCalls, contains('playListenCue'));
    });

    test('playListenCue does not invoke platform method when isEnabled is false', () async {
      AudioCueService.isEnabled = false;
      await AudioCueService.playListenCue();
      expect(methodCalls, isEmpty);
    });

    test('playListenCue gracefully handles platform channel exceptions', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        throw PlatformException(code: 'ERROR', message: 'Failed to play tone');
      });

      // Should not throw
      await expectLater(AudioCueService.playListenCue(), completes);
    });
  });
}
