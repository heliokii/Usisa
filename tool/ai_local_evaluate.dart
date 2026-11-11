import 'dart:convert';
import 'dart:io';

import 'package:usisa/features/scan/scam_analyzer.dart';
import 'package:usisa/features/scan/scan_models.dart';

void main() {
  final rows = (jsonDecode(
    File('test/fixtures/ai_messages.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  final ids = <String>{};
  final result = <String, String>{};
  for (final row in rows) {
    if (!ids.add(row['id'] as String) ||
        !['development', 'held_out'].contains(row['split']) ||
        row['scam'] != null && row['scam'] is! bool) {
      throw const FormatException('Invalid synthetic fixture');
    }
    result[row['id'] as String] = ScamAnalyzer()
        .analyze(ScanInput(row['text'] as String))
        .localRisk
        .name;
  }
  if (result.length != rows.length) throw StateError('Missing local outcomes');
  Directory('.verification').createSync(recursive: true);
  File('.verification/ai-local.json').writeAsStringSync(jsonEncode(result));
  stdout.writeln(
    '${result.length} local synthetic outcomes; no network requests.',
  );
}
