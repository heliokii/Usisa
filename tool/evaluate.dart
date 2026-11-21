// Quality bar evaluation (#26). Runs under `flutter test` because the Check pipeline imports Flutter packages.
//
// Phone only means what the app does with online checks off: no link checker and no AI, so a message whose link the
// phone can't judge gets Couldn't check. Couldn't check is never counted as an alarm on harmless messages nor as a
// caught scam or gambling ad; the report lists it separately per label, as the spec's Quality bar says.
//
// Phone only (every change; fails when a phone-alone target is missed on the sealed split):
//   flutter test --no-pub tool/evaluate.dart
// Combined, with the online link check and AI (by hand before a release and after any prompt change):
//   flutter test --no-pub tool/evaluate.dart --dart-define=USISA_EVAL_AI=true --dart-define=USISA_GATEWAY_URL=https://usisa-gateway.onrender.com
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/gateway_ai_checker.dart';
import 'package:usisa/features/check/gateway_link_checker.dart';

import 'evaluation.dart';

const combined = bool.fromEnvironment('USISA_EVAL_AI');

void main() {
  test(combined ? 'combined evaluation (phone + link check + AI)' : 'phone-only evaluation', () async {
    final client = http.Client();
    final pipeline = combined
        ? CheckPipeline(linkChecker: gatewayLinkChecker(client, gatewayBase), aiChecker: gatewayAiChecker(client, gatewayBase, language: () => 'en'))
        : const CheckPipeline();
    final development = await evaluate(loadSplit(sealed: false), pipeline.run, aiScan: combined);
    final sealed = await evaluate(loadSplit(sealed: true), pipeline.run, aiScan: combined);
    client.close();

    final mode = combined ? 'combined' : 'phone only';
    // ignore: avoid_print
    print([
      '# Usisa Quality bar evaluation, $mode',
      development.format('Development split (70%, tune here)', combined: combined),
      sealed.format('Sealed split (30%, release targets)', combined: combined),
    ].join('\n\n'));
    expect(sealed.misses(combined: combined), isEmpty, reason: 'A missed target on the sealed split blocks the release.');
  }, timeout: const Timeout(Duration(minutes: 60)));
}
