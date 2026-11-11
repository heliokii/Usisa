import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/scan/ai_models.dart';
import 'package:usisa/features/scan/scan_models.dart';
import 'package:usisa/features/scan/scam_analyzer.dart';

Map<String, dynamic> assessment({String risk = 'high'}) => {
  'state': risk == 'unknown' ? 'unableToAssess' : 'completed',
  'risk': risk == 'unknown' ? null : risk,
  'summary': aiSummaryCode,
  'warningSigns': risk == 'unknown'
      ? []
      : [
          {'code': 'credential_request', 'evidence': 'Send your OTP'},
        ],
  'recommendationCodes': ['dont_share_secrets', 'verify_official_channel'],
  'modelId': 'openai/gpt-oss-120b',
  'promptVersion': 'ph-scam-v1',
  'checkedAt': DateTime.now().toUtc().toIso8601String(),
};

void main() {
  const text = 'GCash: Send your OTP immediately.';
  test(
    'AI cannot lower local or live reputation risk; can raise local low',
    () {
      final local = ScamAnalyzer().analyze(const ScanInput(text));
      final low = AiAssessment.fromJson(assessment(risk: 'low'), text: text);
      expect(local.withAi(low).risk, RiskLevel.high);
      expect(local.withAi(low).localRisk, RiskLevel.high);
      final benign = ScamAnalyzer().analyze(const ScanInput('Hello'));
      final high = AiAssessment.fromJson({
        ...assessment(),
        'warningSigns': [
          {'code': 'other', 'evidence': 'Hello'},
        ],
      }, text: benign.text);
      expect(benign.localRisk, RiskLevel.low);
      expect(benign.withAi(high).risk, RiskLevel.high);
      final at = DateTime.now().subtract(const Duration(seconds: 1));
      final matched = ScamAnalyzer()
          .analyze(const ScanInput('Hello'))
          .withLinks([
            LinkResult(
              original: 'https://example.test',
              uri: Uri.parse('https://example.test'),
              findings: [],
              reputation: ReputationState.matched,
              provider: safeBrowsingProvider,
              checkedAt: at,
              expiresAt: at.add(const Duration(minutes: 1)),
            ),
          ]);
      expect(matched.withAi(low).risk, RiskLevel.high);
    },
  );
  test('unknown/unavailable add no risk and old history loads without AI', () {
    final local = ScamAnalyzer().analyze(const ScanInput('Hello'));
    final unknown = AiAssessment.fromJson(
      assessment(risk: 'unknown'),
      text: local.text,
    );
    expect(unknown.risk, isNull);
    expect(local.withAi(unknown).risk, RiskLevel.low);
    expect(
      local.withAi(const AiAssessment(AiScanState.unavailable)).risk,
      RiskLevel.low,
    );
    expect(ScanResult.fromJson(local.toJson()).aiAssessment, isNull);
  });
  test('evidence, codes, states and all output sizes are validated', () {
    for (final patch in <Map<String, dynamic>>[
      {
        'warningSigns': [
          {'code': 'credential_request', 'evidence': 'invented'},
        ],
      },
      {
        'warningSigns': [
          {'code': 'unknown_code', 'evidence': 'Send your OTP'},
        ],
      },
      {'warningSigns': []},
      {
        'recommendationCodes': ['call_12345'],
      },
      {'summary': 'x' * 481},
      {'unexpected': true},
      {'state': 'unableToAssess'},
      {'modelId': 'client-selected'},
    ]) {
      expect(
        () => AiAssessment.fromJson({...assessment(), ...patch}, text: text),
        throwsFormatException,
      );
    }
  });
  test('AI roundtrip preserves model and quote, link updates preserve AI', () {
    final local = ScamAnalyzer().analyze(const ScanInput(text));
    final ai = AiAssessment.fromJson(assessment(), text: text);
    final result = ScanResult.fromJson(local.withAi(ai).withLinks([]).toJson());
    expect(result.aiAssessment?.modelId, 'openai/gpt-oss-120b');
    expect(result.aiAssessment?.findings.single.evidence, 'Send your OTP');
  });
  test(
    'legacy retained prose is discarded without deleting local or AI evidence',
    () {
      final local = ScamAnalyzer().analyze(const ScanInput(text));
      final json = local.toJson()
        ..['aiAssessment'] = {
          ...assessment(),
          'summary': 'Call 09171234567 at https://invented.test',
        };
      final restored = ScanResult.fromJson(json);
      expect(restored.id, local.id);
      expect(restored.aiAssessment?.summary, aiSummaryCode);
      expect(restored.aiAssessment?.findings.single.evidence, 'Send your OTP');
    },
  );
}
