import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app/read_aloud.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/verdict_actions.dart';
import 'package:usisa/features/check/verdict_screen.dart';
import 'package:usisa/l10n/app_localizations.dart';

/// A phone's speech engine with only the [voices] installed.
class FakeTts implements TtsEngine {
  FakeTts(this.voices);
  final Set<String> voices;
  String? voice;
  final spoken = <(String voice, String text)>[];

  @override
  Future<bool> isLanguageAvailable(String tag) async => voices.contains(tag);
  @override
  Future<void> setLanguage(String tag) async => voice = tag;
  @override
  Future<void> speak(String text) async => spoken.add((voice!, text));
  @override
  Future<void> stop() async {}
}

const dangerous = CheckResult(
  text: 'Send your OTP at bit.ly/verify-now',
  verdict: Verdict.dangerous,
  reasons: ['otp_with_link', 'urgency'],
  checkedOnPhone: true,
);

Future<void> showVerdict(WidgetTester tester, {String language = 'en', TtsEngine? tts, ShareText? share}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: VerdictScreen(result: dangerous, readAloud: ReadAloud(tts ?? FakeTts({})), share: share),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500)); // Let the note slide in.
}

void main() {
  stopTests();
  testWidgets('Read aloud speaks the verdict and its advice in English', (tester) async {
    final tts = FakeTts({'en-US'});
    await showVerdict(tester, tts: tts);
    await tapButton(tester, 'Read aloud');

    expect(tts.spoken, [('en-US', "Dangerous. Don't tap the link, don't reply, and don't send money.")]);
  });

  testWidgets('Read aloud uses a Filipino voice when the phone has one', (tester) async {
    final tts = FakeTts({'en-US', 'tl-PH'});
    await showVerdict(tester, language: 'fil', tts: tts);
    await tapButton(tester, 'Basahin nang malakas');

    expect(tts.spoken, [('tl-PH', 'Delikado. Huwag pindutin ang link, huwag sumagot, at huwag magpadala ng pera.')]);
  });

  testWidgets('without a Filipino voice, Read aloud reads the English verdict in English and says so', (tester) async {
    final tts = FakeTts({'en-US'});
    await showVerdict(tester, language: 'fil', tts: tts);
    await tapButton(tester, 'Basahin nang malakas');

    expect(tts.spoken, [('en-US', "Dangerous. Don't tap the link, don't reply, and don't send money.")]);
    expect(find.text('Walang Filipino na boses sa phone na ito, kaya binabasa sa English.'), findsOneWidget);
  });

  testWidgets('with no voice at all, Read aloud says it is unavailable and speaks nothing', (tester) async {
    final tts = FakeTts({});
    await showVerdict(tester, tts: tts);
    await tapButton(tester, 'Read aloud');

    expect(tts.spoken, isEmpty);
    expect(find.text("Read aloud isn't available on this phone."), findsOneWidget);
  });

  testWidgets('Send to family shares the verdict and a short explanation', (tester) async {
    final shared = <String>[];
    await showVerdict(tester, share: (text) async => shared.add(text));
    await tapButton(tester, 'Send to family');

    expect(shared, [
      'I checked a message with Usisa. It says: Dangerous\n'
          "Don't tap the link, don't reply, and don't send money.\n"
          '- It asks for your OTP or password and has a link\n'
          '- It rushes you to act quickly',
    ]);
  });

  testWidgets('both buttons are text-only', (tester) async {
    await showVerdict(tester, share: (_) async {});
    for (final label in ['Send to family', 'Read aloud']) {
      final button = find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      expect(find.descendant(of: button, matching: find.byType(Icon)), findsNothing);
    }
  });
}

/// A speech engine that keeps talking until it is stopped, like a long read on a real phone.
class LongTts implements TtsEngine {
  var stops = 0;
  Completer<void>? _talking;
  @override
  Future<bool> isLanguageAvailable(String tag) async => tag == 'en-US';
  @override
  Future<void> setLanguage(String tag) async {}
  @override
  Future<void> speak(String text) => (_talking = Completer<void>()).future;
  @override
  Future<void> stop() async {
    stops++;
    if (!(_talking?.isCompleted ?? true)) _talking!.complete();
  }
}

void stopTests() {
  testWidgets('Read aloud turns into Stop reading while it speaks, and Stop silences it', (tester) async {
    final tts = LongTts();
    await showVerdict(tester, tts: tts);
    await tapButton(tester, 'Read aloud');
    expect(find.text('Stop reading'), findsOneWidget);

    final stopsBefore = tts.stops;
    await tapButton(tester, 'Stop reading');
    expect(tts.stops, greaterThan(stopsBefore));
    expect(find.text('Read aloud'), findsOneWidget);
  });

  testWidgets('opening another page stops the reading', (tester) async {
    final tts = LongTts();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [StopReadingOnNavigate()],
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: VerdictScreen(result: dangerous, readAloud: ReadAloud(tts)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tapButton(tester, 'Read aloud');
    final stopsBefore = tts.stops;

    navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
    await tester.pump();
    expect(tts.stops, greaterThan(stopsBefore));
  });
}
