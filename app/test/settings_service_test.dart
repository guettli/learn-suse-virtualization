import 'package:flutter_test/flutter_test.dart';
import 'package:handsfree_anki/services/audio_cue_service.dart';
import 'package:handsfree_anki/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadSettings returns default settings when no preferences stored', () async {
      final settings = await SettingsService.loadSettings();

      expect(settings.speechRate, equals(0.5));
      expect(settings.volume, equals(1.0));
      expect(settings.pitch, equals(1.0));
      expect(settings.language, equals('en-US'));
      expect(settings.audioCueEnabled, isTrue);
      expect(AudioCueService.isEnabled, isTrue);
    });

    test('saveSettings persists values and updates AudioCueService.isEnabled', () async {
      const customSettings = AppSettings(
        speechRate: 0.75,
        volume: 0.8,
        pitch: 1.2,
        language: 'de-DE',
        audioCueEnabled: false,
      );

      await SettingsService.saveSettings(customSettings);
      expect(AudioCueService.isEnabled, isFalse);

      final loaded = await SettingsService.loadSettings();
      expect(loaded.speechRate, equals(0.75));
      expect(loaded.volume, equals(0.8));
      expect(loaded.pitch, equals(1.2));
      expect(loaded.language, equals('de-DE'));
      expect(loaded.audioCueEnabled, isFalse);
    });

    test('resetToDefaults restores default values', () async {
      const customSettings = AppSettings(
        speechRate: 0.9,
        volume: 0.5,
        pitch: 1.5,
        language: 'en-GB',
        audioCueEnabled: false,
      );
      await SettingsService.saveSettings(customSettings);

      await SettingsService.resetToDefaults();

      final reset = await SettingsService.loadSettings();
      expect(reset.speechRate, equals(SettingsService.defaultSettings.speechRate));
      expect(reset.volume, equals(SettingsService.defaultSettings.volume));
      expect(reset.pitch, equals(SettingsService.defaultSettings.pitch));
      expect(reset.language, equals(SettingsService.defaultSettings.language));
      expect(reset.audioCueEnabled, equals(SettingsService.defaultSettings.audioCueEnabled));
      expect(AudioCueService.isEnabled, isTrue);
    });

    test('AppSettings copyWith works accurately', () {
      const initial = AppSettings();
      final updated = initial.copyWith(
        speechRate: 0.6,
        audioCueEnabled: false,
      );

      expect(updated.speechRate, equals(0.6));
      expect(updated.volume, equals(initial.volume));
      expect(updated.pitch, equals(initial.pitch));
      expect(updated.language, equals(initial.language));
      expect(updated.audioCueEnabled, isFalse);
    });
  });
}
