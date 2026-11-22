import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/check/check.dart';

import 'ai_scan_test.dart' show openAiScan, settle, tapCheck;
import 'scan_message_test.dart' show pasteAndCheck, startApp;

const askAi = 'Ask AI to look closer';

CheckResult result(CheckInput input, Verdict verdict) =>
    CheckResult(text: input.text, verdict: verdict, reasons: const ['urgency'], checkedOnPhone: false);

void main() {
  for (final (verdict, shown) in [
    (Verdict.looksSafe, false),
    (Verdict.beCareful, true),
    (Verdict.dangerous, false),
    (Verdict.couldntCheck, true),
  ]) {
    testWidgets('a plain tile ${verdict.name} verdict ${shown ? 'offers' : 'does not offer'} $askAi', (tester) async {
      await startApp(tester, runCheck: (input) async => result(input, verdict));
      await pasteAndCheck(tester, 'Hello po');
      expect(find.text(askAi), shown ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('an AI scan verdict never offers $askAi', (tester) async {
    await openAiScan(tester, runCheck: (input) async => result(input, Verdict.beCareful));
    await tester.tap(find.text('Scan a message'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Hello po');
    await tapCheck(tester);
    expect(find.text('Be careful'), findsOneWidget);
    expect(find.text(askAi), findsNothing);
  });

  testWidgets('tapping $askAi shows the AI scan verdict for the same input', (tester) async {
    final inputs = <CheckInput>[];
    await startApp(
      tester,
      runCheck: (input) async {
        inputs.add(input);
        return result(input, input.aiScan ? Verdict.dangerous : Verdict.beCareful);
      },
    );
    await pasteAndCheck(tester, 'Hello po');
    await tester.ensureVisible(find.text(askAi));
    await tester.tap(find.text(askAi));
    await settle(tester);

    expect(inputs.last.text, 'Hello po');
    expect(inputs.last.aiScan, isTrue);
    expect(inputs.last.source, CheckSource.message);
    expect(find.text('Dangerous'), findsOneWidget);
    expect(find.text('Be careful'), findsNothing);
    expect(find.text(askAi), findsNothing);
  });
}
