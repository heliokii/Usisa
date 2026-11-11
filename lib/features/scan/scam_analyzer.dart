import 'dart:math';

import 'scan_models.dart';
import 'url_checker.dart';

class ScamAnalyzer {
  ScamAnalyzer({UrlChecker? urlChecker}) : _urls = urlChecker ?? UrlChecker();
  final UrlChecker _urls;
  static final _rules = <String, RegExp>{
    'codeRequest': RegExp(
      r'\b(?:send|share|provide|enter|give|submit|ibigay|i-send|isend|ipadala|ilagay|ibahagi)\b[^.!?\n]{0,65}\b(?:otp|one.time (?:pin|password)|password|pin|security code|verification code)\b',
      caseSensitive: false,
    ),
    'paymentRequest': RegExp(
      r'\b(?:send|pay|transfer|deposit|magbayad|magpadala|bayaran|i-transfer)\b[^.!?\n]{0,60}\b(?:money|fee|payment|deposit|pesos|php|pera|bayad|processing|shipping|delivery)\b',
      caseSensitive: false,
    ),
    'urgency': RegExp(
      r'\b(?:act now|immediately|urgent|within \d+ (?:minute|hour)s?|ngayon na|agad|suspended|suspendido|blocked|deactivated|mawawala|masususpinde)\b',
      caseSensitive: false,
    ),
    'prize': RegExp(
      r'\b(?:you (?:have )?won|claim your prize|cash prize|nanalo ka|premyo|lucky winner)\b',
      caseSensitive: false,
    ),
    'advanceFee': RegExp(
      r'\b(?:processing fee|release fee|advance payment|bayad muna|pay first)\b',
      caseSensitive: false,
    ),
  };
  static final _brand = RegExp(
    r'\b(?:gcash|maya|paymaya|bdo|bpi|landbank|metrobank|unionbank|sss|philhealth|pag-?ibig|bir|government|bangko)\b',
    caseSensitive: false,
  );
  static final _negation = RegExp(
    r"\b(?:never|do not|don.t|huwag|wag|not to|avoid)\b[^.!?\n]{0,45}$",
    caseSensitive: false,
  );

  ScanResult analyze(ScanInput input) {
    final text = input.text;
    if (text.trim().isEmpty) {
      throw const ScanException('emptyInput');
    }
    if (text.runes.length > 10000) {
      throw const ScanException('textTooLong');
    }
    final links = _urls.extract(text);
    if (input.source == ScanSource.link &&
        (links.length != 1 ||
            links.single.uri == null ||
            links.single.original != text.trim())) {
      throw const ScanException('invalidUrl');
    }
    final found = <Finding>[];
    for (final entry in _rules.entries) {
      for (final match in entry.value.allMatches(text)) {
        final prefix = text.substring(max(0, match.start - 60), match.start);
        if (_negation.hasMatch(prefix)) {
          continue;
        }
        found.add(
          Finding(
            entry.key,
            evidence: match.group(0)!,
            start: match.start,
            end: match.end,
          ),
        );
        break;
      }
    }
    final sensitive = found.any(
      (f) => f.code == 'codeRequest' || f.code == 'paymentRequest',
    );
    final pressure = found.any((f) => f.code == 'urgency');
    final high = sensitive && (pressure || _brand.hasMatch(text));
    final findings = found
        .map(
          (f) => Finding(
            f.code,
            severity:
                high && (f.code == 'codeRequest' || f.code == 'paymentRequest')
                ? RiskLevel.high
                : f.severity,
            evidence: f.evidence,
            start: f.start,
            end: f.end,
          ),
        )
        .toList();
    final now = DateTime.now();
    final random = Random.secure().nextInt(0x100000000).toRadixString(16);
    return ScanResult(
      id: '${now.microsecondsSinceEpoch}-$random',
      text: text,
      source: input.source,
      findings: findings,
      links: links,
      createdAt: now,
    );
  }
}
