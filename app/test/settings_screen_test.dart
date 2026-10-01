import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handsfree_anki/screens/settings_screen.dart';
import 'package:handsfree_anki/services/audio_cue_service.dart';
import 'package:handsfree_anki/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AudioCueService.isEnabled = true;
    });

    testWidgets('renders all settings controls and labels properly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Wait for async loadSettings
      await tester.pumpAndSettle();

      expect(find.text('Voice & Audio Settings'), findsOneWidget);
      expect(find.text('Speech Synthesis (TTS)'), findsOneWidget);
      expect(find.text('Voice Language / Accent'), findsOneWidget);
      expect(find.text('Speech Rate'), findsOneWidget);
      expect(find.text('Speech Volume'), findsOneWidget);
      expect(find.text('Voice Pitch'), findsOneWidget);
      expect(find.text('Listen Mode Cue (Beep)'), findsOneWidget);
      expect(find.text('Test Voice Settings'), findsOneWidget);
    });

    testWidgets('toggling audio cue switch persists new setting', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Tap the switch to disable it
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      expect(AudioCueService.isEnabled, isFalse);

      final loaded = await SettingsService.loadSettings();
      expect(loaded.audioCueEnabled, isFalse);
    });
  });
}
