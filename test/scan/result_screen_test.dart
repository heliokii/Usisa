import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/scan/ai_models.dart';
import 'package:usisa/features/scan/result_screen.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/l10n/app_localizations.dart';
import 'package:usisa/theme/usisa_theme.dart';

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: UsisaTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: child,
);

ScanResult _result({
  ScanSource source = ScanSource.text,
  String text = 'A message for review.',
  List<Finding> findings = const [],
  List<LinkResult> links = const [],
  AiAssessment? aiAssessment,
}) => ScanResult(
  id: 'result',
  text: text,
  source: source,
  findings: findings,
  links: links,
  createdAt: DateTime(2026),
  aiAssessment: aiAssessment,
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpResult(
  WidgetTester tester,
  ScanResult result, {
  Uint8List? screenshotPreview,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    _app(
      ResultScreen(result: result, screenshotPreview: screenshotPreview),
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'summary shows three signs, overflow opens details, and both actions stay visible',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      final findings = [
        Finding('urgency', severity: RiskLevel.high, evidence: 'Act now'),
        Finding('prize', severity: RiskLevel.high, evidence: 'Claim prize'),
        Finding('advanceFee', severity: RiskLevel.high, evidence: 'Pay a fee'),
        Finding(
          'deceptiveHost',
          severity: RiskLevel.high,
          evidence: 'brand.example',
        ),
      ];
      await _pumpResult(tester, _result(findings: findings));

      expect(find.text('High Risk'), findsOneWidget);
      expect(find.text('Pressures you to act'), findsOneWidget);
      expect(find.text('Promises a prize'), findsOneWidget);
      expect(find.text('Asks for an upfront fee'), findsOneWidget);
      expect(find.text('Brand name on a different domain'), findsNothing);
      expect(find.text('Check another message'), findsOneWidget);
      expect(find.text('Safety Recommendations'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);

      await tester.tap(find.text('See 1 more sign'));
      await tester.pumpAndSettle();
      expect(find.text('Brand name on a different domain'), findsOneWidget);
    },
  );

  testWidgets('link summary opens full domain and reputation details', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    const url = 'https://gcash-verify.ph/secure';
    final finding = Finding(
      'deceptiveHost',
      severity: RiskLevel.high,
      evidence: 'gcash-verify.ph',
    );
    final link = LinkResult(
      original: url,
      uri: Uri.parse(url),
      findings: [finding],
    );
    await _pumpResult(
      tester,
      _result(source: ScanSource.link, text: url, links: [link]),
    );

    expect(find.text('High Risk'), findsOneWidget);
    await tester.tap(find.text('Full link').last);
    await tester.pumpAndSettle();
    expect(find.text('Domain'), findsOneWidget);
    expect(find.text('Similarity'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('gcash-verify.ph'), findsWidgets);
  });

  testWidgets(
    'screenshot preview is transient and history-style fallback remains usable',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      final screenshot = _result(
        source: ScanSource.screenshot,
        text: 'Your account needs verification.',
      );
      await _pumpResult(tester, screenshot, screenshotPreview: Uint8List(0));

      expect(find.byTooltip('View full image'), findsOneWidget);
      await tester.tap(find.byTooltip('View full image'));
      await tester.pumpAndSettle();
      expect(find.text('Screenshot'), findsWidgets);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await _pumpResult(tester, screenshot);
      expect(find.text('Your account needs verification.'), findsOneWidget);
      expect(find.byTooltip('View full image'), findsNothing);
    },
  );

  testWidgets('AI assessment opens a sheet and review still requires consent', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    const rawSummary = 'Untrusted server prose must not be shown.';
    final result = _result(
      aiAssessment: const AiAssessment(
        AiScanState.completed,
        risk: RiskLevel.caution,
        summary: rawSummary,
        findings: [Finding('urgency', evidence: 'Act now')],
      ),
    );
    await _pumpResult(tester, result);

    final aiAssessment = find.text('AI assessment').first;
    await tester.ensureVisible(aiAssessment);
    await tester.tap(aiAssessment);
    await tester.pumpAndSettle();
    expect(find.text('Need Review'), findsWidgets);
    expect(
      find.text(
        'AI can miss scams or flag safe messages. Quotes show its input, not proof.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(rawSummary), findsNothing);
    expect(find.text('Pressures you to act'), findsOneWidget);

    await tester.ensureVisible(find.text('Review for AI check'));
    await tester.tap(find.text('Review for AI check'));
    await tester.pumpAndSettle();
    expect(find.text('Send this text for AI check'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('unavailable AI can be reviewed and retried with consent', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await _pumpResult(
      tester,
      _result(aiAssessment: const AiAssessment(AiScanState.unavailable)),
    );

    expect(find.textContaining('AI is unavailable'), findsOneWidget);
    final assessment = find.text('AI assessment').first;
    await tester.ensureVisible(assessment);
    await tester.tap(assessment);
    await tester.pumpAndSettle();
    expect(find.textContaining('AI is unavailable'), findsWidgets);

    await tester.ensureVisible(find.text('Review and retry AI'));
    await tester.tap(find.text('Review and retry AI'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Send this text for AI check'), findsOneWidget);
  });

  testWidgets('checking AI can be cancelled from its assessment sheet', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await _pumpResult(
      tester,
      _result(aiAssessment: const AiAssessment(AiScanState.checking)),
    );

    final assessment = find.text('AI assessment').first;
    await tester.ensureVisible(assessment);
    await tester.tap(assessment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final l = AppLocalizations.of(tester.element(find.byType(ResultScreen)));
    expect(find.text(l.aiChecking), findsWidgets);
    expect(tester.takeException(), isNull);
    expect(find.text(l.cancel), findsOneWidget);

    await tester.tap(find.text(l.cancel));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('AI check cancelled.'), findsWidgets);
  });

  testWidgets(
    'result uses a scroll fallback for short viewports and large text',
    (tester) async {
      _setViewport(tester, const Size(320, 480));
      await _pumpResult(tester, _result());
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);

      _setViewport(tester, const Size(390, 844));
      await _pumpResult(tester, _result(), textScale: 2);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
