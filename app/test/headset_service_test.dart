import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handsfree_anki/services/headset_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeadsetService Tests', () {
    const channel = MethodChannel('com.guettli.handsfree_anki/media');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return true;
      });
    });

    tearDown(() {
      HeadsetService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('maps play_pause platform event to HeadsetAction.playPause', () async {
      HeadsetAction? received;
      HeadsetService.initialize(onAction: (action) {
        received = action;
      });

      await HeadsetService.handleMethodCallForTesting(
        const MethodCall('onMediaAction', 'play_pause'),
      );

      expect(received, equals(HeadsetAction.playPause));
    });

    test('maps next platform event to HeadsetAction.next', () async {
      HeadsetAction? received;
      HeadsetService.initialize(onAction: (action) {
        received = action;
      });

      await HeadsetService.handleMethodCallForTesting(
        const MethodCall('onMediaAction', 'next'),
      );

      expect(received, equals(HeadsetAction.next));
    });

    test('maps previous platform event to HeadsetAction.previous', () async {
      HeadsetAction? received;
      HeadsetService.initialize(onAction: (action) {
        received = action;
      });

      await HeadsetService.handleMethodCallForTesting(
        const MethodCall('onMediaAction', 'previous'),
      );

      expect(received, equals(HeadsetAction.previous));
    });

    test('ignores unknown method or argument', () async {
      HeadsetAction? received;
      HeadsetService.initialize(onAction: (action) {
        received = action;
      });

      await HeadsetService.handleMethodCallForTesting(
        const MethodCall('unknownMethod', 'play_pause'),
      );
      expect(received, isNull);

      await HeadsetService.handleMethodCallForTesting(
        const MethodCall('onMediaAction', 'unknown_action'),
      );
      expect(received, isNull);
    });

    test('dispose removes listener', () async {
      HeadsetAction? received;
      HeadsetService.initialize(onAction: (action) {
        received = action;
      });

      HeadsetService.dispose();

      await HeadsetService.handleMethodCallForTesting(
        const MethodCall('onMediaAction', 'play_pause'),
      );
      expect(received, isNull);
    });

    test('startSession and stopSession call platform channel without errors', () async {
      const channel = MethodChannel('com.guettli.handsfree_anki/media');
      final log = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall.method);
        return true;
      });

      await HeadsetService.startSession();
      expect(log, contains('startMediaSession'));

      await HeadsetService.stopSession();
      expect(log, contains('stopMediaSession'));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  });
}
