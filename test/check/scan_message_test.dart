import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/history/history_store.dart';

Future<void> startApp(WidgetTester tester, {RunCheck? runCheck}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UsisaApp(storage: MemoryStorage(), runCheck: runCheck));
  // The header drift repeats forever, so pump past the entrance instead of settling.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> pasteAndCheck(WidgetTester tester, String text) async {
  // Centre the tile so the bottom nav doesn't cover it at large text sizes.
  await Scrollable.ensureVisible(tester.element(find.text('Scan a message')), alignment: .5);
  await tester.pump();
  await tester.tap(find.text('Scan a message'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.text('Check'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('paste a scam text and see the Dangerous verdict screen', (tester) async {
    await startApp(tester);
    await pasteAndCheck(tester, 'Your account is on hold. Send your OTP at bit.ly/verify-now');
    // First Check with a link asks for online consent; stay on the phone.
    await tester.tap(find.text('No, phone only'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Dangerous'), findsOneWidget);
    expect(find.byIcon(Icons.dangerous_rounded), findsOneWidget);
    expect(find.text("Don't tap the link, don't reply, and don't send money."), findsOneWidget);
    expect(find.text('It asks for your OTP or password and has a link'), findsOneWidget);
    expect(find.text('Checked on your phone'), findsOneWidget);
    expect(find.text('Your account is on hold. Send your OTP at bit.ly/verify-now'), findsOneWidget);
  });

  testWidgets('Check stays disabled until something is pasted', (tester) async {
    await startApp(tester);
    await tester.tap(find.text('Scan a message'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  for (final (verdict, word, icon) in [
    (Verdict.looksSafe, 'Looks safe', Icons.check_circle_rounded),
    (Verdict.beCareful, 'Be careful', Icons.error_rounded),
    (Verdict.dangerous, 'Dangerous', Icons.dangerous_rounded),
    (Verdict.couldntCheck, "Couldn't check", Icons.help_rounded),
  ]) {
    testWidgets('the verdict screen shows the $word look', (tester) async {
      await startApp(
        tester,
        runCheck: (input) async => CheckResult(
          text: input.text,
          verdict: verdict,
          reasons: const ['urgency', 'gambling_ad', 'unresolved_link'],
          checkedOnPhone: false,
        ),
      );
      await pasteAndCheck(tester, 'Hello po');

      expect(find.text(word), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
      expect(find.text('Why'), findsOneWidget);
      expect(find.text('It rushes you to act quickly'), findsOneWidget);
      expect(find.text('This is an unsolicited gambling ad'), findsOneWidget);
      expect(find.text("We couldn't see where the link goes"), findsOneWidget);
      expect(find.text('Checked on your phone'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('verdict screen lays out on a small phone with 200% text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await startApp(tester);
    await pasteAndCheck(tester, 'Congrats, you won P50,000! Claim your prize now. Reply URGENT');
    tester.view.physicalSize = const Size(320, 640);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.dragUntilVisible(find.text('You checked'), find.byType(CustomScrollView), const Offset(0, -200));
    expect(tester.takeException(), isNull);
    expect(find.text('Dangerous'), findsOneWidget);
  });
}
