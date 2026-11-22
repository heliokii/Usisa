import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_localizations.dart';

/// The phone's speech engine; widget tests pass a fake.
abstract interface class TtsEngine {
  Future<bool> isLanguageAvailable(String tag);
  Future<void> setLanguage(String tag);
  Future<void> speak(String text);
  Future<void> stop();
}

class FlutterTtsEngine implements TtsEngine {
  // speak() resolves when the speech ends, so the button can turn back from Stop.
  final _tts = FlutterTts()..awaitSpeakCompletion(true);
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

  /// Every ReadAloud that has spoken, so leaving a page or tab can silence all of them.
  static final _all = <ReadAloud>{};
  static void stopAll() {
    for (final r in _all) {
      r.stop();
    }
  }

  /// What is being read right now (the key passed to [speak]), or null when silent.
  final speaking = ValueNotifier<Object?>(null);

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
  Future<String?> speak(String language, String Function(String language) textIn, {Object key = true}) async {
    _all.add(this);
    for (final lang in {language, 'en'}) {
      for (final tag in _voices[lang] ?? const <String>[]) {
        if (_available[tag] ??= await _tts.isLanguageAvailable(tag)) {
          await _tts.stop();
          await _tts.setLanguage(tag);
          speaking.value = key;
          // Not awaited: the caller gets the language straight away; Stop shows until the speech ends.
          _tts.speak(textIn(lang)).whenComplete(() {
            if (speaking.value == key) speaking.value = null;
          }).ignore();
          return lang;
        }
      }
    }
    return null;
  }

  Future<void> stop() async {
    speaking.value = null;
    await _engine?.stop();
  }
}

/// Speaks [textIn] in the app's language, with a note when it falls back to English or the phone has no voice.
Future<void> readAloudWithNote(
  BuildContext context,
  ReadAloud readAloud,
  String Function(AppLocalizations l) textIn, {
  Object key = true,
}) async {
  final l = AppLocalizations.of(context);
  final language = Localizations.localeOf(context).languageCode;
  final spoken = await readAloud.speak(language, (lang) => textIn(lookupAppLocalizations(Locale(lang))), key: key);
  if (!context.mounted || spoken == language) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(spoken == null ? l.readAloudUnavailable : l.readAloudNoFilipino)));
}

/// The Read aloud button: "Read aloud" while silent, "Stop reading" while it reads this [speechKey].
class ReadAloudButton extends StatelessWidget {
  const ReadAloudButton({super.key, required this.readAloud, required this.speechKey, required this.onRead});
  final ReadAloud readAloud;
  final Object speechKey;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: readAloud.speaking,
      builder: (context, current, _) {
        final reading = current == speechKey;
        return OutlinedButton(
          onPressed: reading ? readAloud.stop : onRead,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
            minimumSize: const Size.fromHeight(56),
            shape: const StadiumBorder(),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
          child: Text(reading ? l.stopReading : l.readAloud, textAlign: TextAlign.center),
        );
      },
    );
  }
}

/// Silences Read aloud whenever a page opens or closes on the navigator it watches.
class StopReadingOnNavigate extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => ReadAloud.stopAll();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => ReadAloud.stopAll();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => ReadAloud.stopAll();
}
