import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/scan/scam_analyzer.dart';
import 'package:usisa/features/scan/scan_models.dart';

void main() {
  final analyzer = ScamAnalyzer();
  ScanResult check(String text) => analyzer.analyze(ScanInput(text));

  test('bank impersonation plus OTP disclosure is high', () {
    final result = check(
      'GCash: Your account is suspended. Send your OTP now.',
    );
    expect(result.risk, RiskLevel.high);
    expect(result.findings.map((f) => f.code), contains('codeRequest'));
  });
  test('legitimate OTP reminders are not requests to disclose', () {
    for (final text in [
      'Your BDO OTP is 123456. Never share your OTP with anyone.',
      'GCash: Huwag ibigay ang iyong OTP kahit kanino.',
      'Do not share your password or PIN. Your payment was received.',
      'Salamat sa iyong bayad. Your order is confirmed.',
    ]) {
      expect(check(text).risk, RiskLevel.low, reason: text);
    }
  });
  test('Taglish payment request and pressure is high', () {
    expect(
      check('Magbayad ng processing fee ngayon na para makuha ang premyo.')
          .risk,
      RiskLevel.high,
    );
  });
  test('a brand mention alone is low; urgency alone is caution', () {
    expect(check('Your GCash payment was received.').risk, RiskLevel.low);
    expect(check('Act now, within 10 minutes!').risk, RiskLevel.caution);
  });
  test('original evidence spans survive emoji and combining characters', () {
    const text =
        '🇵🇭 e\u0301 GCash: Send your OTP now or your account will be suspended.';
    for (final finding in check(text).findings) {
      if (finding.start != null) {
        expect(text.substring(finding.start!, finding.end), finding.evidence);
      }
    }
  });
  test('empty and excessive content fail instead of low risk', () {
    expect(() => check('   '), throwsA(isA<ScanException>()));
    expect(check('a' * 10000).risk, RiskLevel.low);
    expect(() => check('a' * 10001), throwsA(isA<ScanException>()));
    expect(check('😀' * 10000).risk, RiskLevel.low);
  });
  test('deceptive host cannot pass an official-domain suffix check', () {
    final result = check('GCash: https://gcash.com.evil.test/verify');
    expect(result.risk, RiskLevel.caution);
    expect(
      result.links.single.findings.map((f) => f.code),
      contains('deceptiveHost'),
    );
  });
  test(
    'HTTPS alone does not verify a message; reputation starts unchecked',
    () {
      final link = check('https://example.test/a').links.single;
      expect(link.reputation, ReputationState.notRequested);
      expect(link.host, 'example.test');
    },
  );
  test('userinfo exposes actual host and is flagged', () {
    final result = check('https://gcash.com@evil.test/path');
    expect(result.links.single.host, 'evil.test');
    expect(result.risk, RiskLevel.caution);
  });
  test(
    'URL extraction preserves trailing punctuation and duplicate occurrences',
    () {
      final result = check(
        'Visit (https://example.test/a), then https://example.test/a.',
      );
      expect(result.links, hasLength(2));
      expect(result.links.first.uri.toString(), 'https://example.test/a');
    },
  );
  test('unsupported and malformed link mode inputs are rejected', () {
    for (final value in [
      'javascript:alert(1)',
      'https://',
      'https://a.test https://b.test',
    ]) {
      expect(
        () => analyzer.analyze(ScanInput(value, source: ScanSource.link)),
        throwsA(isA<ScanException>()),
      );
    }
  });
  test('unassessed malformed links remain visible in text', () {
    final result = check('Use this: https://');
    expect(result.links.single.uri, isNull);
    expect(result.risk, RiskLevel.caution);
  });
  test('limits apply to distinct links and preserve no silent truncation', () {
    expect(
      check(List.generate(10, (i) => 'https://e$i.test').join(' ')).links,
      hasLength(10),
    );
    expect(
      () => check(List.generate(11, (i) => 'https://e$i.test').join(' ')),
      throwsA(isA<ScanException>()),
    );
    expect(
      () => check('https://a.test/${'a' * 2048}'),
      throwsA(isA<ScanException>()),
    );
  });
  test('result serialization retains evidence, source and coverage', () {
    final before = check('BDO: Send your PIN now. https://bit.ly/example');
    final after = ScanResult.fromJson(before.toJson());
    expect(after.text, before.text);
    expect(after.risk, before.risk);
    expect(after.links.single.reputation, ReputationState.notRequested);
  });
}
