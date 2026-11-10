import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/settings/settings_store.dart';
import 'package:usisa/features/scan/ai_scan_client.dart';
import 'package:usisa/features/scan/ai_models.dart';
import 'package:usisa/features/scan/ai_review_screen.dart';
import 'package:usisa/features/scan/scan_screen.dart';
import 'package:usisa/features/scan/ocr_service.dart';
import 'package:usisa/features/scan/ocr_models.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/scan/result_screen.dart';
import 'package:usisa/features/scan/scam_analyzer.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/theme/usisa_theme.dart';

import 'ai_models_test.dart' show assessment;

Future<void> tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Widget app(
  Widget home, {
  Locale locale = const Locale('en'),
  double scale = 1,
}) => MaterialApp(
  theme: UsisaTheme.light,
  darkTheme: UsisaTheme.dark,
  themeMode: ThemeMode.dark,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(body: home),
);

class ScreenshotOcr extends OcrService {
  @override
  bool get available => true;
  @override
  Future<OcrDraft?> recoverScreenshot() async => null;
  @override
  Future<OcrDraft?> readScreenshot() async =>
      OcrDraft(text: 'Send your OTP', bytes: Uint8List(0));
}

void main() {
  testWidgets(
    'editing a retained result replaces its text under the same scan identity',
    (tester) async {
      final storage = MemoryStorage();
      final history = HistoryStore(storage);
      await history.setEnabled(true);
      final original = ScamAnalyzer().analyze(
        const ScanInput('Original private text'),
      );
      await history.save(original, expectedGeneration: 0);
      await tester.pumpWidget(
        app(
          ResultScreen(
            result: original,
            history: history,
            aiFactory: () => AiScanClient(
              baseUri: Uri.parse('https://gateway.test'),
              client: MockClient(
                (_) async => http.Response(jsonEncode(assessment()), 200),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Review for AI check');
      await tester.enterText(find.byType(TextFormField), 'Send your OTP');
      await tap(tester, 'Send this text for AI check');
      expect(history.entries, hasLength(1));
      expect(history.entries.single.id, original.id);
      expect(history.entries.single.createdAt, original.createdAt);
      expect(history.entries.single.text, 'Send your OTP');
      expect(
        storage.values.values.any(
          (value) => value.contains('Original private text'),
        ),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      history.dispose();
    },
  );
  testWidgets(
    'result prose is app-owned even for a legacy or injected assessment',
    (tester) async {
      final local = ScamAnalyzer().analyze(const ScanInput('Send your OTP'));
      await tester.pumpWidget(
        app(
          ResultScreen(
            result: local.withAi(
              const AiAssessment(
                AiScanState.completed,
                risk: RiskLevel.high,
                summary: 'Call 09171234567 or visit https://invented.test for support.',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('invented.test'), findsNothing);
      expect(find.textContaining('09171234567'), findsNothing);
    },
  );
  testWidgets(
    'SMS review, failure, retry, pause and resume always need a new confirmation',
    (tester) async {
      final storage = MemoryStorage();
      final history = HistoryStore(storage);
      await history.setEnabled(true);
      final pending = Completer<http.Response>();
      var calls = 0;
      final local = ScamAnalyzer().analyze(
        const ScanInput(
          'GCash: Send your OTP immediately.',
          source: ScanSource.sms,
        ),
      );
      await tester.pumpWidget(
        app(
          ResultScreen(
            result: local,
            history: history,
            aiFactory: () => AiScanClient(
              baseUri: Uri.parse('https://gateway.test'),
              client: MockClient((_) async {
                calls++;
                return calls == 1 ? http.Response('{}', 503) : pending.future;
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tap(tester, 'Review for AI check');
      await tap(tester, 'Send this text for AI check');
      expect(calls, 1);
      expect(find.textContaining('AI assessment unavailable'), findsOneWidget);
      expect(find.text('High risk'), findsWidgets);
      await tap(tester, 'Review and retry AI');
      expect(calls, 1);
      await tester.ensureVisible(find.text('Send this text for AI check'));
      await tester.tap(find.text('Send this text for AI check'));
      for (var frame = 0; frame < 10 && calls < 2; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      pending.complete(http.Response(jsonEncode(assessment()), 200));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.textContaining('AI check cancelled.'), findsOneWidget);
      expect(history.entries.single.aiAssessment?.state.name, 'unavailable');
      await tester.pumpWidget(const SizedBox.shrink());
      history.dispose();
    },
  );
  for (final mode in ['message', 'screenshot']) {
    testWidgets(
      'reviewed $mode sends only edited text after confirmation; lower AI cannot clear local warnings',
      (tester) async {
        final storage = MemoryStorage();
        final history = HistoryStore(storage);
        final settings = SettingsStore(storage);
        final wait = Completer<http.Response>();
        var calls = 0;
        await tester.pumpWidget(
          app(
            ScanScreen(
              history: history,
              settings: settings,
              ocr: ScreenshotOcr(),
              aiFactory: () => AiScanClient(
                baseUri: Uri.parse('https://gateway.test'),
                client: MockClient((request) {
                  calls++;
                  expect(jsonDecode(request.body), {
                    'text': 'GCash: Send your OTP immediately.',
                    'responseLanguage': 'en',
                  });
                  return wait.future;
                }),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final localChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'On-device'),
        );
        expect(localChip.selected, isTrue);
        await tap(tester, 'AI assisted');
        if (mode == 'screenshot') {
          await tap(tester, 'Screenshot');
          await tap(tester, 'Choose screenshot');
          await tap(tester, 'Check this text');
        } else {
          await tester.enterText(
            find.byType(TextField).first,
            'Original private text',
          );
          await tap(tester, 'Review for AI check');
        }
        expect(calls, 0);
        expect(find.text('Send this text for AI check'), findsOneWidget);
        await tester.enterText(
          find.byType(TextFormField),
          'GCash: Send your OTP immediately.',
        );
        await tester.ensureVisible(find.text('Send this text for AI check'));
        await tester.tap(find.text('Send this text for AI check'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        for (
          var frame = 0;
          frame < 10 && find.text('Scan result').evaluate().isEmpty;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(calls, 1);
        expect(find.text('High risk'), findsWidgets);
        expect(
          find.text('On-device checks complete. AI is checking…'),
          findsOneWidget,
        );
        wait.complete(http.Response(jsonEncode(assessment(risk: 'low')), 200));
        await tester.pumpAndSettle();
        expect(find.text('High risk'), findsWidgets);
        expect(find.text('AI assessment'), findsOneWidget);
        expect(find.textContaining('The assessments differ'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        history.dispose();
        settings.dispose();
      },
    );
  }
  testWidgets(
    'keep on device, cancel, history open and app resume never upload automatically',
    (tester) async {
      final storage = MemoryStorage();
      final history = HistoryStore(storage);
      final settings = SettingsStore(storage);
      var calls = 0;
      await tester.pumpWidget(
        app(
          ScanScreen(
            history: history,
            settings: settings,
            aiFactory: () => AiScanClient(
              baseUri: Uri.parse('https://gateway.test'),
              client: MockClient((_) async {
                calls++;
                return http.Response('{}', 503);
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Hello');
      await tap(tester, 'AI assisted');
      await tap(tester, 'Review for AI check');
      await tap(tester, 'Cancel');
      expect(find.text('Hello'), findsOneWidget);
      expect(calls, 0);
      await tap(tester, 'Review for AI check');
      await tap(tester, 'Keep on device');
      expect(find.text('Scan result'), findsOneWidget);
      expect(calls, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(calls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      history.dispose();
      settings.dispose();
    },
  );
  for (final width in [320.0, 840.0]) {
    testWidgets(
      'Filipino AI review at $width and 200% text remains editable with keyboard',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          app(
            const AiReviewScreen(input: ScanInput('Send your OTP')),
            locale: const Locale('fil'),
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        await tester.showKeyboard(find.byType(TextFormField));
        await tester.enterText(find.byType(TextFormField), '');
        await tap(tester, 'Ipadala ang tekstong ito para sa AI');
        expect(tester.takeException(), isNull);
        expect(find.byType(TextFormField), findsOneWidget);
      },
    );
  }
}
