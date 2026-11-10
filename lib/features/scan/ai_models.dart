import 'scan_models.dart';

enum AiScanState {
  notRequested,
  checking,
  completed,
  unableToAssess,
  unavailable,
  cancelled,
}

const aiWarningCodes = {
  'credential_request',
  'payment_request',
  'urgency',
  'impersonation',
  'prize',
  'suspicious_link',
  'other',
};
const aiRecommendationCodes = {
  'dont_share_secrets',
  'verify_official_channel',
  'pause_payment',
  'contact_provider_if_shared',
};
const aiModels = {'openai/gpt-oss-120b', 'openai/gpt-oss-20b'};

class ReviewedAiInput {
  const ReviewedAiInput({
    required this.text,
    required this.source,
    required this.responseLanguage,
    required this.inputRevision,
    required this.privacyGeneration,
  });
  final String text;
  final ScanSource source;
  final String responseLanguage;
  final int inputRevision;
  final int privacyGeneration;
}

class AiAssessment {
  const AiAssessment(
    this.state, {
    this.risk,
    this.summary = '',
    this.findings = const [],
    this.recommendationCodes = const [],
    this.modelId,
    this.promptVersion,
    this.checkedAt,
  });
  final AiScanState state;
  final RiskLevel? risk;
  final String summary;
  final List<Finding> findings;
  final List<String> recommendationCodes;
  final String? modelId;
  final String? promptVersion;
  final DateTime? checkedAt;

  Map<String, dynamic> toJson() => {
    'state': state.name,
    'risk': risk?.name,
    'summary': summary,
    'warningSigns': findings
        .map((f) => {'code': f.code, 'evidence': f.evidence})
        .toList(),
    'recommendationCodes': recommendationCodes,
    'modelId': modelId,
    'promptVersion': promptVersion,
    'checkedAt': checkedAt?.toIso8601String(),
  };

  factory AiAssessment.fromJson(
    Map<String, dynamic> json, {
    required String text,
  }) {
    Never invalid() => throw const FormatException('Invalid AI assessment');
    const keys = {
      'state',
      'risk',
      'summary',
      'warningSigns',
      'recommendationCodes',
      'modelId',
      'promptVersion',
      'checkedAt',
    };
    if (json.length != keys.length || !json.keys.every(keys.contains))
      invalid();
    final state = AiScanState.values
        .where((s) => s.name == json['state'])
        .firstOrNull;
    if (state == null) invalid();
    final assessed = state == AiScanState.completed;
    final unknown = state == AiScanState.unableToAssess;
    if (!assessed && !unknown) {
      if (json['risk'] != null ||
          json['summary'] != '' ||
          json['warningSigns'] is! List ||
          (json['warningSigns'] as List).isNotEmpty ||
          json['recommendationCodes'] is! List ||
          (json['recommendationCodes'] as List).isNotEmpty)
        invalid();
      // Pending work is never resumed from retained history.
      return AiAssessment(
        state == AiScanState.checking ? AiScanState.cancelled : state,
      );
    }
    final risk = RiskLevel.values
        .where((r) => r.name == json['risk'])
        .firstOrNull;
    if ((assessed && risk == null) || (unknown && json['risk'] != null))
      invalid();
    final summary = json['summary'];
    final rawSigns = json['warningSigns'];
    final rawAdvice = json['recommendationCodes'];
    final at = json['checkedAt'] is String
        ? DateTime.tryParse(json['checkedAt'] as String)
        : null;
    if (summary is! String ||
        summary.trim().isEmpty ||
        summary.runes.length > 480 ||
        rawSigns is! List ||
        rawSigns.length > 5 ||
        rawAdvice is! List ||
        rawAdvice.length > 4 ||
        at == null ||
        !aiModels.contains(json['modelId']) ||
        json['promptVersion'] != 'ph-scam-v1')
      invalid();
    final signs = <Finding>[];
    for (final sign in rawSigns) {
      if (sign is! Map ||
          sign.length != 2 ||
          !aiWarningCodes.contains(sign['code']) ||
          sign['evidence'] is! String)
        invalid();
      final quote = sign['evidence'] as String;
      if (quote.trim().isEmpty ||
          quote.runes.length > 160 ||
          !text.contains(quote))
        invalid();
      final start = text.indexOf(quote);
      signs.add(
        Finding(
          sign['code'] as String,
          severity: risk ?? RiskLevel.caution,
          evidence: quote,
          start: start,
          end: start + quote.length,
        ),
      );
    }
    if ((risk == RiskLevel.caution || risk == RiskLevel.high) &&
            signs.isEmpty ||
        unknown && signs.isNotEmpty)
      invalid();
    if (!rawAdvice.every(aiRecommendationCodes.contains) ||
        rawAdvice.toSet().length != rawAdvice.length)
      invalid();
    return AiAssessment(
      state,
      risk: risk,
      summary: summary,
      findings: List.unmodifiable(signs),
      recommendationCodes: List<String>.unmodifiable(rawAdvice),
      modelId: json['modelId'] as String,
      promptVersion: json['promptVersion'] as String,
      checkedAt: at,
    );
  }
}
