// Pure Dart on purpose: the background SMS entry point runs this without any UI.
import 'dart:math' show max;

import 'check.dart' show Verdict;

enum SignStrength { strong, weak }

/// A warning sign the phone found, by reason code.
class Sign {
  const Sign(this.code, this.strength);
  final String code;
  final SignStrength strength;
}

class PhoneCheck {
  const PhoneCheck(this.verdict, this.signs, this.links, {this.harmlessPromo = false});
  final Verdict verdict;
  final List<Sign> signs;
  final List<String> links;

  /// Ordinary advertising (GLOSSARY.md "Harmless promo"); its verdict stays Looks safe.
  final bool harmlessPromo;
}

/// Official domains of brands scammers copy, keyed by the brand word a look-alike would use.
/// Carried over from the old url_checker (references reviewed 2026-11-10).
const officialDomains = {
  'gcash': ['gcash.com'],
  'maya': ['maya.ph', 'mayabank.ph', 'paymaya.com'],
  'paymaya': ['paymaya.com', 'maya.ph'],
  'bdo': ['bdo.com.ph', 'bdonetworkbank.com.ph'],
  'bpi': ['bpi.com.ph'],
  'landbank': ['landbank.com'],
  'metrobank': ['metrobank.com.ph'],
  'sss': ['sss.gov.ph'],
  'philhealth': ['philhealth.gov.ph'],
  'pagibig': ['pagibigfund.gov.ph'],
  'unionbank': ['unionbankph.com'],
  'rcbc': ['rcbc.com'],
  'pnb': ['pnb.com.ph'],
  'gsis': ['gsis.gov.ph'],
  'bir': ['bir.gov.ph'],
  'lto': ['lto.gov.ph'],
  'dict': ['dict.gov.ph'],
  'dswd': ['dswd.gov.ph'],
  'phlpost': ['phlpost.gov.ph'],
  'jnt': ['jtexpress.ph'],
  'lbc': ['lbcexpress.com'],
  'shopee': ['shopee.ph', 'shp.ee'],
  'lazada': ['lazada.com.ph'],
  'globe': ['globe.com.ph'],
  'meralco': ['meralco.com.ph'],
  'easytrip': ['easytrip.ph'],
  'facebook': ['facebook.com', 'fb.com', 'fb.me'],
  'fb': ['facebook.com', 'fb.com', 'fb.me'],
};

// Banks, e-wallets and agencies: their name in a link's path ("bit.ly/OnlineBDOVerify") is also a look-alike.
const _moneyBrands = {'gcash', 'maya', 'paymaya', 'bdo', 'bpi', 'landbank', 'metrobank', 'sss', 'philhealth', 'pagibig', 'unionbank'};

/// Known link shorteners, carried over from the old url_checker.
const shorteners = ['bit.ly', 'tinyurl.com', 't.co', 'shorturl.at', 'rb.gy', 'cutt.ly'];

// Second-level suffixes, so "bdo.com.ph" is the registrable domain of "online.bdo.com.ph".
const _twoLevelSuffixes = {'com.ph', 'net.ph', 'org.ph', 'gov.ph', 'edu.ph', 'co.uk', 'com.sg', 'com.my'};

// Words scammers glue onto a brand ("onlinebdo", "gcashph").
const _brandAffixes = {
  'online', 'my', 'secure', 'login', 'verify', 'ph', 'app', 'bank', 'banking', 'help', 'support', //
  'update', 'account', 'e', 'web', 'portal', 'official', 'promo', 'rewards',
  'updates', 'verification', 'security', 'mobile', 'confirm', 'center', 'appeal', 'points', 'refund', 'track', //
  'delivery', 'pay', 'payment', 'rfid', 'gov', 'alert', 'service', 'care', 'reward', 'cash', 'unlock',
};

