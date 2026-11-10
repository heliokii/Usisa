import 'ai_models.dart';

enum ScanSource { text, link, screenshot, sms }

enum RiskLevel { low, caution, high }

enum ReputationState { notRequested, checking, matched, noMatch, unavailable }

const safeBrowsingProvider = 'Google Safe Browsing';

class ScanException implements Exception {
  const ScanException(this.code);
  final String code;
  @override
  String toString() => code;
}

class ScanInput {
  const ScanInput(this.text, {this.source = ScanSource.text});
  final String text;
  final ScanSource source;
}

class Finding {
  const Finding(
    this.code, {
    this.severity = RiskLevel.caution,
    this.evidence = '',
    this.start,
    this.end,
  });
  final String code;
  final RiskLevel severity;
  final String evidence;
  final int? start;
  final int? end;
  Map<String, dynamic> toJson() => {
    'code': code,
    'severity': severity.name,
    'evidence': evidence,
    'start': start,
    'end': end,
  };
  factory Finding.fromJson(Map<String, dynamic> json) => Finding(
    json['code'] as String,
    severity: RiskLevel.values.byName(json['severity'] as String),
    evidence: json['evidence'] as String,
    start: json['start'] as int?,
    end: json['end'] as int?,
  );
}

class LinkResult {
  const LinkResult({
    required this.original,
    required this.uri,
    required this.findings,
    this.reputation = ReputationState.notRequested,
    this.checkedAt,
    this.expiresAt,
    this.threatTypes = const [],
    this.provider,
  });
  final String original;
  final Uri? uri;
  final List<Finding> findings;
  final ReputationState reputation;
  final DateTime? checkedAt;
  final DateTime? expiresAt;
  final List<String> threatTypes;
  final String? provider;
  bool get hasThreatWarning =>
      reputation == ReputationState.matched &&
      (provider != safeBrowsingProvider ||
          currentReputation == ReputationState.matched);
  String get host => uri?.host ?? original;
  bool get schemeAssumed =>
      uri != null &&
      !RegExp(r'^https?://', caseSensitive: false).hasMatch(original);
  DateTime? get reputationDeadline {
    final at = checkedAt;
    if (at == null) return null;
    final ceiling = at.add(const Duration(minutes: 5));
    if (reputation == ReputationState.matched) {
      final expiry = expiresAt;
      return expiry == null
          ? at
          : expiry.isBefore(ceiling)
          ? expiry
          : ceiling;
    }
    return reputation == ReputationState.noMatch ? ceiling : null;
  }

  ReputationState get currentReputation {
    if (reputation != ReputationState.matched &&
        reputation != ReputationState.noMatch) {
      return reputation;
    }
    final now = DateTime.now();
    return checkedAt == null ||
            checkedAt!.isAfter(now) ||
            reputationDeadline == null ||
            !now.isBefore(reputationDeadline!)
        ? ReputationState.unavailable
        : reputation;
  }

  bool get reputationExpired =>
      (reputation == ReputationState.matched ||
          reputation == ReputationState.noMatch) &&
      currentReputation == ReputationState.unavailable;
  LinkResult withReputation(
    ReputationState state, {
    DateTime? at,
    DateTime? until,
    List<String> threats = const [],
    String? provider,
  }) => LinkResult(
    original: original,
    uri: uri,
    findings: findings,
    reputation: state,
    checkedAt: at,
    expiresAt: until,
    threatTypes: threats,
    provider: provider ?? this.provider,
  );
  Map<String, dynamic> toJson() => {
    'original': original,
    'uri': uri?.toString(),
    'findings': findings.map((f) => f.toJson()).toList(),
    'reputation': reputation.name,
    'checkedAt': checkedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'threatTypes': threatTypes,
    'provider': provider,
  };
  factory LinkResult.fromJson(Map<String, dynamic> json) => LinkResult(
    original: json['original'] as String,
    uri: json['uri'] == null ? null : Uri.parse(json['uri'] as String),
    findings: (json['findings'] as List)
        .map((f) => Finding.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList(),
    reputation: ReputationState.values.byName(json['reputation'] as String),
    checkedAt: json['checkedAt'] == null
        ? null
        : DateTime.parse(json['checkedAt'] as String),
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String),
    threatTypes: List<String>.from(json['threatTypes'] as List),
    provider:
        json['provider'] as String? ??
        (['matched', 'noMatch'].contains(json['reputation'])
            ? 'Google Web Risk'
            : null),
  );
}

class ScanResult {
  const ScanResult({
    required this.id,
    required this.text,
    required this.source,
    required this.findings,
    required this.links,
    required this.createdAt,
    this.ruleVersion = 'rules-v1',
    this.aiAssessment,
    this.reviewedForAi = false,
  });
  final String id;
  final String text;
  final ScanSource source;
  final List<Finding> findings;
  final List<LinkResult> links;
  final DateTime createdAt;
  final String ruleVersion;
  final AiAssessment? aiAssessment;
  final bool reviewedForAi;
  RiskLevel get localRisk => findings.any((f) => f.severity == RiskLevel.high)
      ? RiskLevel.high
      : findings.isNotEmpty || links.any((l) => l.findings.isNotEmpty)
      ? RiskLevel.caution
      : RiskLevel.low;
  RiskLevel get risk {
    // Safe Browsing advisories cannot outlive expiry; independent local warnings remain.
    if (links.any((l) => l.hasThreatWarning) ||
        localRisk == RiskLevel.high ||
        aiAssessment?.risk == RiskLevel.high) {
      return RiskLevel.high;
    }
    return localRisk == RiskLevel.caution ||
            aiAssessment?.risk == RiskLevel.caution
        ? RiskLevel.caution
        : RiskLevel.low;
  }

  bool get hasUncheckedLinks => links.any(
    (l) =>
        l.uri == null ||
        l.currentReputation == ReputationState.notRequested ||
        l.currentReputation == ReputationState.unavailable ||
        l.currentReputation == ReputationState.checking,
  );
  ScanResult withLinks(List<LinkResult> value) => ScanResult(
    id: id,
    text: text,
    source: source,
    findings: findings,
    links: value,
    createdAt: createdAt,
    ruleVersion: ruleVersion,
    aiAssessment: aiAssessment,
    reviewedForAi: reviewedForAi,
  );
  ScanResult withAi(AiAssessment value, {bool? reviewed}) => ScanResult(
    id: id,
    text: text,
    source: source,
    findings: findings,
    links: links,
    createdAt: createdAt,
    ruleVersion: ruleVersion,
    aiAssessment: value,
    reviewedForAi: reviewed ?? reviewedForAi,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'source': source.name,
    'findings': findings.map((f) => f.toJson()).toList(),
    'links': links.map((l) => l.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'ruleVersion': ruleVersion,
    if (aiAssessment != null) 'aiAssessment': aiAssessment!.toJson(),
    'reviewedForAi': reviewedForAi,
  };
  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id: json['id'] as String,
    text: json['text'] as String,
    source: ScanSource.values.byName(json['source'] as String),
    findings: (json['findings'] as List)
        .map((f) => Finding.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList(),
    links: (json['links'] as List)
        .map((l) => LinkResult.fromJson(Map<String, dynamic>.from(l as Map)))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    ruleVersion: json['ruleVersion'] as String,
    aiAssessment: json['aiAssessment'] == null
        ? null
        : AiAssessment.fromJson(
            Map<String, dynamic>.from(json['aiAssessment'] as Map),
            text: json['text'] as String,
          ),
    reviewedForAi: json['reviewedForAi'] == true,
  );
}
