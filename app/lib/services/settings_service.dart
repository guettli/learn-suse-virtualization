import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_cue_service.dart';

/// Immutable model holding user-customizable audio and TTS preferences.
class AppSettings {
  final double speechRate;
  final double volume;
  final double pitch;
  final String language;
  final bool audioCueEnabled;

  const AppSettings({
    this.speechRate = 0.5,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.language = 'en-US',
    this.audioCueEnabled = true,
  });

  AppSettings copyWith({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
    bool? audioCueEnabled,
  }) {
    return AppSettings(
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      language: language ?? this.language,
      audioCueEnabled: audioCueEnabled ?? this.audioCueEnabled,
    );
  }
}

/// Service managing persistence and application of user settings.
class SettingsService {
  static const String _keySpeechRate = 'settings_speech_rate';
  static const String _keyVolume = 'settings_volume';
  static const String _keyPitch = 'settings_pitch';
  static const String _keyLanguage = 'settings_language';
  static const String _keyAudioCue = 'settings_audio_cue';

  static const AppSettings defaultSettings = AppSettings();

  /// Loads stored user settings from SharedPreferences, falling back to defaults.
  static Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final speechRate = prefs.getDouble(_keySpeechRate) ?? defaultSettings.speechRate;
      final volume = prefs.getDouble(_keyVolume) ?? defaultSettings.volume;
      final pitch = prefs.getDouble(_keyPitch) ?? defaultSettings.pitch;
      final language = prefs.getString(_keyLanguage) ?? defaultSettings.language;
      final audioCueEnabled = prefs.getBool(_keyAudioCue) ?? defaultSettings.audioCueEnabled;

      AudioCueService.isEnabled = audioCueEnabled;

      return AppSettings(
        speechRate: speechRate,
        volume: volume,
        pitch: pitch,
        language: language,
        audioCueEnabled: audioCueEnabled,
      );
    } catch (e) {
      debugPrint("SettingsService.loadSettings error: $e");
      return defaultSettings;
    }
  }

  /// Persists user settings to SharedPreferences and updates active service state.
  static Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySpeechRate, settings.speechRate);
      await prefs.setDouble(_keyVolume, settings.volume);
      await prefs.setDouble(_keyPitch, settings.pitch);
      await prefs.setString(_keyLanguage, settings.language);
      await prefs.setBool(_keyAudioCue, settings.audioCueEnabled);

      AudioCueService.isEnabled = settings.audioCueEnabled;
    } catch (e) {
      debugPrint("SettingsService.saveSettings error: $e");
    }
  }

  /// Resets all preferences back to defaults.
  static Future<void> resetToDefaults() async {
    await saveSettings(defaultSettings);
  }
}
