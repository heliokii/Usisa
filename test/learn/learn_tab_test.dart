import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app/read_aloud.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/verdict_screen.dart';
import 'package:usisa/features/learn/learn_screen.dart';
import 'package:usisa/l10n/app_localizations.dart';

import '../check/verdict_actions_test.dart' show FakeTts;

Future<void> show(WidgetTester tester, Widget home, {String language = 'en'}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 300, scrollable: find.byType(Scrollable).first);
  await tester.pump();
}

void main() {
  for (final language in ['en', 'fil']) {
    testWidgets('Learn shows Golden rules, the 8 topics and Report a scam in $language', (tester) async {
      final l = lookupAppLocalizations(Locale(language));
      await show(tester, LearnScreen(readAloud: ReadAloud(FakeTts({}))), language: language);
      final titles = [l.learnGoldenTitle, for (final t in learnTopics) l.learnTopicTitle(t), l.learnReportTitle];
      for (final title in titles) {
        await scrollTo(tester, find.text(title));
        expect(find.text(title), findsOneWidget);
      }
      expect(learnTopics, hasLength(8));
      expect(l.learnReportChannels, contains('1326'));
    });

    test('every red flag in $language is quoted word for word from its sample text', () {
      final l = lookupAppLocalizations(Locale(language));
      for (final topic in learnTopics) {
        final flags = redFlags(l, topic);
        expect(flags, isNotEmpty, reason: topic);
        for (final (phrase, why) in flags) {
          expect(l.learnTopicSample(topic), contains(phrase), reason: '$topic: $phrase');
          expect(why, isNotEmpty);
        }
      }
    });
  }

  testWidgets('Read aloud on a topic card speaks that card in the app language', (tester) async {
    final tts = FakeTts({'en-US', 'tl-PH'});
    await show(tester, LearnScreen(readAloud: ReadAloud(tts)), language: 'fil');
    final card = find.byKey(const ValueKey('learn-family'));
    await scrollTo(tester, card);
    final button = find.descendant(of: card, matching: find.text('Basahin nang malakas'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();

    expect(tts.spoken, hasLength(1));
    expect(tts.spoken.single.$1, 'tl-PH');
    expect(tts.spoken.single.$2, startsWith(lookupAppLocalizations(const Locale('fil')).learnTopicTitle('family')));
  });

  test('verdict reasons map to their Learn topic', () {
    expect(learnTopicFor(['urgency', 'otp_with_link']), 'phishing');
    expect(learnTopicFor(['lookalike_domain']), 'phishing');
    expect(learnTopicFor(['prize_claim']), 'prize');
    expect(learnTopicFor(['payment_request']), 'prize');
    expect(learnTopicFor(['family_money']), 'family');
    expect(learnTopicFor(['gambling_ad']), 'gambling');
    expect(learnTopicFor(['urgency', 'brand_mention']), isNull);
    expect(learnTopicFor(['no_signs']), isNull);
  });

  testWidgets('a verdict whose reasons match a topic links to it, and the link opens it', (tester) async {
    const result = CheckResult(
      text: 'Hi Ma, pa-send ng 500 load',
      verdict: Verdict.looksSafe,
      reasons: ['family_money'],
      checkedOnPhone: true,
    );
    await show(tester, VerdictScreen(result: result, readAloud: ReadAloud(FakeTts({}))));
    final link = find.text('Learn more: Family emergency texts');
    await tester.ensureVisible(link);
    await tester.pumpAndSettle();
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('learn-family')), findsOneWidget);
    expect(find.text('Hi Ma, pa-send ng 500 load'), findsNothing, reason: 'the topic page replaced the verdict');
  });

  testWidgets('a verdict with no matching topic has no Learn link', (tester) async {
    const result = CheckResult(text: 'hello', verdict: Verdict.looksSafe, reasons: ['no_signs'], checkedOnPhone: true);
    await show(tester, VerdictScreen(result: result, readAloud: ReadAloud(FakeTts({}))));
    expect(find.textContaining('Learn more'), findsNothing);
  });
}
