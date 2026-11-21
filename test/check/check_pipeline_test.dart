import 'package:flutter_test/flutter_test.dart';
import 'package:usisa/features/check/check.dart';

const harmless = 'Hi Ma, nakauwi na ako. Ingat po kayo!';
const harmlessWithLink = 'Sale ngayon sa shopee.ph/sale, tingnan mo';
const otpWithLink = 'Your account is on hold. Send your OTP at bit.ly/verify-now';
const lookalike = 'Update your details at gcash-verify-ph.xyz';

/// Link checker that gives every link the same status.
LinkChecker links(LinkStatus status) =>
    (found) async => [for (final link in found) LinkCheck(link, status)];

AiChecker ai(AiLevel level, [List<AiSign> signs = const []]) =>
    (_) async => AiAnswer(level, signs);

Future<CheckResult> check(String text, {bool aiScan = false, LinkChecker? linkChecker, AiChecker? aiChecker}) =>
    CheckPipeline(
      linkChecker: linkChecker,
      aiChecker: aiChecker,
    ).run(CheckInput(text, source: CheckSource.message, aiScan: aiScan));

void main() {
  group('rule 1: flagged or shortener-blocked links are Dangerous', () {
    test('a flagged hop is Dangerous even when the AI says low', () async {
      final r = await check(
        harmlessWithLink,
        aiScan: true,
        linkChecker: links(LinkStatus.flagged),
        aiChecker: ai(AiLevel.low),
      );
      expect(r.verdict, Verdict.dangerous);
      expect(r.reasons.first, 'flagged_link');
    });

    test('a shortener-blocked link is Dangerous', () async {
      final r = await check(harmlessWithLink, linkChecker: links(LinkStatus.shortenerBlocked));
      expect(r.verdict, Verdict.dangerous);
      expect(r.reasons.first, 'shortener_blocked');
    });
  });

  group('rule 2: AI scan with an AI answer', () {
    test('AI low / caution / high map to the three verdicts', () async {
      expect((await check(harmless, aiScan: true, aiChecker: ai(AiLevel.low))).verdict, Verdict.looksSafe);
      expect((await check(harmless, aiScan: true, aiChecker: ai(AiLevel.caution))).verdict, Verdict.beCareful);
      expect((await check(harmless, aiScan: true, aiChecker: ai(AiLevel.high))).verdict, Verdict.dangerous);
    });

    test('strong signs raise the AI verdict by one step only', () async {
      // Two strong signs (OTP request with a link, look-alike domain) still only raise low to Be careful.
      final r = await check(
        '$otpWithLink or $lookalike',
        aiScan: true,
        linkChecker: links(LinkStatus.clean),
        aiChecker: ai(AiLevel.low),
      );
      expect(r.verdict, Verdict.beCareful);
      final raised = await check(
        otpWithLink,
        aiScan: true,
        linkChecker: links(LinkStatus.clean),
        aiChecker: ai(AiLevel.caution),
      );
      expect(raised.verdict, Verdict.dangerous);
    });

    test('weak signs only add reasons', () async {
      final r = await check('Reply immediately po', aiScan: true, aiChecker: ai(AiLevel.low));
      expect(r.verdict, Verdict.looksSafe);
      expect(r.reasons, contains('urgency'));
    });

    test('a mismatched AI quote drops only that reason', () async {
      final r = await check(
        'Pay the fee now',
        aiScan: true,
        aiChecker: ai(AiLevel.caution, const [
          AiSign('payment_request', quote: 'Pay the fee'),
          AiSign('impersonation', quote: 'not in the message'),
        ]),
      );
      expect(r.verdict, Verdict.beCareful);
      expect(r.reasons, contains('payment_request'));
      expect(r.reasons, isNot(contains('impersonation')));
    });
  });

  group('rule 3: the phone verdict is final without an AI answer', () {
    test('plain tiles ignore the AI even when it is available', () async {
      final r = await check(harmless, aiChecker: ai(AiLevel.high));
      expect(r.verdict, Verdict.looksSafe);
    });

    test('a strong sign makes a plain check Dangerous', () async {
      expect((await check(otpWithLink)).verdict, Verdict.dangerous);
      expect((await check(lookalike)).verdict, Verdict.dangerous);
      expect((await check('Congrats, you won P50,000! Claim your prize now')).verdict, Verdict.dangerous);
    });

    test('an AI scan whose AI could not answer keeps the phone verdict', () async {
      final r = await check(harmless, aiScan: true, aiChecker: (_) async => null);
      expect(r.verdict, Verdict.looksSafe);
      final failing = await check(otpWithLink, aiScan: true, aiChecker: (_) => throw Exception('busy'));
      expect(failing.verdict, Verdict.dangerous);
    });
  });

  test('rule 4: a gambling ad is at least Be careful', () async {
    final r = await check(
      'FREE 888 bonus credits sa casino!',
      aiScan: true,
      aiChecker: ai(AiLevel.low, const [AiSign('gambling_ad')]),
    );
    expect(r.verdict, Verdict.beCareful);
    expect(r.reasons, contains('gambling_ad'));
  });

  test('rule 5: an app-opening link is Be careful', () async {
    final r = await check(harmlessWithLink, linkChecker: links(LinkStatus.opensApp));
    expect(r.verdict, Verdict.beCareful);
    expect(r.reasons, contains('opens_app'));
  });

  group('rule 6: links that could not be checked', () {
    test('with no warnings, the verdict is Couldn\'t check', () async {
      final r = await check(harmlessWithLink, linkChecker: links(LinkStatus.unresolved));
      expect(r.verdict, Verdict.couldntCheck);
      expect(r.reasons, ['unresolved_link']);
    });

    test('a failed link check counts as could not check', () async {
      final r = await check(harmlessWithLink, linkChecker: (_) => throw Exception('offline'));
      expect(r.verdict, Verdict.couldntCheck);
    });

    test('a warning beats Couldn\'t check', () async {
      final r = await check(otpWithLink, linkChecker: links(LinkStatus.unresolved));
      expect(r.verdict, Verdict.dangerous);
    });
  });

  test('a Check gives at most 3 reasons', () async {
    final r = await check('URGENT: $otpWithLink. $lookalike. You won, claim your prize!');
    expect(r.verdict, Verdict.dangerous);
    expect(r.reasons, hasLength(3));
  });

  group('phone check', () {
    test('dotted words and file names are not links', () async {
      var called = false;
      final r = await check(
        'ok.salamat, sent you report.pdf',
        linkChecker: (found) async {
          called = true;
          return [];
        },
      );
      expect(called, isFalse);
      expect(r.verdict, Verdict.looksSafe);
    });

    test('an official brand domain is not a look-alike', () async {
      final r = await check('Visit bdo.com.ph or www.gcash.com for details');
      expect(r.verdict, Verdict.looksSafe);
    });

    test('an OTP request split across lines with a link is still caught', () async {
      final r = await check('Please send your\nOTP to\nbit.ly/abc');
      expect(r.verdict, Verdict.dangerous);
    });

    test('a genuine OTP notice without a link looks safe', () async {
      final r = await check('Your OTP is 123456. Do not share it with anyone.');
      expect(r.verdict, Verdict.looksSafe);
    });
  });

  group('labels', () {
    test('"Checked on your phone" when no online check ran', () async {
      final r = await check(harmless);
      expect(r.checkedOnPhone, isTrue);
      expect(r.verdict, Verdict.looksSafe);
      expect(r.reasons, ['no_signs']);
    });

    test('not when the link check ran', () async {
      final r = await check(harmlessWithLink, linkChecker: links(LinkStatus.clean));
      expect(r.checkedOnPhone, isFalse);
    });
  });
}
