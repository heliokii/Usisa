import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/history/history_store.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> openAiScan(WidgetTester tester, {required RunCheck runCheck, Future<String?> Function()? readScreenshot}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UsisaApp(storage: MemoryStorage(), runCheck: runCheck, readScreenshot: readScreenshot));
  await settle(tester);
  await Scrollable.ensureVisible(tester.element(find.text('AI scan')), alignment: .5);
  await tester.pump();
  await tester.tap(find.text('AI scan'));
  await settle(tester);
}

Future<void> tapCheck(WidgetTester tester) async {
  await tester.pump();
  await tester.ensureVisible(find.text('Check'));
  await tester.tap(find.text('Check'));
  await settle(tester);
}

void main() {
  CheckResult answer(CheckInput input) =>
      CheckResult(text: input.text, verdict: Verdict.beCareful, reasons: const ['urgency'], checkedOnPhone: false);

  testWidgets('AI scan lets the person choose a message, a link or a screenshot', (tester) async {
    final inputs = <CheckInput>[];
    await openAiScan(
      tester,
      runCheck: (input) async {
        inputs.add(input);
        return answer(input);
      },
      readScreenshot: () async => 'Read from the picture',
    );
    expect(find.text('A message'), findsOneWidget);
    expect(find.text('A link'), findsOneWidget);
    expect(find.text('A screenshot'), findsOneWidget);

    await tester.tap(find.text('A message'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Pay now po');
    await tapCheck(tester);
    expect(find.text('Be careful'), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('A link'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'bit.ly/x');
    await tapCheck(tester);
    await tester.pageBack();
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text('A screenshot'));
    await settle(tester);
    await tester.tap(find.text('Choose a screenshot'));
    await settle(tester);
    await tapCheck(tester);

    expect([for (final i in inputs) (i.text, i.source, i.aiScan)], [
      ('Pay now po', CheckSource.message, true),
      ('bit.ly/x', CheckSource.link, true),
      ('Read from the picture', CheckSource.screenshot, true),
    ]);
  });

  testWidgets('the AI\'s quoted words are highlighted in the checked text', (tester) async {
    await openAiScan(
      tester,
      runCheck: (input) async => CheckResult(
        text: input.text,
        verdict: Verdict.dangerous,
        reasons: const ['credential_request'],
        checkedOnPhone: false,
        evidence: const ['Send your OTP'],
      ),
    );
    await tester.tap(find.text('A message'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Hi! Send your OTP now');
    await tapCheck(tester);

    final checked = tester.widget<Text>(find.text('Hi! Send your OTP now'));
    final highlighted = <String>[];
    checked.textSpan!.visitChildren((span) {
      if (span is TextSpan && span.style?.backgroundColor != null) highlighted.add(span.text!);
      return true;
    });
    expect(highlighted, ['Send your OTP']);
  });

  testWidgets('when the AI could not answer, the verdict says so', (tester) async {
    await openAiScan(
      tester,
      runCheck: (input) async => CheckResult(
        text: input.text,
        verdict: Verdict.looksSafe,
        reasons: const ['no_signs'],
        checkedOnPhone: true,
        aiUnavailable: true,
      ),
    );
    await tester.tap(find.text('A message'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Hello po');
    await tapCheck(tester);
    expect(find.text('Looks safe'), findsOneWidget);
    expect(find.text("AI couldn't look at this right now"), findsOneWidget);
  });
}
