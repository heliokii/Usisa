// The labelled test set (#26) and the Quality bar metrics, shared by tool/evaluate.dart and its tests.
import 'dart:convert';
import 'dart:io';

import 'package:usisa/features/check/check.dart';

const scam = 'scam', gamblingAd = 'gambling_ad', harmlessPromo = 'harmless_promo', normal = 'normal';
const labels = [scam, gamblingAd, harmlessPromo, normal];

class LabelledMessage {
  const LabelledMessage({
    required this.id,
    required this.template,
    required this.label,
    required this.reason,
    required this.text,
  });
  final String id;

  /// Messages from the same template (one campaign, reworded) always land in the same split.
  final String template;
  final String label;
  final String reason;
  final String text;
}

const _dir = 'test/fixtures/evaluation';

/// A template is sealed when its FNV-1a hash ends in 0-2, so the 30% split never moves when rows are added.
bool isSealedTemplate(String template) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(template)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash % 10 < 3;
}

/// One fixture file: its licence text and its messages.
(String, List<LabelledMessage>) readFile({required bool kaggle, required bool sealed}) {
  final name = '${kaggle ? 'kaggle_' : ''}${sealed ? 'sealed' : 'development'}.json';
  final json = jsonDecode(File('$_dir/$name').readAsStringSync()) as Map<String, dynamic>;
  return (
    json['licence'] as String,
    [
      for (final m in (json['messages'] as List).cast<Map<String, dynamic>>())
        LabelledMessage(
          id: m['id'] as String,
          template: m['template'] as String,
          label: m['label'] as String,
          reason: m['reason'] as String,
          text: m['text'] as String,
        ),
    ],
  );
}

List<LabelledMessage> loadSplit({required bool sealed}) => [
  ...readFile(kaggle: false, sealed: sealed).$2,
  ...readFile(kaggle: true, sealed: sealed).$2,
];

class Report {
  Report(this.results);
  final List<(LabelledMessage, Verdict)> results;

  Iterable<Verdict> _of(Set<String> wanted) => results.where((r) => wanted.contains(r.$1.label)).map((r) => r.$2);
  double _share(Set<String> wanted, bool Function(Verdict) hit) {
    final verdicts = _of(wanted).toList();
    return verdicts.isEmpty ? 0 : verdicts.where(hit).length / verdicts.length;
  }

  static bool _alarm(Verdict v) => v == Verdict.beCareful || v == Verdict.dangerous;

  /// Harmless promo + Normal given Be careful or Dangerous. Couldn't check is not an alarm.
  double get falseAlarmRate => _share({harmlessPromo, normal}, _alarm);
  int get dangerousOnHarmless => _of({harmlessPromo, normal}).where((v) => v == Verdict.dangerous).length;
  double get scamsCaught => _share({scam}, _alarm);
  double get scamsDangerous => _share({scam}, (v) => v == Verdict.dangerous);
  double get gamblingCareful => _share({gamblingAd}, _alarm);

  /// Couldn't check counts per label, reported separately from the targets.
  Map<String, int> get couldntCheck => {
    for (final label in labels)
      if (_of({label}).where((v) => v == Verdict.couldntCheck).isNotEmpty)
        label: _of({label}).where((v) => v == Verdict.couldntCheck).length,
  };

  /// The Quality bar targets this report misses: phone alone, or combined (phone + link check + AI).
  List<String> misses({required bool combined}) => [
    if (falseAlarmRate > 0.05) 'false alarms on harmless > 5%',
    if (dangerousOnHarmless > 0) 'Dangerous on harmless > 0',
    if (scamsCaught < (combined ? 0.9 : 0.75)) 'scams caught < ${combined ? 90 : 75}%',
    if (scamsDangerous < (combined ? 0.7 : 0.5)) 'scams Dangerous < ${combined ? 70 : 50}%',
    if (gamblingCareful < 0.9) 'gambling ads Be careful+ < 90%',
  ];

  String format(String title, {required bool combined}) {
    String pct(double v) => '${(100 * v).toStringAsFixed(1)}%';
    int n(Set<String> l) => _of(l).length;
    final missed = misses(combined: combined);
    return [
      '## $title (${results.length} messages)',
      'False alarms on Harmless promo + Normal: ${pct(falseAlarmRate)} of ${n({harmlessPromo, normal})} (target <= 5%)',
      'Dangerous on Harmless promo + Normal: $dangerousOnHarmless (target 0)',
      'Scams caught: ${pct(scamsCaught)} of ${n({scam})} (target >= ${combined ? 90 : 75}%)',
      'Scams Dangerous: ${pct(scamsDangerous)} (target >= ${combined ? 70 : 50}%)',
      'Gambling ads Be careful or above: ${pct(gamblingCareful)} of ${n({gamblingAd})} (target >= 90%)',
      "Couldn't check (reported separately): ${couldntCheck.isEmpty ? 'none' : couldntCheck}",
      missed.isEmpty ? 'All targets met.' : 'MISSED: ${missed.join('; ')}',
    ].join('\n');
  }
}

/// Runs every message through the Check pipeline seam, as Scan a message (or AI scan when [aiScan]).
Future<Report> evaluate(List<LabelledMessage> messages, RunCheck run, {bool aiScan = false}) async => Report([
  for (final m in messages) (m, (await run(CheckInput(m.text, source: CheckSource.message, aiScan: aiScan))).verdict),
]);