// Endings a bare "word.word" must have to count as a link, so "ok.salamat" and "report.pdf" don't.
const _tlds =
    'com|net|org|info|biz|ph|gov|edu|xyz|top|online|site|club|life|live|pw|vip|win|bet|casino|games|fun|icu|'
    'shop|store|click|link|app|io|ly|me|cc|co|tk|ml|ga|cf|gq|ws|gg|cn|ru|us|uk|asia|tv|sg|cloud|today|world|'
    'space|website|tech|buzz|monster|cyou|sbs|bond|lol|page|dev|at|gy|ink|xin|work|support|help|services|'
    'bid|is|so|ee|ai|la|si|lc|sh|ms|st|fm|in|eu|rocks|pub|gs';

final _link = RegExp(
  '${r'''\b[a-z][a-z0-9+.-]*://[^\s<>"']+'''}'
  '${r'''|\bwww\.[^\s<>"']+'''}'
  '${r'''|(?<![\w@.-])(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:'''}$_tlds'
  '${r''')(?![\w-])(?::\d{1,5})?(?:[/?#][^\s<>"']*)?'''}',
  caseSensitive: false,
);

const _secret =
    r'(?:otp|one ?time (?:pin|password|passcode)|password|passcode|m?pin|security code|verification code|'
    r'login code|\d-digit code)';
const _askVerb =
    r'(?:send|share|provide|enter|give|submit|reply(?: with| mo)?|type|input|forward|relay|i-?send|pa-?send|pa-?forward|'
    r'pakisend|ipadala|ibigay|ilagay|i-?type|i-?reply|ibahagi|sabihin|i-?forward)';
final _secretRequest = RegExp('\\b$_askVerb\\b.{0,60}?\\b$_secret\\b');
final _codeDelivery = RegExp(
  '\\b$_secret\\b[^.!?]{0,25}?\\b\\d{4,8}\\b|\\b\\d{4,8}\\b[^.!?]{0,25}?\\b$_secret\\b',
);
final _negation = RegExp(r"\b(?:never|do not|don'?t|huwag|wag|hindi|not to|avoid|no|no one|nobody|walang)\b");

/// A public scam warning ("Babala ... ito ay scam"): the requests it describes are not asked of the reader.
final _scamWarning = RegExp(
  r'\bhuwag (?:pong )?maniwala\b|\b(?:babala|beware|warning|paalala|mag-?ingat)\b.{0,120}\bscam|\bscam\b.{0,60}\b(?:huwag|never|do not)\b',
);

final _win = RegExp(
  r"\b(?:you(?:'ve| have)? won|you are (?:our |the |a )?(?:lucky )?winner|nanalo ka|panalo ka|napili (?:ka|kayo)|"
  r'(?:kayo|ikaw) ay napili|congratulations?\W+(?:you|your|winner|ikaw)|(?:number|sim\W*|account) (?:has |had )?won|'
  r'been awarded|(?:one of )?(?:the |our )?lucky winners? of|masuwerteng nanal|eligible for (?:a )?free|'
  r'been selected (?:as|to receive)|beneficiary|free money|incoming (?:transfer|fund)|cash deposit of|tax refund|'
  r'free \d{2,}\b(?! ?(?:gb|mb|minutes|mins|texts|sms|calls))|\d+ ?(?:p|php|₱) (?:for )?free|withdraw \d+ ?p for free|'
  r'(?:withdraw|i-?withdraw|claim) (?:your |ang )?(?:winnings|panalo)|'
  r'you have (?:p|php|₱) ?[\d,]+(?:\.\d+)? in your account)',
);
final _claim = RegExp(
  r'\b(?:claim|i-?claim|redeem|to receive|matanggap|entitlement|processing fee|release fee|magbayad)\b',
);
final _details = RegExp(r'\b(?:(?:full )?name\W+(?:and )?address|pangalan\W.{0,20}address|bank details)\b');
final _advanceFee = RegExp(
  r'\b(?:(?:release|processing|clearance|activation|handling|unlock|shipping|training|customs|redelivery|'
  r'registration|membership|insurance|reservation|verification|penalty) fee|pay first|advance payment|'
  r'(?:mag-?)?deposit muna|(?<!paki-?)\bbayad muna|munang mag-?deposit|kailangan (?:muna )?(?:ang |ng )?bayad|'
  r'personal (?:account|wallet|g-?cash)|personal kong|outside the app)\b',
);
final _inPerson = RegExp(
  r'\b(?:office|hr|customer service|booth|counter|store|branch|desk|munisipyo|barangay|city hall)\b|\bvalid id\b',
);
final _aid = RegExp(r'\b(?:ayuda|allowance|cash aid|financial assistance|subsidy)\b');
final _claimPrize = RegExp(r'\b(?:claim|i-?claim|kunin) (?:your |ang |mo ang )?(?:prize|reward|premyo)');

// An account or delivery threat with a "do this now" step; with a link it's the classic phishing text.
final _threat = RegExp(
  r'\b(?:suspend\w*|suspendido|deactivat\w*|disabled?|lock(?:ed)?|restricted|on-?hold|on hold|blocked|blocking|'
  // Bills and expiring points are left out: real billers send those with links the phone doesn't know.
  r'clos(?:ed|ure)|terminat\w*|masususpinde|ma-?block|'
  r'under review|cannot be delivered|hindi maipadala|security purposes|issues with account security|'
  r'unrecognized attempts|login attempts|incomplete address|(?:continue|keep) receiving|(?:permanently )?delet(?:ed|ion)|'
  r'revoked?|hindi (?:namin )?(?:maihatid|maipadala)|delivery (?:attempt )?failed|failed (?:delivery|twice)|'
  r'will be (?:returned|cancell?ed))\b',
);
final _threatAction = RegExp(
  r'\b(?:verify|verification|update|confirm|register|log ?in|appeal|settle|pay|redeem|convert|claim|regain|'
  r'review|i-?update|i-?redeem|i-?confirm|magbayad|bayaran|provide|re-?schedule|i-?schedule)\b',
);

final _newNumber = RegExp(
  r'\b(?:bagong (?:number|numero|sim)|new (?:number|phone|sim)|numerong gamit|nasira (?:ang )?(?:phone|cellphone|cp)|'
  r'nawala (?:ang )?(?:phone|cellphone|cp)|lost my phone)\b',
);
final _wrongSend = RegExp(r'\b(?:nagkamali (?:ako )?ng (?:send|padala)|wrong (?:send|transfer)|by mistake|napasa-?load)\b');
// Someone claiming a relative is arrested, hurt or in hospital.
final _emergency = RegExp(r'\b(?:presinto|pulis|police|nahuli|makulong|naaksidente|aksidente|ospital|hospital|kidnap\w*)\b');
final _sendBack = RegExp(r'\b(?:pakibalik|ibalik|isauli|send (?:it )?back|return (?:it|the money))\b');
// What turns a relative's or a wrong-send request into the scam: keep it secret, or pay a new number/wallet.
final _secrecy = RegExp(r"\b(?:wag|huwag|don'?t) (?:mo )?(?:muna )?(?:sabihin|tawagan|ipaalam|tell|call)\b");
final _newDestination = RegExp(
  r'\b(?:g-?cash|wallet|account|number|numero) na ito\b|\bthis (?:g-?cash|wallet|account|number)\b|(?:\+?63|\b0)9\d{9}\b',
);

final _easyMoney = RegExp(
  r'\b(?:daily (?:salary|income)|salary of \d|(?:sweldo|suweld\w|sahod)\W+\d|\d+\W*(?:per|a|bawat) (?:day|araw|order)|'
  r'earn(?:ing)? (?:up to )?\S*\d(?![\d%])|\d+% (?:daily|weekly|monthly)|(?:daily|weekly) (?:profit|returns?)|airdrop|earn at|make money|kumita\b|kikita|kumikita ako|extra income|(?:part-?time|online|seller|easy|home) job|job offer|'
  r'work from home|\bwfh\b|home-?based|onliner|mag-?rate lang|doble ang pera|double your money|guaranteed|walang talo|'
  r'crypto\w*|bitcoin|\d*usdt|trading tutor|milyonaryo|red envelope|(?:personal|cash|easy) loans?|loan offer|'
  r'offer you (?:a )?(?:personal )?loan)\b',
);
final _privateContact = RegExp(
  r'(?:\b(?:contact|reply|message|msg|chat|add|pm|e-?mail)(?: me| us| our \w+ team)\W+(?:\w+\W+){0,2}'
  r'(?:via |thru |through |on |at |by |sa |to )?(?:e-?mail|gmail|what\W?s\W?app|telegram|viber|wechat)\b|'
  r'\b(?:via|thru|through|on) (?:telegram|viber|what\W?s\W?app|wechat)\b|\b(?:telegram|viber|what\W?s\W?app) group\b|'
  r'\bsearch for \w+ to download\b|\bprocessing team\b|\bpm (?:lang|me|mo ako)\b|\breply \W?yes\b|'
  r'[\w.]+@(?:gmail|yahoo|ymail|hotmail|outlook)\.com|what\W?s\W?app\d? ?\+?\d)',
);

final _urgency = RegExp(
  r'\b(?:urgent|immediately|asap|act now|right away|within \d+ ?(?:hours?|hrs?|minutes?|mins?)|today only|'
  r'ngayon na|ngayon din|agad|locked|suspended|suspension|suspendido|deactivated|blocked|mawawala|'
  r'masususpinde|ma-?block|(?:hanggang|until) (?:\d{1,2}(?::\d\d)? ?(?:am|pm)|mamaya|today|tonight|ngayong? (?:araw|gabi)))\b',
);
final _brand = RegExp(
  r'\b(?:g-?cash|maya|paymaya|bdo|banco de oro|bpi|landbank|metrobank|unionbank|rcbc|pnb|sss|philhealth|pag-?ibig|'
  r'bir|dswd|dict|lto|gsis|phlpost)\b',
);

// Shops, couriers and utilities scammers pose as; not a reason by itself, only backing for a request.
final _shop = RegExp(r'\b(?:shopee|lazada|j&t|lbc|ninja ?van|meralco|globe|smart|facebook|seller|agent|assistant|audit)\b');

final _family = RegExp(
  r'\b(?:ma|mama|mommy|mom|nay|nanay|inay|pa|papa|daddy|dad|tay|tatay|itay|ate|kuya|tita|tito|lola|lolo|anak|'
  r'insan|bunso|bes|tol|pre)\b',
);
final _moneyAsk = RegExp(
  r'\b(?:pa-?send|send|padala|ipadala|magpadala|pahingi|pahiram|pautang|pa[- ]?load|pasaload)\b[^.!?]{0,40}?'
  r'\b(?:pera|money|load|pamasahe|gcash|wallet|libo|\d+)\b',
);

final _gamblingWord = RegExp(
  r'\b(?:casino|(?<!limited |few |available |remaining )slots?|e-?sabong|sabong|cockfighting|jili|baccarat|baraha|sportsbook|betting|\w*bingo\w*|poker|roulette|taya|'
  r'pagcor|lucky wheel|gaming credits?|\w*bet\d+\w*|\d+bets?\w?|[a-z]\d?bet|bet(?:fil|plus)\w*|gaming platform|big win|unang deposito|first deposit|'
  r'free bets?|best odds|(?:libreng|free) deposit|new players?|fresh faces|winning (?:rates?|probability|spree)|'
  r'lottery tickets?|casin[o0]|(?:1st|first) deposit|vip (?:rebate|perks|rewards?|reward plan|bonus\w*|url)|'
  r'(?:rebate|perks|rewards?|bonus\w*)[^.!?]{0,30}\bvip\b)\b|\b21 ?yo\+',
);
// "Join and win a motorcycle: sign up at <unknown site>".
final _winPitch = RegExp(r'\b(?:win|manalo|winner|panalo|raffle draw)\b');
final _signUp = RegExp(r'\b(?:register|sign ?up|join|sumali|magrehistro|click)\b');
final _purchase = RegExp(r'\b(?:receipts?|purchases?|bumili|bili|buy|shop|order)\b');
// A peso gift for signing up somewhere: "FREE PHP20 gift", "libreng P50".
final _freePeso = RegExp(
  r'\b(?:free|libreng)\s?(?:p|php|₱)\s?\d+(?![\d,]*\s(?:load|data|cashback|off))|\b\d+ ?(?:p|php|₱)\s(?:for )?free\b',
);
// Pay in to get more back: "recharge 100, get 166", "cash in P50, get P100".
final _topUpGet = RegExp(
  r'\b(?:recharge|mag-?recharge|top[- ]?up|cash[- ]?in|deposit\w*|magdeposito)\b.{0,40}\b(?:get|maka(?:ka)?kuha|makatanggap|receive|naka-?p?\d)',
);
final _luckyOrPeso = RegExp(r'\b\d+ ?(?:p|php|pesos?)\b|₱|\bp ?\d');
// Casino-style lucky amounts with a giveaway: "free 777", "8888 bonus", "P1,888 cash".
final _luckyAmount = RegExp(r'\b[\d,]*(?:777|888)[\d,]*\s?(?:p|php|pesos?)?\b');
final _giveaway = RegExp(r'\b(?:free|libre\w*|bonus\w*|claim|makakuha|receive|cash|reward\w*|gift|giveaway|credits?|wins?)\b');
// "Download the app ... P117 cash": paid to install.
final _paidDownload = RegExp(
  r'\bdownload\w*\b.{0,60}(?:\b\d+ ?p\b|\bp ?\d|₱|\bphp ?\d|\bcash\b)|(?:\b\d+ ?p\b|\bp ?\d|₱).{0,60}\bdownload',
);
final _bonus = RegExp(
  r'(?:bonus\w*|\bfree credits?|libreng (?:(?:p|php)?\d+\w*|pera)|free (?:\d+\w*|money)|cash ?back|rebate|spin)\b',
);
final _gamble = RegExp(
  r'\b(?:deposit\w*|deposito|withdraw|laro|maglaro|paglalaro|games?|play|sign[- ]?up|register|magrehistro|'
  r'magparehistro|recharge|top[- ]?up|log ?in|sign[- ]?in|claim|welcome|sumali|sali|join|wins?|winner|manalo|panalo|pagwawagi|'
  r'prizes?|premyo|swerte|suwerte|lucky)\b',
);
// Play our games and win.
final _play = RegExp(r'\b(?:games?|gaming|laro\w*|maglaro|manlalaro|play)\b');
final _prizeWord = RegExp(r'\b(?:win|wln|manalo|panalo|premyo|papremyo|prizes?|winning|winner|swerte|jackpot)\b'
);
// "Turn 20 pesos into 30k": a tiny stake for a big win.
final _stakeWin = RegExp(r'\b\d+ ?pesos?\b.{0,60}\b\d+k\b|\b\d+k\b.{0,60}\b\d+ ?pesos?\b');

// A bank or agency (not a wallet people pay through) asking you to call or pay a mobile number.
final _officialSender = RegExp(
  r'\b(?:bdo|banco de oro|bpi|landbank|metrobank|unionbank|rcbc|pnb|sss|philhealth|pag-?ibig|bir|dswd|lto|gsis|'
  r'meralco)\b',
);
// A text that opens as a wallet or bank ("GCash: ...") but pushes gambling: real brands never advertise betting.
final _brandSender = RegExp(
  r'^\W*(?:g-?cash|maya|paymaya|bdo|banco de oro|bpi|landbank|metrobank|unionbank|rcbc|pnb|security bank|chinabank)\s*[:|-]',
);
final _mobileNumber = RegExp(r'(?:\+?63|\b0)9\d{9}\b');
final _callOrPay = RegExp(r'\b(?:call|tawag\w*|text|contact|pay|bayad\w*|bayar\w*|magbayad|send|magpadala|padala)\b');

final _promo = RegExp(
  r'(?:\bpromo\b|\bsale\b|% off|\bdiscount|\bvouchers?\b|free shipping|shop now|register to|'
  r'\btext \w+ to \d{3,}|\bgigas?\d*\b|\bgosurf|\bdial \*\d+|\bcashback\b|\bunli)',
);

/// Judges a text on the phone alone.
PhoneCheck phoneCheck(String text) {
  final n = _normalize(text);
  // Lower-case, undo look-alike digits in words ("b0nus"), join spaced letters ("B D O") and lines,
  // so split requests still match.
  final t = n
      .replaceAllMapped(RegExp(r'(?<=[a-z])I(?=[a-z])'), (_) => 'l')
      .replaceAllMapped(RegExp(r'(?<=[A-Z])l(?=[A-Z])'), (_) => 'I')
      .toLowerCase()
      .replaceAllMapped(RegExp(r'(?<=[a-z])[0134@$5!](?=[a-z])|(?<!\w)\$(?=[a-z])|(?<=[a-z]{3})[$0](?!\w)|(?<!\w)0(?=[a-z]{3})'), (m) => _leet[m[0]]!)
      .replaceAllMapped(RegExp(r'\b[a-z0-9](?:[ *][a-z0-9]\b){2,}'), (m) => m[0]!.replaceAll(RegExp('[ *]'), ''))
      .replaceAll(RegExp(r'\s+'), ' ');
  final links = _findLinks(n);
  final unofficial = links.where((l) => !isOfficialLink(l)).isNotEmpty;
  bool asked(RegExp r) => r.allMatches(t).any((m) => !_negated(t, m.start));
  final warning = _scamWarning.hasMatch(t);

  // A text that carries the code ("Enter OTP 482913") is delivering it, not asking for it.
  final asksSecret = !warning && !_codeDelivery.hasMatch(t) && asked(_secretRequest);
  final contact = !warning && _privateContact.hasMatch(t);
  final asksFee = !warning && asked(_advanceFee);
  final details = _details.hasMatch(t);
  final win = _win.hasMatch(t);
  final remote = links.isNotEmpty || asksFee || details || contact;
  // A prize claimed in person ("at the barangay hall, bring an ID") is often real; one claimed online, by fee or
  // by sending details is not.
  final inPerson = !remote && _inPerson.hasMatch(t);
  final prize =
      !inPerson &&
      ((win && (_claim.hasMatch(t) || remote)) ||
          (_aid.hasMatch(t) && _claim.hasMatch(t) && unofficial) ||
          _claimPrize.hasMatch(t));
  final prizeHook = prize;
  final unbranded = unofficial || !_brand.hasMatch(t);
  final gambling =
      _gamblingWord.hasMatch(t) ||
      _gamblingWord.hasMatch(n.toLowerCase()) ||
      // Generic promo words below only count with a link the phone doesn't know, or no known brand: real
      // brands run app, raffle and cash-in promos with the same words.
      (!warning && unofficial && _play.hasMatch(t) && _prizeWord.hasMatch(t)) ||
      (_bonus.hasMatch(t) && _gamble.hasMatch(t)) ||
      (_stakeWin.hasMatch(t) && _gamble.hasMatch(t)) ||
      (unbranded && _topUpGet.hasMatch(t) && _luckyOrPeso.hasMatch(t)) ||
      (_luckyAmount.hasMatch(t) && _giveaway.hasMatch(t)) ||
      (unbranded && _paidDownload.hasMatch(t)) ||
      // Real raffles come with a purchase; casino "events" only want a sign-up.
      (unofficial && _winPitch.hasMatch(t) && _signUp.hasMatch(t) && !_purchase.hasMatch(t)) ||
      (unofficial && _freePeso.hasMatch(t));
  final moneyAsk = _moneyAsk.hasMatch(t);
  // Banks and agencies use hotlines and their own apps, never a personal mobile number to call or pay.
  final officialToMobile = _officialSender.hasMatch(t) && _mobileNumber.hasMatch(t) && _callOrPay.hasMatch(t);
  final impersonation =
      (_newNumber.hasMatch(t) && moneyAsk) ||
      (_wrongSend.hasMatch(t) && _sendBack.hasMatch(t)) ||
      (_emergency.hasMatch(t) && moneyAsk) ||
      officialToMobile ||
      (gambling && unofficial && _brandSender.hasMatch(t));
  // Real relatives change numbers and real people mis-send; secrecy or a new wallet to pay is the scam.
  final impersonationHook =
      impersonation && (officialToMobile || _secrecy.hasMatch(t) || _newDestination.hasMatch(t) || unofficial);

  final signs = <Sign>[
    // With only the brand's own links, the request isn't sending you to a fake page.
    if (asksSecret && unofficial) const Sign('otp_with_link', SignStrength.strong),
    if (asksSecret && !unofficial) const Sign('credential_request', SignStrength.strong),
    if (links.any(_isLookalike)) const Sign('lookalike_domain', SignStrength.strong),
    if (_threat.hasMatch(t) && _threatAction.hasMatch(t) && unofficial) const Sign('account_threat', SignStrength.strong),
    if (prize) const Sign('prize_claim', SignStrength.strong),
    if (impersonation) const Sign('impersonation', SignStrength.strong),
    if (asksFee) const Sign('payment_request', SignStrength.strong),
    if (!warning && _easyMoney.hasMatch(t)) const Sign('easy_money', SignStrength.strong),
    if (contact) const Sign('private_contact', SignStrength.strong),
    if (gambling) const Sign('gambling_ad', SignStrength.weak),
    if (_urgency.hasMatch(t)) const Sign('urgency', SignStrength.weak),
    if (_brand.hasMatch(t)) const Sign('brand_mention', SignStrength.weak),
    if (_family.hasMatch(t) && moneyAsk) const Sign('family_money', SignStrength.weak),
  ];
  final codes = {for (final s in signs) s.code};

  final Verdict verdict;
  if (codes.intersection(_decisive).isNotEmpty || prizeHook || impersonationHook) {
    verdict = Verdict.dangerous;
  } else if (codes.intersection(_hooks).isNotEmpty) {
    // A code or fee request, an easy-money offer or "contact me on email" alone may be innocent;
    // backed by another sign or a link it's the classic scam.
    final backing = codes.intersection(_backing).length + (unofficial ? 1 : 0) + (_shop.hasMatch(t) ? 1 : 0);
    verdict = backing >= 2 ? Verdict.dangerous : Verdict.beCareful;
  } else if (gambling) {
    verdict = Verdict.beCareful;
  } else {
    verdict = Verdict.looksSafe;
  }
  final promo = verdict == Verdict.looksSafe && _promo.hasMatch(t);
  return PhoneCheck(verdict, signs, links, harmlessPromo: promo);
}

const _decisive = {'otp_with_link', 'lookalike_domain', 'account_threat'};
const _hooks = {'credential_request', 'payment_request', 'easy_money', 'private_contact', 'prize_claim', 'impersonation'};
const _backing = {'credential_request', 'payment_request', 'easy_money', 'private_contact', 'brand_mention', 'urgency', 'gambling_ad'};

const _leet = {'0': 'o', '1': 'i', '3': 'e', '4': 'a', '@': 'a', r'$': 's', '5': 's', '!': 'l'};

/// True when the clause before [start] says not to do it ("Never share your OTP").
bool _negated(String t, int start) {
  final before = t.substring(max(0, start - 40), start);
  final clause = before.substring(before.lastIndexOf(RegExp(r'[.!?]')) + 1);
  return _negation.hasMatch(clause);
}

List<String> _findLinks(String text) => [
  for (final m in _link.allMatches(text)) m[0]!.replaceFirst(RegExp(r'''[.,!?;:)\]}'"]+$'''), ''),
];

/// A host that uses a known brand's word but whose registrable domain isn't that brand's own.
bool _isLookalike(String link) {
  final uri = Uri.tryParse(link.contains('://') ? link : 'http://$link');
  final labels = (uri?.host.toLowerCase() ?? '').split('.')..removeWhere((l) => l.isEmpty);
  if (labels.length < 2) return false;
  final keep = labels.length > 2 && _twoLevelSuffixes.contains(labels.sublist(labels.length - 2).join('.')) ? 3 : 2;
  final registrable = labels.sublist(labels.length - keep).join('.');
  if (officialDomains.values.any((ds) => ds.contains(registrable))) return false;
  // Brands publish app links on shared deep-link hosts as "<brand>.onelink.me"; affixed names stay look-alikes.
  if (_deepLinkHosts.contains(registrable) && labels.length == 3 && officialDomains.containsKey(labels.first)) {
    return false;
  }
  // "https://bdo.com.ph@evil.example" really goes to evil.example, so the part before "@" counts too.
  final tokens = [
    ...labels.take(labels.length - 1),
    ...uri!.userInfo.toLowerCase().split(RegExp('[.:]')),
  ].expand((l) => l.split('-'));
  if (tokens.any((tok) => officialDomains.keys.any((b) => _namesBrand(tok, b)))) return true;
  // In a path, a bank name alone is common in real promo short links ("bit.ly/BPI-Promo"); with a login word it's phishing.
  final path = uri.path.toLowerCase();
  return _pathPhish.hasMatch(path) &&
      path.split(RegExp('[^a-z0-9]')).any((tok) => _moneyBrands.any((b) => _namesBrand(tok, b)));
}

const _deepLinkHosts = {'onelink.me', 'page.link', 'app.link'};

final _pathPhish = RegExp('online|secure|login|verif|update|account|security|confirm|unlock|support|mobile|portal');

/// [token] is [brand] with only scam affixes around it ("onlinebdoverify", "mylandbankph").
bool _namesBrand(String token, String brand) {
  final at = token.indexOf(brand);
  return at >= 0 && _affixes(token.substring(0, at)) && _affixes(token.substring(at + brand.length));
}

bool _affixes(String s) => s.isEmpty || _brandAffixes.any((a) => s.startsWith(a) && _affixes(s.substring(a.length)));

/// Undoes Unicode tricks: invisible characters, full-width and math-styled letters, Cyrillic/Greek look-alikes.
String _normalize(String text) {
  final out = StringBuffer();
  for (final r in text.runes) {
    if (_invisible.contains(r)) continue;
    if (r >= 0xFF01 && r <= 0xFF5E) {
      out.writeCharCode(r - 0xFEE0);
    } else if (r >= 0x1D400 && r <= 0x1D6A3) {
      final i = (r - 0x1D400) % 52;
      out.writeCharCode(i < 26 ? 0x41 + i : 0x61 + i - 26);
    } else if (r >= 0x1D7CE && r <= 0x1D7FF) {
      out.writeCharCode(0x30 + (r - 0x1D7CE) % 10);
    } else {
      out.write(_homoglyphs[String.fromCharCode(r)] ?? String.fromCharCode(r));
    }
  }
  return out.toString();
}

const _invisible = {
  0x00AD,
  0x180E,
  0x200B,
  0x200C,
  0x200D,
  0x200E,
  0x200F,
  0x2060,
  0x2061,
  0x2062,
  0x2063,
  0x2064,
  0xFEFF,
};

const _homoglyphs = {
  'А': 'A', 'В': 'B', 'Е': 'E', 'К': 'K', 'М': 'M', 'Н': 'H', 'О': 'O', 'Р': 'P', 'С': 'C', 'Т': 'T', 'Х': 'X', //
  'а': 'a', 'е': 'e', 'о': 'o', 'р': 'p', 'с': 'c', 'у': 'y', 'х': 'x', 'і': 'i', 'ј': 'j', 'ѕ': 's', 'ԁ': 'd',
  'Α': 'A', 'Β': 'B', 'Ε': 'E', 'Ζ': 'Z', 'Η': 'H', 'Ι': 'I', 'Κ': 'K', 'Μ': 'M', 'Ν': 'N', 'Ο': 'O', 'Ρ': 'P',
  'Τ': 'T', 'Υ': 'Y', 'Χ': 'X', 'ο': 'o', 'α': 'a', 'ν': 'v', 'ι': 'i', 'ɡ': 'g',
};

/// A link whose host is on a known brand's own domain, which the phone can judge without going online.
bool isOfficialLink(String link) {
  final host = Uri.tryParse(link.contains('://') ? link : 'http://$link')?.host.toLowerCase() ?? '';
  return officialDomains.values.expand((ds) => ds).any((d) => host == d || host.endsWith('.$d'));
}
