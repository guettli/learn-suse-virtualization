import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Manages Android Foreground Service & Wakelock for screen-off audio listening.
class ForegroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    try {
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onServiceStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: 'handsfree_flashcards_channel',
          initialNotificationTitle: 'Hands-Free Flashcards',
          initialNotificationContent: 'Continuous audio active',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [AndroidForegroundType.microphone],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onServiceStart,
          onBackground: (_) async => true,
        ),
      );
    } catch (e) {
      debugPrint("Background service config error: $e");
    }
  }

  static Future<void> startSessionService({required String deckName}) async {
    try {
      await WakelockPlus.enable();
      final isRunning = await _service.isRunning();
      if (!isRunning) {
        await _service.startService();
      }
      _service.invoke('update', {
        'title': 'Studying: $deckName',
        'content': 'Hands-free voice recognition active',
      });
    } catch (e) {
      debugPrint("Error starting background service: $e");
    }
  }

  static Future<void> stopSessionService() async {
    try {
      await WakelockPlus.disable();
      final isRunning = await _service.isRunning();
      if (isRunning) {
        _service.invoke('stopService');
      }
    } catch (e) {
      debugPrint("Error stopping background service: $e");
    }
  }

  @pragma('vm:entry-point')
  static void onServiceStart(ServiceInstance service) async {
    service.on('update').listen((event) {
      if (event != null && service is AndroidServiceInstance) {
        final title = event['title'] as String? ?? 'Hands-Free Flashcards';
        final content = event['content'] as String? ?? 'Listening for commands...';
        service.setForegroundNotificationInfo(
          title: title,
          content: content,
        );
      }
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
}
