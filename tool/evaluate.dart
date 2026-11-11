import 'dart:convert';
import 'dart:io';

import 'package:usisa/features/scan/scam_analyzer.dart';
import 'package:usisa/features/scan/scan_models.dart';

List<int> counts(Iterable<(bool, bool)> rows) {
  final values = [0, 0, 0, 0]; // TP, FP, FN, TN
  for (final row in rows) {
    values[row.$1
        ? row.$2
              ? 0
              : 2
        : row.$2
        ? 1
        : 3]++;
  }
  return values;
}

String percent(int numerator, int denominator) => denominator == 0
    ? 'n/a'
    : '${(100 * numerator / denominator).toStringAsFixed(1)}%';

void main() {
  if (counts([(true, true), (false, true), (true, false), (false, false)])
          .join(',') !=
      '1,1,1,1') {
    throw StateError('Metric self-check failed');
  }
  final fixtures = (jsonDecode(
    File('test/fixtures/evaluation_messages.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  final analyzer = ScamAnalyzer();
  final results = <(Map<String, dynamic>, RiskLevel)>[];
  final ids = <String>{};
  for (final row in fixtures) {
    if (!ids.add(row['id'] as String) ||
        (row['scam'] != null && row['scam'] is! bool)) {
      throw FormatException('Invalid evaluation fixture');
    }
    results.add((row, analyzer.analyze(ScanInput(row['text'] as String)).risk));
  }
  final output = StringBuffer('''# Local rules evaluation

Frozen rules-v1, evaluated 10 November 2026. These 36 synthetic, manually labeled examples were written after the development tests and were not used to tune rules. This is a small diagnostic set authored by the implementer, not an independently annotated corpus or a real-world accuracy estimate. A caution or high result counts as an alert. Four ambiguous examples are excluded from binary metrics.

| Slice | N | TP | FP | FN | TN | Precision | Recall | False positive rate |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
''');
  for (final slice in [
    'All labeled',
    ...results
        .map((r) => r.$1['language'] as String)
        .where((l) => l != 'Ambiguous')
        .toSet(),
  ]) {
    final rows = results
        .where(
          (r) =>
              r.$1['scam'] != null &&
              (slice == 'All labeled' || r.$1['language'] == slice),
        )
        .toList();
    final c = counts(
      rows.map((r) => (r.$1['scam'] as bool, r.$2 != RiskLevel.low)),
    );
    output.writeln(
      '| $slice | ${rows.length} | ${c.join(' | ')} | ${percent(c[0], c[0] + c[1])} | ${percent(c[0], c[0] + c[2])} | ${percent(c[1], c[1] + c[3])} |',
    );
  }
  output.writeln(
    '\n## Individual outcomes\n\n| ID | Expected | Observed | Category |\n|---|---|---|---|',
  );
  for (final row in results) {
    output.writeln(
      '| ${row.$1['id']} | ${row.$1['scam'] == null
          ? 'Ambiguous'
          : row.$1['scam'] == true
          ? 'Scam'
          : 'Benign'} | ${row.$2.name} | ${row.$1['category']} |',
    );
  }
  output.writeln('''
## Interpretation and release gates

Paraphrased requests and obfuscated characters can evade rules. Ordinary payment requests or urgent notices may raise caution despite being legitimate. Low risk means no configured warning was found, never a verified sender or safe destination. This report does not evaluate live URL reputation or AI.

Do not advertise a detection percentage or enable unrestricted monitoring from this set. Before public release, obtain an independently labeled PH corpus, agree deployment thresholds, review Filipino copy with a speaker, and measure on physical Android devices. OCR transcription and URL recovery need separate image fixtures; the app requires text review before scanning. The optional AI plan should evaluate contextual misses against the same frozen examples without replacing local checks.

Reproduce: `dart run tool/evaluate.dart`. No fixture URL is fetched.
''');
  File('docs/evaluation.md').writeAsStringSync(output.toString());
  stdout.write(output.toString());
}
