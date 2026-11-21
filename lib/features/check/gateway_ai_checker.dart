import 'package:http/http.dart' as http;

import '../scan/ai_models.dart';
import '../scan/ai_scan_client.dart';
import '../scan/scan_models.dart';
import 'check.dart';

/// The AI over the gateway's `POST /v1/ai-scan`, given what the link check saw of each link.
/// Any failure, or an AI that couldn't assess, is no answer (null), never a guess.
AiChecker gatewayAiChecker(http.Client client, Uri base, {required String Function() language}) =>
    (text, links) async {
      bool fits(String s) => s.isNotEmpty && s.length <= 2048;
      final assessment = await AiScanClient(baseUri: base, client: client).check(
        ReviewedAiInput(
          text: text,
          source: ScanSource.text,
          responseLanguage: language(),
          inputRevision: 0,
          privacyGeneration: 0,
          // The gateway accepts at most 5 links of 8 hops each.
          links: [
            for (final l in links.where((l) => fits(l.link)).take(5))
              {
                'url': l.link,
                'destination': l.destination != null && fits(l.destination!) ? l.destination : null,
                'hops': l.hops.where(fits).take(8).toList(),
              },
          ],
        ),
      );
      if (assessment.state != AiScanState.completed) return null;
      return AiAnswer(AiLevel.values.byName(assessment.risk!.name), [
        for (final f in assessment.findings) AiSign(f.code, quote: f.evidence),
      ]);
    };
