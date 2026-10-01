import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isLoading = true;
  AppSettings _settings = const AppSettings();
  bool _isPlayingPreview = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlayingPreview = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _isPlayingPreview = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final loaded = await SettingsService.loadSettings();
    if (mounted) {
      setState(() {
        _settings = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(AppSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    await SettingsService.saveSettings(newSettings);
  }

  Future<void> _testVoice() async {
    if (_isPlayingPreview) {
      await _tts.stop();
      if (mounted) setState(() => _isPlayingPreview = false);
      return;
    }

    setState(() => _isPlayingPreview = true);
    await _tts.setLanguage(_settings.language);
    await _tts.setSpeechRate(_settings.speechRate);
    await _tts.setVolume(_settings.volume);
    await _tts.setPitch(_settings.pitch);

    final previewText = _settings.language.startsWith('de')
        ? 'Dies ist eine Sprachprobe für freihändiges Lernen.'
        : 'This is a voice preview for hands-free study.';

    await _tts.speak(previewText);
  }

  Future<void> _resetDefaults() async {
    if (_isPlayingPreview) {
      await _tts.stop();
      _isPlayingPreview = false;
    }
    await SettingsService.resetToDefaults();
    if (mounted) {
      setState(() {
        _settings = SettingsService.defaultSettings;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to defaults.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Voice & Audio Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice & Audio Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
            onPressed: _resetDefaults,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Section: Text-to-Speech Voice
          Text(
            'Speech Synthesis (TTS)',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Language / Accent
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Voice Language / Accent'),
              subtitle: Text(
                _settings.language == 'en-US'
                    ? 'English (US)'
                    : _settings.language == 'en-GB'
                        ? 'English (UK)'
                        : 'German (DE)',
              ),
              trailing: DropdownButton<String>(
                value: _settings.language,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                  DropdownMenuItem(value: 'en-GB', child: Text('English (UK)')),
                  DropdownMenuItem(value: 'de-DE', child: Text('German (DE)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _updateSettings(_settings.copyWith(language: val));
                  }
                },
              ),
            ),
          ),

          // Speech Rate Slider
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed, size: 20),
                          const SizedBox(width: 8),
                          Text('Speech Rate', style: theme.textTheme.titleSmall),
                        ],
                      ),
                      Text(
                        '${(_settings.speechRate * 2.0).toStringAsFixed(2)}x',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.speechRate,
                    min: 0.2,
                    max: 1.0,
                    divisions: 16,
                    label: '${(_settings.speechRate * 2.0).toStringAsFixed(2)}x',
                    onChanged: (val) {
                      _updateSettings(_settings.copyWith(speechRate: val));
                    },
                  ),
                ],
              ),
            ),
          ),

          // Volume Slider
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volume_up, size: 20),
                          const SizedBox(width: 8),
                          Text('Speech Volume', style: theme.textTheme.titleSmall),
                        ],
                      ),
                      Text(
                        '${(_settings.volume * 100).toInt()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.volume,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: '${(_settings.volume * 100).toInt()}%',
                    onChanged: (val) {
                      _updateSettings(_settings.copyWith(volume: val));
                    },
                  ),
                ],
              ),
            ),
          ),

          // Pitch Slider
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, size: 20),
                          const SizedBox(width: 8),
                          Text('Voice Pitch', style: theme.textTheme.titleSmall),
                        ],
                      ),
                      Text(
                        '${_settings.pitch.toStringAsFixed(1)}x',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.pitch,
                    min: 0.5,
                    max: 1.5,
                    divisions: 10,
                    label: '${_settings.pitch.toStringAsFixed(1)}x',
                    onChanged: (val) {
                      _updateSettings(_settings.copyWith(pitch: val));
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Section: Audio Feedback
          Text(
            'Audible Feedback & Earcons',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Listen Earcon Switch
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: SwitchListTile(
              secondary: const Icon(Icons.hearing),
              title: const Text('Listen Mode Cue (Beep)'),
              subtitle: const Text(
                'Play a subtle prompt beep when speech ends and the microphone begins listening.',
              ),
              value: _settings.audioCueEnabled,
              onChanged: (val) {
                _updateSettings(_settings.copyWith(audioCueEnabled: val));
              },
            ),
          ),

          const SizedBox(height: 24),

          // Preview Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            ),
            icon: Icon(_isPlayingPreview ? Icons.stop : Icons.play_arrow),
            label: Text(
              _isPlayingPreview ? 'Stop Voice Preview' : 'Test Voice Settings',
              style: const TextStyle(fontSize: 16),
            ),
            onPressed: _testVoice,
          ),
        ],
      ),
    );
  }
}
