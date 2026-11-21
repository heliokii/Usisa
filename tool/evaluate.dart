// Quality bar evaluation (#26). Runs under `flutter test` because the Check pipeline imports Flutter packages.
//
// Phone only (every change; fails when a phone-alone target is missed on the sealed split):
//   flutter test --no-pub tool/evaluate.dart
// Combined, with the online link check and AI (by hand before a release and after any prompt change):
//   flutter test --no-pub tool/evaluate.dart --dart-define=USISA_EVAL_AI=true --dart-define=USISA_GATEWAY_URL=https://usisa-gateway.onrender.com
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/gateway_link_checker.dart';
import 'package:usisa/features/scan/ai_models.dart';
import 'package:usisa/features/scan/ai_scan_client.dart';
import 'package:usisa/features/scan/scan_models.dart';

import 'evaluation.dart';

const combined = bool.fromEnvironment('USISA_EVAL_AI');

void main() {
  test(combined ? 'combined evaluation (phone + link check + AI)' : 'phone-only evaluation', () async {
    final client = http.Client();
    final ai = AiScanClient(baseUri: gatewayBase, client: client);
    final pipeline = combined
        ? CheckPipeline(linkChecker: gatewayLinkChecker(client, gatewayBase), aiChecker: (text) => _askAi(ai, text))
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

/// AI scan over the gateway's `POST /v1/ai-scan`; null when the AI couldn't answer.
Future<AiAnswer?> _askAi(AiScanClient client, String text) async {
  final a = await client.check(
    ReviewedAiInput(text: text, source: ScanSource.text, responseLanguage: 'en', inputRevision: 0, privacyGeneration: 0),
  );
  if (a.state != AiScanState.completed || a.risk == null) return null;
  return AiAnswer(AiLevel.values[a.risk!.index], [for (final f in a.findings) AiSign(f.code, quote: f.evidence)]);
}
