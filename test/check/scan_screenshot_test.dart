import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/history/history_store.dart';
import 'package:usisa/features/scan/scan_models.dart';

Future<void> openScreenshotTile(
  WidgetTester tester, {
  required Future<String?> Function() readScreenshot,
  RunCheck? runCheck,
}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UsisaApp(storage: MemoryStorage(), readScreenshot: readScreenshot, runCheck: runCheck));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await Scrollable.ensureVisible(tester.element(find.text('Scan a screenshot')), alignment: .5);
  await tester.pump();
  await tester.tap(find.text('Scan a screenshot'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.text('Choose a screenshot'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> tapCheck(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Check'));
  await tester.tap(find.text('Check'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('the read text is shown for review, then checked', (tester) async {
    await openScreenshotTile(
      tester,
      readScreenshot: () async => 'Your account is on hold. Send your OTP at bit.ly/verify-now',
    );
    expect(find.text('Check the text we read and fix any mistakes.'), findsOneWidget);
    expect(find.text('Your account is on hold. Send your OTP at bit.ly/verify-now'), findsOneWidget);

    await tapCheck(tester);
    // First Check with a link asks for online consent; stay on the phone.
    await tester.tap(find.text('No, phone only'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Dangerous'), findsOneWidget);
  });

  testWidgets('the edited text is what gets checked', (tester) async {
    CheckInput? checked;
    await openScreenshotTile(
      tester,
      readScreenshot: () async => 'Hi Ma, pa-send ng pera',
      runCheck: (input) async {
        checked = input;
        return CheckResult(
          text: input.text,
          verdict: Verdict.looksSafe,
          reasons: const ['no_signs'],
          checkedOnPhone: true,
        );
      },
    );
    await tester.enterText(find.byType(TextField), 'Hi Ma, nakauwi na ako');
    await tapCheck(tester);

    expect(checked!.text, 'Hi Ma, nakauwi na ako');
    expect(checked!.source, CheckSource.screenshot);
  });

  for (final (name, read) in [
    ('a failed read', () async => throw const ScanException('ocrFailed')),
    ('a picture with no text', () async => '   '),
  ]) {
    testWidgets('$name shows a plain message, never a verdict', (tester) async {
      var checks = 0;
      await openScreenshotTile(
        tester,
        readScreenshot: read,
        runCheck: (input) async {
          checks++;
          throw StateError('no Check should run');
        },
      );
      expect(find.text("We couldn't read any text in this picture. Try a clearer screenshot."), findsOneWidget);
      expect(find.text('Check'), findsNothing);
      expect(checks, 0);
    });
  }

  testWidgets('cancelling the picker stays on the tile', (tester) async {
    await openScreenshotTile(tester, readScreenshot: () async => null);
    expect(find.text('Choose a screenshot'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
