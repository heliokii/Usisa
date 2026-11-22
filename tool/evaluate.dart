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
// Combined runs one split per run, because each message costs one AI call against the gateway's AI_DAILY_LIMIT:
// the sealed split by default (about 390 calls, release targets), or the development split for tuning with
// --dart-define=USISA_EVAL_SPLIT=development (about 950 calls). Calls are paced under the gateway's 10 AI calls a minute.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/gateway_ai_checker.dart';
import 'package:usisa/features/check/gateway_link_checker.dart';

import 'evaluation.dart';

const combined = bool.fromEnvironment('USISA_EVAL_AI');
const developmentOnly = String.fromEnvironment('USISA_EVAL_SPLIT') == 'development';

void main() {
  test(combined ? 'combined evaluation (phone + link check + AI)' : 'phone-only evaluation', () async {
    final client = http.Client();
    final pipeline = combined
        ? CheckPipeline(linkChecker: gatewayLinkChecker(client, gatewayBase), aiChecker: gatewayAiChecker(client, gatewayBase, language: () => 'en'))
        : const CheckPipeline();

    var aiMissing = 0, done = 0;
    // One AI call every 7 s stays under the gateway's per-client limit, so refusals don't pass as phone-only answers.
    Future<CheckResult> paced(CheckInput input) async {
      final started = DateTime.now();
      final result = await pipeline.run(input);
      if (result.aiUnavailable) aiMissing++;
      // ignore: avoid_print
      if (++done % 25 == 0) print('progress $done, AI missing $aiMissing');
      final wait = const Duration(seconds: 7) - DateTime.now().difference(started);
      if (!wait.isNegative) await Future<void>.delayed(wait);
      return result;
    }

    final run = combined ? paced : pipeline.run;
    final development = !combined || developmentOnly ? await evaluate(loadSplit(sealed: false), run, aiScan: combined) : null;
    final sealed = combined && developmentOnly ? null : await evaluate(loadSplit(sealed: true), run, aiScan: combined);
    client.close();

    // ignore: avoid_print
    print([
      '# Usisa Quality bar evaluation, ${combined ? 'combined' : 'phone only'}',
      if (combined) 'AI answers missing: $aiMissing of $done',
      if (development != null) development.format('Development split (70%, tune here)', combined: combined),
      if (sealed != null) sealed.format('Sealed split (30%, release targets)', combined: combined),
    ].join('\n\n'));
    if (sealed != null) {
      expect(sealed.misses(combined: combined), isEmpty, reason: 'A missed target on the sealed split blocks the release.');
    }
  }, timeout: const Timeout(Duration(hours: 2)));
}
