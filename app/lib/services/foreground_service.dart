import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
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

/// Manages Android Foreground Service & Wakelock for screen-off audio listening.
@pragma('vm:entry-point')
class ForegroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initialize() async {
    try {
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
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
          onForeground: onBackgroundServiceStart,
          onBackground: (_) async => true,
        ),
      );
    } catch (e) {
      debugPrint("Background service config error: $e");
    }
  }

  static Future<bool> startSessionService({required String deckName}) async {
    try {
      await WakelockPlus.enable();

      // On Android 14+ (and Android generally), starting FGS with type microphone
      // requires RECORD_AUDIO permission to be actively granted.
      final micGranted = await Permission.microphone.isGranted;
      if (!micGranted) {
        debugPrint("Microphone permission not granted; running in standard foreground mode.");
        return false;
      }

      final isRunning = await _service.isRunning();
      if (!isRunning) {
        await _service.startService();
      }
      _service.invoke('update', {
        'title': 'Studying: $deckName',
        'content': 'Hands-free voice recognition active',
      });
      return true;
    } catch (e, stack) {
      debugPrint("Error starting background service (continuing safely): $e\n$stack");
      return false;
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
}

