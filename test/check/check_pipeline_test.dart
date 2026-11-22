import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/features/check/check.dart';
import 'package:usisa/features/check/gateway_ai_checker.dart';

import '../scan/ai_models_test.dart' show assessment;
import '../scan/gateway_test_helpers.dart';

const harmless = 'Hi Ma, nakauwi na ako. Ingat po kayo!';
const harmlessWithLink = 'Sale ngayon sa tindahan.ph/sale, tingnan mo';
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

    test('a mismatched quote in the gateway answer drops only that reason, not the AI answer', () async {
      final gateway = MockClient((request) async =>
          gatewayHealthResponse(request) ??
          http.Response(
            jsonEncode({
              ...assessment(risk: 'caution'),
              'warningSigns': [
                {'code': 'payment_request', 'evidence': 'Pay the fee'},
                {'code': 'impersonation', 'evidence': 'not in the message'},
              ],
            }),
            200,
          ));
      final r = await check(
        'Pay the fee now',
        aiScan: true,
        aiChecker: gatewayAiChecker(gateway, Uri.parse('https://gateway.test'), language: () => 'en'),
      );
      expect(r.aiUnavailable, isFalse);
      expect(r.verdict, Verdict.beCareful);
      expect(r.reasons, contains('payment_request'));
      expect(r.reasons, isNot(contains('impersonation')));
      expect(r.evidence, ['Pay the fee']);
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

    test('a wallet-branded gaming-credits text with a short link is Dangerous on the phone alone', () async {
      const text = 'GCash: You received P200 Gaming Credits! 09170000000 Active lang ito hanggang 12PM. '
          'Gamitin para manalo ng Jackpot today: https://bit.ly/4abcDEF';
      for (final status in [LinkStatus.unresolved, LinkStatus.clean]) {
        final r = await CheckPipeline(linkChecker: (links) async => [for (final l in links) LinkCheck(l, status)])
            .run(const CheckInput(text, source: CheckSource.message));
        expect(r.verdict, Verdict.dangerous, reason: '$status');
        expect(r.reasons, containsAll(['impersonation', 'gambling_ad']), reason: '$status');
      }
    });

    test('real wallet promos and plain lotto results stay Looks safe', () async {
      for (final text in [
        'GCash: Get P50 cashback when you pay bills this weekend. Details at gcash.com/promos',
        'PCSO Lotto results: Grand Lotto 6/55 jackpot P45M, winning numbers 04-11-23-30-41-52.',
      ]) {
        final r = await CheckPipeline(linkChecker: (links) async => [for (final l in links) LinkCheck(l, LinkStatus.clean)])
            .run(CheckInput(text, source: CheckSource.message));
        expect(r.verdict, Verdict.looksSafe, reason: text);
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

    test('an account threat with a link is Dangerous', () async {
      for (final text in [
        'Your e-wallet will be deactivated today. Verify your account here: wallet-check.top/v',
        'Ang iyong account ay suspendido. I-update agad sa acct-help.icu',
        'Your parcel cannot be delivered. Please confirm your address at parcel-ph.vip/x',
      ]) {
        final r = await check(text);
        expect(r.verdict, Verdict.dangerous, reason: text);
        expect(r.reasons, contains('account_threat'), reason: text);
      }
    });

    test('look-alikes of couriers, telcos, utilities and agencies, and bank names in link paths, are Dangerous', () async {
      for (final text in [
        'Your points expire tonight, convert at meralco-points.click',
        'Pay your fine at lto-gov.top',
        'Track it here: jnt-delivery.shop',
        'Your account needs review: tinyurl.com/OnlineGCashVerify',
      ]) {
        expect((await check(text)).verdict, Verdict.dangerous, reason: text);
      }
    });

    test('an impersonated relative or a wrong-send refund asking for money is Dangerous', () async {
      for (final text in [
        'Ma, ako to, bagong number ko. Pa-send ng 2,000 sa GCash na ito, emergency.',
        'Nagkamali ako ng send ng P1,000 sa account mo. Pakibalik naman po sa number na ito 09171234567.',
        'Ma, bagong number ko to. Pa-send ng 500, wag mo muna sabihin kay papa.',
      ]) {
        final r = await check(text);
        expect(r.verdict, Verdict.dangerous, reason: text);
        expect(r.reasons, contains('impersonation'), reason: text);
      }
      expect((await check('Ma, bagong number ko ito. Tawag ako mamaya.')).verdict, Verdict.looksSafe);
      // Real relatives change numbers and people do mis-send: without secrecy or a new wallet, only Be careful.
      for (final text in [
        'Ma, bagong number ko ito. Pa-load ng 100 pag may time.',
        'Nagkamali ako ng send sayo ng 300 kanina, pakibalik na lang. Salamat!',
      ]) {
        expect((await check(text)).verdict, Verdict.beCareful, reason: text);
      }
    });

    test('easy money and contact-a-stranger hooks are Be careful, Dangerous with a link or a fee', () async {
      final job = await check('Part-time job, daily salary 2000-5000, kahit nasa bahay lang!');
      expect(job.verdict, Verdict.beCareful);
      expect(job.reasons, contains('easy_money'));
      expect((await check('Earn 800 per day watching videos: gain.bid/x')).verdict, Verdict.dangerous);
      expect((await check('Online seller job! Pay a P500 registration fee to start')).verdict, Verdict.dangerous);
      final stranger = await check('I have an urgent matter for you, contact me by email: someone@gmail.com');
      expect(stranger.verdict, Verdict.dangerous);
      expect(stranger.reasons, contains('private_contact'));
    });

    test('a fee for a free gift or a payment outside the shop app is Dangerous', () async {
      expect((await check('Napili ka para sa libreng tablet! Magbayad lang ng P199 shipping fee.')).verdict, Verdict.dangerous);
      expect((await check('Lazada seller ako. Bayad ka na lang sa personal account ko.')).verdict, Verdict.dangerous);
      expect((await check('Checkout in the app only. No payment outside the app.')).verdict, Verdict.looksSafe);
    });

    test('more gambling ads are Be careful; lotto results and app raffles are not', () async {
      for (final text in [
        '100% bonus sa unang deposito! lucky88.xyz',
        'Spin the lucky wheel and win up to 50,000 daily!',
        'Gawing 30k ang 20 pesos mo! Maglaro na sa winbig.site',
      ]) {
        expect((await check(text)).verdict, Verdict.beCareful, reason: text);
      }
      for (final text in [
        'You could win P5,000! Log in to the app to earn a raffle entry.',
        'Walang nanalo ng jackpot sa Grand Lotto ngayong gabi.',
      ]) {
        expect((await check(text)).verdict, Verdict.looksSafe, reason: text);
      }
    });

    test('a winner hook asking for your details or fee is Dangerous, a pickup at the office is not', () async {
      expect((await check('Your number won P500,000! Send your name and address to claim.')).verdict, Verdict.dangerous);
      expect((await check('Nanalo ka sa raffle! Kunin mo yung premyo sa admin office bukas.')).verdict, Verdict.looksSafe);
    });

    test('real bank promos, billers and in-person raffles are never Dangerous', () async {
      for (final text in [
        'BPI: Enjoy 0% installment on gadgets this month. Details at bit.ly/BPI-Promo',
        'Your PLDT account has an unpaid balance of P1,699. Pay via GCash or visit pldthome.com to avoid disconnection.',
        'Congratulations! You are one of the lucky winners of our raffle. Claim your prize at the mall customer service with a valid ID.',
        'Maya: Get P50 cashback when you pay bills. Limited slots! maya.ph/promos',
      ]) {
        expect((await check(text)).verdict, isNot(Verdict.dangerous), reason: text);
      }
      expect((await check('Maya: Get P50 cashback when you pay bills. Limited slots!')).verdict, Verdict.looksSafe);
    });

    test('casino-style giveaways are gambling ads; the same words from real brands are not', () async {
      for (final text in [
        'Mag-recharge ng P100 ngayon at makakuha ng P200! panalo-ph.top',
        'New players get FREE 777 bonus today! lucky-ph.icu',
        'Receive a FREE PHP20 gift when you join! surewin-ph.xyz',
        'Join now and win a brand new motorcycle! Sign up at moto-event.top',
        'Legit 0NLINE CASIN0 dito! Register now.',
      ]) {
        final r = await check(text);
        expect(r.verdict, isNot(anyOf(Verdict.looksSafe, Verdict.couldntCheck)), reason: text);
        expect(r.reasons, contains('gambling_ad'), reason: text);
      }
      for (final text in [
        'Download the GCash app and get P50 when you sign up with code HELLO. gcash.com',
        'Join our Christmas raffle and win a car! Register your receipts at mallpromo.com.ph',
        'Cash in P500 to your Maya wallet and get P20 cashback this weekend.',
        'Get FREE P100 load when you refer a friend to the app! telco-refer.ph',
        'Lotto 6/58 jackpot now at P49 million. Play at any PCSO outlet.',
      ]) {
        expect((await check(text)).reasons, isNot(contains('gambling_ad')), reason: text);
      }
    });

    test('a bank or agency asking you to call or pay a mobile number is Dangerous', () async {
      for (final text in [
        'BPI: A transfer of PHP 9,000 is pending. To cancel, call our officer at 09171112233.',
        'SSS: May multa ka. Bayaran sa GCash 09171112233 para hindi ma-hold ang pension mo.',
      ]) {
        expect((await check(text)).verdict, Verdict.dangerous, reason: text);
      }
      expect(
        (await check('You have received PHP 50.00 of GCash from JU*N D. 09171112233. Ref 123.')).verdict,
        Verdict.looksSafe,
      );
    });

    test('an emergency about a relative with a secret money request is Dangerous', () async {
      final r = await check('Nasa ospital po ang anak niyo. Magpadala ng P8,000 sa number na ito, wag niyo pong sabihin sa iba.');
      expect(r.verdict, Verdict.dangerous);
    });

    test('a page-deletion or failed-delivery threat with a link is Dangerous', () async {
      for (final text in [
        'Your page will be permanently deleted. Submit an appeal at page-appeal-help.com',
        'Hindi namin maihatid ang parcel mo. I-schedule ulit at bayaran ang P30 sa parcel-resched.shop',
      ]) {
        expect((await check(text)).verdict, Verdict.dangerous, reason: text);
      }
    });

    test('a genuine OTP text carrying its code, or a brand app link, is never Dangerous', () async {
      for (final text in [
        'Enter OTP 482913 to complete your purchase at shop-checkout.ph/pay. Never share this code.',
        'Please enter the OTP 908812 to confirm your GCash transaction. gcash.com',
        'Get the GCash app here: gcash.onelink.me/promo and enjoy P50 off your first bills payment.',
      ]) {
        expect((await check(text)).verdict, isNot(Verdict.dangerous), reason: text);
      }
      // An affixed brand name on the same host is still a look-alike.
      expect((await check('Verify now at bdoonlineapp.page.link/login')).verdict, Verdict.dangerous);
    });

    test('a scam warning that mentions an OTP is not an alarm', () async {
      final r = await check('Babala: may nagpapanggap na bangko na humihingi ng OTP. Ito ay scam, huwag sumunod.');
      expect(r.verdict, Verdict.looksSafe);
    });

    test('a relative asking to pay a bill first stays Looks safe', () async {
      expect((await check('Kuya, paki-bayad muna ng tubig gamit GCash, babayaran kita bukas.')).verdict, Verdict.looksSafe);
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

    test('still "Checked on your phone" when no link got a real online answer', () async {
      expect((await check(harmlessWithLink, linkChecker: links(LinkStatus.unresolved))).checkedOnPhone, isTrue);
      expect((await check(harmlessWithLink, linkChecker: links(LinkStatus.opensApp))).checkedOnPhone, isTrue);
      expect((await check(harmlessWithLink, linkChecker: (_) => throw Exception('offline'))).checkedOnPhone, isTrue);
      expect((await check(harmlessWithLink, linkChecker: links(LinkStatus.flagged))).checkedOnPhone, isFalse);
    });
  });
}
