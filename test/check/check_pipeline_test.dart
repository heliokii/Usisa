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
    (_, _) async => AiAnswer(level, signs);

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
      final r = await check(harmless, aiScan: true, aiChecker: (_, _) async => null);
      expect(r.verdict, Verdict.looksSafe);
      final failing = await check(otpWithLink, aiScan: true, aiChecker: (_, _) => throw Exception('busy'));
      expect(failing.verdict, Verdict.dangerous);
    });

    test('an AI scan whose AI could not answer says so', () async {
      final r = await check(harmless, aiScan: true, aiChecker: (_, _) async => null);
      expect(r.aiUnavailable, isTrue);
      expect(r.checkedOnPhone, isTrue);
      expect((await check(harmless, aiScan: true, aiChecker: ai(AiLevel.low))).aiUnavailable, isFalse);
      expect((await check(harmless, aiChecker: (_, _) async => null)).aiUnavailable, isFalse);
    });
  });

  group('AI scan', () {
    test("the AI sees each link's real destination and redirect steps", () async {
      List<LinkCheck>? seen;
      await check(
        otpWithLink,
        aiScan: true,
        linkChecker: (found) async => [
          for (final l in found)
            LinkCheck(l, LinkStatus.clean, destination: 'https://gcash-verify.xyz/', hops: const ['https://gcash-verify.xyz/']),
        ],
        aiChecker: (text, links) async {
          seen = links;
          return const AiAnswer(AiLevel.high);
        },
      );
      expect(seen!.single.destination, 'https://gcash-verify.xyz/');
      expect(seen!.single.hops, ['https://gcash-verify.xyz/']);
    });

    test("the AI's quoted words are kept as evidence, mismatched ones dropped", () async {
      final r = await check(
        'Pay the fee now',
        aiScan: true,
        aiChecker: ai(AiLevel.caution, const [
          AiSign('payment_request', quote: 'Pay the fee'),
          AiSign('impersonation', quote: 'not in the message'),
        ]),
      );
      expect(r.evidence, ['Pay the fee']);
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

    test("with online checks declined, a link the phone can't judge is Couldn't check", () async {
      final r = await check(harmlessWithLink);
      expect(r.verdict, Verdict.couldntCheck);
      expect(r.reasons, ['unresolved_link']);
      expect(r.checkedOnPhone, isTrue);
    });

    test('a warning beats Couldn\'t check', () async {
      final r = await check(otpWithLink, linkChecker: links(LinkStatus.unresolved));
      expect(r.verdict, Verdict.dangerous);
    });
  });

  group('Check a link', () {
    Future<CheckResult> link(String text, {LinkChecker? linkChecker}) =>
        CheckPipeline(linkChecker: linkChecker).run(CheckInput(text, source: CheckSource.link));

    test('a clean link Looks safe and shows its real destination', () async {
      final r = await link(
        'bit.ly/shopee-sale',
        linkChecker: (found) async => [for (final l in found) LinkCheck(l, LinkStatus.clean, destination: 'https://shopee.ph/sale')],
      );
      expect(r.verdict, Verdict.looksSafe);
      expect(r.destinations, ['https://shopee.ph/sale']);
      expect(r.checkedOnPhone, isFalse);
    });

    test('an intent: link is Be careful without asking the gateway', () async {
      var asked = false;
      final r = await link(
        'intent://open#Intent;package=com.fake.wallet;end',
        linkChecker: (found) async {
          asked = true;
          return [];
        },
      );
      expect(asked, isFalse);
      expect(r.verdict, Verdict.beCareful);
      expect(r.reasons, contains('opens_app'));
    });

    test('an intent: link is Be careful even with online checks off', () async {
      final r = await link('intent://open#Intent;package=com.fake.wallet;end');
      expect(r.verdict, Verdict.beCareful);
      expect(r.checkedOnPhone, isTrue);
    });

    test('a link the phone cannot spot is still checked online, never passed as safe', () async {
      final r = await link('weird-host.example', linkChecker: links(LinkStatus.unresolved));
      expect(r.verdict, Verdict.couldntCheck);
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

    test('a genuine bank OTP notice with its official link looks safe', () async {
      final r = await check(
        'BDO: Your One-Time PIN is 482913. Never share your OTP with anyone. Report fraud at www.bdo.com.ph',
      );
      expect(r.verdict, Verdict.looksSafe);
      expect(r.reasons, isNot(contains('otp_with_link')));
    });

    test('a family money request stays Looks safe, with the request as a reason', () async {
      for (final text in [
        'Hi Ma, pa-send naman ng pera pang tuition ko. Salamat po!',
        'Kuya pa load naman 50 sa globe, wala na ako load',
        'Nay padala po ng 500 sa gcash ko, pamasahe lang',
      ]) {
        final r = await check(text);
        expect(r.verdict, Verdict.looksSafe, reason: text);
        expect(r.reasons, contains('family_money'), reason: text);
      }
    });

    test('harmless promos look safe', () async {
      for (final text in [
        'Shopee 11.11 Big Sale! Up to 90% off + free shipping vouchers. Shop now at shopee.ph',
        'GoSURF50: 2GB data: valid for 3 days. Text GO50 to 8080. Promo ends tonight!',
        'Smart Giga Promo: Register to GIGA99 for 16GB. Limited time only.',
      ]) {
        // Links checked clean online, so only the phone check decides.
        final r = await check(text, linkChecker: links(LinkStatus.clean));
        expect(r.verdict, Verdict.looksSafe, reason: text);
        expect(r.reasons, ['harmless_promo'], reason: text);
      }
    });

    test('"data:" in a promo is not a link', () async {
      var called = false;
      await check('GoSURF50: 2GB data: valid for 3 days.', linkChecker: (found) async {
        called = true;
        return [];
      });
      expect(called, isFalse);
    });

    test('a gambling ad is Be careful, with a reason', () async {
      for (final text in [
        'Claim the BARAHA B0NUS 888 now! Register at pinas77.life, deposit via gcash',
        'JILI GAMES LIBRENG 1088P! Sabong at slots, 100% deposit bonus sa unang taya',
        'FREE 200 credits sa online casino, no deposit needed. Play now!',
      ]) {
        final r = await check(text);
        expect(r.verdict, Verdict.beCareful, reason: text);
        expect(r.reasons, contains('gambling_ad'), reason: text);
      }
    });

    test('a locally detected gambling ad is at least Be careful even when the AI says low', () async {
      final r = await check(
        'Online casino: 100% deposit bonus, slots and baccarat',
        aiScan: true,
        aiChecker: ai(AiLevel.low),
      );
      expect(r.verdict, Verdict.beCareful);
      expect(r.reasons, contains('gambling_ad'));
    });

    test('a gambling ad asking for an OTP is Dangerous', () async {
      final noLink = await check('Casino bonus 500! Para ma-claim, i-send ang OTP na natanggap mo');
      expect(noLink.verdict, Verdict.dangerous);
      final withLink = await check('Casino bonus 500! Login at win777.xyz and enter your OTP to claim');
      expect(withLink.verdict, Verdict.dangerous);
    });

    test('a prize-claim hook is Dangerous', () async {
      for (final text in [
        'Congratulations! You have won P25,000 from GCash raffle. Claim at gcash-promo.top',
        'Nanalo ka ng P10,000! I-claim ang premyo mo, magbayad lang ng processing fee',
        'You have won the prize 999P to enter ccb8.xyz',
      ]) {
        final r = await check(text);
        expect(r.verdict, Verdict.dangerous, reason: text);
        expect(r.reasons, contains('prize_claim'), reason: text);
      }
    });

    test('a plain lotto result looks safe', () async {
      final r = await check(
        'PCSO Lotto 6/42 result 11/20/2026: 05-12-19-23-31-40. Jackpot prize P5,940,000.00. No winner.',
      );
      expect(r.verdict, Verdict.looksSafe);
    });

    test('a look-alike brand domain is Dangerous; official subdomains are not', () async {
      for (final text in [
        'Your account is on hold, verify at onlinebdo-banking.online',
        'Visit bdo.com.ph.secure-login.info to keep your account',
        'Update now: gcash.com-verify.ph',
      ]) {
        final r = await check(text);
        expect(r.verdict, Verdict.dangerous, reason: text);
        expect(r.reasons, contains('lookalike_domain'), reason: text);
      }
      for (final text in [
        'Log in at online.bdo.com.ph',
        'See m.gcash.com/help',
        'Check your contributions at member.sss.gov.ph',
        'Read the news at classic.com and bpimonitor.org',
      ]) {
        final r = await check(text, linkChecker: links(LinkStatus.clean));
        expect(r.verdict, Verdict.looksSafe, reason: text);
      }
    });

    test('a brand name hidden before "@" in a link is a look-alike', () async {
      final r = await check('BDO: visit https://bdo.com.ph@verification.example to restore access.');
      expect(r.verdict, Verdict.dangerous);
      expect(r.reasons, contains('lookalike_domain'));
    });

    test('a fee to release money is Be careful; with a brand it is Dangerous', () async {
      final r = await check('Your package is on hold. Pay the release fee to receive it.');
      expect(r.verdict, Verdict.beCareful);
      expect(r.reasons, contains('payment_request'));
      expect((await check('BIR refund ready na! Pay the processing fee para ma-release.')).verdict, Verdict.dangerous);
    });

    test('an OTP request split across lines is caught', () async {
      final r = await check('GCash Advisory:\nPlease send\nyour\nOTP\nimmediately to avoid suspension');
      expect(r.verdict, Verdict.dangerous);
      expect(r.reasons, contains('credential_request'));
    });

    test('an OTP request alone is Be careful; with a brand or urgency it is Dangerous', () async {
      expect((await check('Pakisend po yung OTP na dumating sa phone mo')).verdict, Verdict.beCareful);
      expect((await check('GCash: Send your OTP now.')).verdict, Verdict.dangerous);
    });

    test('Unicode tricks do not hide an OTP request with a link', () async {
      // Zero-width spaces, full-width letters and a Cyrillic "о" in OTP.
      for (final text in ['Send your O​T​P at bit.ly/x1', 'Send your ＯＴＰ at bit.ly/x1', 'Send your ОTP at bit.ly/x1']) {
        expect((await check(text)).verdict, Verdict.dangerous, reason: text);
      }
    });

    test('weak signs alone never change a plain verdict', () async {
      final r = await check('Urgent po! Your BDO statement is ready, tawagan mo ako agad');
      expect(r.verdict, Verdict.looksSafe);
      expect(r.reasons, containsAll(['urgency', 'brand_mention']));
    });

    test('links are found with schemes, www and known endings, and file names are skipped', () async {
      List<String>? seen;
      await check(
        'See https://example.org/a, www.foo.net, pay.gcash-help.xyz/login and photo.jpg or notes.txt or ok.po',
        linkChecker: (found) async {
          seen = found;
          return [for (final l in found) LinkCheck(l, LinkStatus.clean)];
        },
      );
      expect(seen, ['https://example.org/a', 'www.foo.net', 'pay.gcash-help.xyz/login']);
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
