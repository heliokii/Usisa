import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/check/check.dart';

import '../../tool/evaluation.dart';

LabelledMessage msg(String label, [String id = 'x']) =>
    LabelledMessage(id: id, template: id, label: label, reason: 'r', text: id);

void main() {
  group('labelled test set', () {
    final development = loadSplit(sealed: false);
    final sealed = loadSplit(sealed: true);
    final all = [...development, ...sealed];

    test('has at least 300 distinct messages, each labelled with a reason', () {
      expect(all.length, greaterThanOrEqualTo(300));
      expect(all.map((m) => m.id).toSet().length, all.length);
      expect(all.map((m) => m.text.toLowerCase().replaceAll(RegExp(r'\W'), '')).toSet().length, all.length);
      for (final m in all) {
        expect(labels, contains(m.label), reason: m.id);
        expect(m.reason.trim(), isNotEmpty, reason: m.id);
      }
      for (final label in labels) {
        expect(all.where((m) => m.label == label), isNotEmpty, reason: label);
      }
    });

    test('splits about 70/30 by template, and the sealed files hold exactly the sealed templates', () {
      for (final m in development) {
        expect(isSealedTemplate(m.template), isFalse, reason: m.id);
      }
      for (final m in sealed) {
        expect(isSealedTemplate(m.template), isTrue, reason: m.id);
      }
      expect(sealed.length / all.length, inInclusiveRange(0.25, 0.35));
      for (final label in labels) {
        expect(sealed.where((m) => m.label == label).length, greaterThanOrEqualTo(10), reason: label);
      }
    });

    test('keeps each template to one label', () {
      final byTemplate = <String, String>{};
      for (final m in all) {
        expect(byTemplate.putIfAbsent(m.template, () => m.label), m.label, reason: m.template);
      }
    });

    test('keeps Kaggle-derived rows in their own attributed file', () {
      for (final sealed in [false, true]) {
        final (licence, rows) = readFile(kaggle: true, sealed: sealed);
        expect(licence, contains('CC BY-NC-SA 4.0'));
        expect(licence, contains('bwandowando'));
        expect(rows.every((m) => m.id.startsWith('kaggle-')), isTrue);
        expect(readFile(kaggle: false, sealed: sealed).$2.any((m) => m.id.startsWith('kaggle-')), isFalse);
      }
    });
  });

  group('evaluation report', () {
    test('runs every message through the Check and counts each target', () async {
      final messages = [
        msg(harmlessPromo, 'promo-safe'),
        msg(normal, 'normal-careful'),
        msg(normal, 'normal-dangerous'),
        msg(normal, 'normal-couldnt'),
        msg(scam, 'scam-dangerous'),
        msg(scam, 'scam-careful'),
        msg(scam, 'scam-safe'),
        msg(scam, 'scam-couldnt'),
        msg(gamblingAd, 'gambling-careful'),
        msg(gamblingAd, 'gambling-safe'),
      ];
      const verdicts = {
        'promo-safe': Verdict.looksSafe,
        'normal-careful': Verdict.beCareful,
        'normal-dangerous': Verdict.dangerous,
        'normal-couldnt': Verdict.couldntCheck,
        'scam-dangerous': Verdict.dangerous,
        'scam-careful': Verdict.beCareful,
        'scam-safe': Verdict.looksSafe,
        'scam-couldnt': Verdict.couldntCheck,
        'gambling-careful': Verdict.beCareful,
        'gambling-safe': Verdict.looksSafe,
      };
      final checked = <CheckInput>[];
      final report = await evaluate(messages, (input) async {
        checked.add(input);
        return CheckResult(text: input.text, verdict: verdicts[input.text]!, reasons: const [], checkedOnPhone: true);
      });

      expect(checked.map((i) => i.source).toSet(), {CheckSource.message});
      expect(checked.any((i) => i.aiScan), isFalse);
      expect(report.falseAlarmRate, 0.5); // 2 of 4 harmless
      expect(report.dangerousOnHarmless, 1);
      expect(report.scamsCaught, 0.5); // 2 of 4
      expect(report.scamsDangerous, 0.25);
      expect(report.gamblingCareful, 0.5);
      expect(report.couldntCheck, {normal: 1, scam: 1});
      expect(report.misses(combined: false), hasLength(4)); // 1 Dangerous on harmless is within the phone-alone allowance of 2
      expect(report.misses(combined: true), hasLength(5));
    });

    test('a report meeting every phone-alone target has no misses, but may miss the combined ones', () async {
      final messages = [
        for (var i = 0; i < 20; i++) msg(normal, 'n$i'),
        for (var i = 0; i < 4; i++) msg(scam, 's$i'),
        msg(gamblingAd, 'g'),
      ];
      // 1 false alarm in 20 (5%), scams 3/4 caught and 2/4 Dangerous, the gambling ad Be careful.
      Verdict verdict(String id) => switch (id) {
        'n0' || 'g' || 's2' => Verdict.beCareful,
        's0' || 's1' => Verdict.dangerous,
        _ => Verdict.looksSafe,
      };
      final report = await evaluate(
        messages,
        (input) async => CheckResult(text: input.text, verdict: verdict(input.text), reasons: const [], checkedOnPhone: true),
      );
      expect(report.misses(combined: false), isEmpty);
      expect(report.misses(combined: true), hasLength(2));
    });
  });
}
