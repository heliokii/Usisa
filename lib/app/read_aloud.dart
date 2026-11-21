import 'package:flutter_tts/flutter_tts.dart';

/// The phone's speech engine; widget tests pass a fake.
abstract interface class TtsEngine {
  Future<bool> isLanguageAvailable(String tag);
  Future<void> setLanguage(String tag);
  Future<void> speak(String text);
  Future<void> stop();
}

class FlutterTtsEngine implements TtsEngine {
  final _tts = FlutterTts();
  @override
  Future<bool> isLanguageAvailable(String tag) async {
    try {
      return await _tts.isLanguageAvailable(tag) == true;
    } catch (_) {
      return false; // No engine, or a platform without one: Read aloud reports it unavailable.
    }
  }

  @override
  Future<void> setLanguage(String tag) => _tts.setLanguage(tag);
  @override
  Future<void> speak(String text) => _tts.speak(text);
  @override
  Future<void> stop() => _tts.stop();
}

/// Reads app text aloud in the app's language, never Filipino text in an English voice.
class ReadAloud {
  ReadAloud([TtsEngine? engine]) : _engine = engine;
  TtsEngine? _engine;
  TtsEngine get _tts => _engine ??= FlutterTtsEngine(); // Created on first use so screens can hold one for free.
  final _available = <String, bool>{};

  // Engines report Filipino as fil or as the older tl tag.
  static const _voices = {
    'fil': ['fil-PH', 'tl-PH'],
    'en': ['en-US', 'en-PH', 'en-GB'],
  };

  /// Speaks [textIn] for [language] ('fil' or 'en'). Without a Filipino voice it speaks the English text instead.
  /// Returns the language spoken, or null when the phone has no usable voice.
  Future<String?> speak(String language, String Function(String language) textIn) async {
    for (final lang in {language, 'en'}) {
      for (final tag in _voices[lang] ?? const <String>[]) {
        if (_available[tag] ??= await _tts.isLanguageAvailable(tag)) {
          await _tts.stop();
          await _tts.setLanguage(tag);
          await _tts.speak(textIn(lang));
          return lang;
        }
      }
    }
    return null;
  }

  Future<void> stop() async => await _engine?.stop();
}
