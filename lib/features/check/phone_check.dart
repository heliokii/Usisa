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
};

/// Known link shorteners, carried over from the old url_checker.
const shorteners = ['bit.ly', 'tinyurl.com', 't.co', 'shorturl.at', 'rb.gy', 'cutt.ly'];

// Second-level suffixes, so "bdo.com.ph" is the registrable domain of "online.bdo.com.ph".
const _twoLevelSuffixes = {'com.ph', 'net.ph', 'org.ph', 'gov.ph', 'edu.ph', 'co.uk', 'com.sg', 'com.my'};

// Words scammers glue onto a brand ("onlinebdo", "gcashph").
const _brandAffixes = {
  'online', 'my', 'secure', 'login', 'verify', 'ph', 'app', 'bank', 'banking', 'help', 'support', //
  'update', 'account', 'e', 'web', 'portal', 'official', 'promo', 'rewards',
};

// Endings a bare "word.word" must have to count as a link, so "ok.salamat" and "report.pdf" don't.
const _tlds =
    'com|net|org|info|biz|ph|gov|edu|xyz|top|online|site|club|life|live|pw|vip|win|bet|casino|games|fun|icu|'
    'shop|store|click|link|app|io|ly|me|cc|co|tk|ml|ga|cf|gq|ws|gg|cn|ru|us|uk|asia|tv|sg|cloud|today|world|'
    'space|website|tech|buzz|monster|cyou|sbs|bond|lol|page|dev|at|gy|ink|xin|work|support|help|services';

final _link = RegExp(
  '${r'''\b[a-z][a-z0-9+.-]*://[^\s<>"']+'''}'
  '${r'''|\bwww\.[^\s<>"']+'''}'
  '${r'''|(?<![\w@.-])(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:'''}$_tlds'
  '${r''')(?![\w-])(?::\d{1,5})?(?:[/?#][^\s<>"']*)?'''}',
  caseSensitive: false,
);

const _secret =
    r'(?:otp|one ?time (?:pin|password|passcode)|password|passcode|m?pin|security code|verification code|'
    r'\d-digit code)';
const _askVerb =
    r'(?:send|share|provide|enter|give|submit|reply with|type|input|forward|relay|i-?send|pa-?send|pa-?forward|pakisend|ipadala|'
    r'ibigay|ilagay|i-?type|i-?reply|ibahagi|sabihin|i-?forward)';
final _secretRequest = RegExp('\\b$_askVerb\\b.{0,60}?\\b$_secret\\b');
final _negation = RegExp(r"\b(?:never|do not|don'?t|huwag|wag|hindi|not to|avoid|no one|nobody|walang)\b");

final _win = RegExp(
  r"\b(?:you(?:'ve| have)? won|you are (?:our |the |a )?(?:lucky )?winner|nanalo ka|panalo ka|napili ka|"
  r'congratulations?,? (?:you|winner))',
);
final _claim = RegExp(r'\b(?:claim|i-?claim|kunin|redeem|processing fee|release fee|magbayad|bayad)\b');
final _advanceFee = RegExp(
  r'\b(?:(?:release|processing|clearance|activation|handling|unlock) fee|bayad muna|pay first|advance payment)\b',
);
final _claimPrize = RegExp(r'\b(?:claim|i-?claim|kunin) (?:your |ang |mo ang )?(?:prize|reward|premyo)');

final _urgency = RegExp(
  r'\b(?:urgent|immediately|asap|act now|right away|within \d+ ?(?:hours?|hrs?|minutes?|mins?)|today only|'
  r'ngayon na|ngayon din|agad|locked|suspended|suspension|suspendido|deactivated|blocked|mawawala|'
  r'masususpinde|ma-?block)\b',
);
final _brand = RegExp(
  r'\b(?:g-?cash|maya|paymaya|bdo|bpi|landbank|metrobank|unionbank|rcbc|pnb|sss|philhealth|pag-?ibig|bir|dswd)\b',
);

final _family = RegExp(
  r'\b(?:ma|mama|mommy|mom|nay|nanay|inay|pa|papa|daddy|dad|tay|tatay|itay|ate|kuya|tita|tito|lola|lolo|anak|'
  r'insan|bunso|bes|tol|pre)\b',
);
final _moneyAsk = RegExp(
  r'\b(?:pa-?send|send|padala|ipadala|pahingi|pautang|pa[- ]?load|pasaload)\b[^.!?]{0,40}?'
  r'\b(?:pera|money|load|pamasahe|gcash|\d+)\b',
);

final _gamblingWord = RegExp(
  r'\b(?:casino|slots?|e-?sabong|sabong|jili|baccarat|sportsbook|betting|bingo|poker|roulette|taya|\w*bet\d+|\d+bet)\b',
);
final _bonus = RegExp(r'\b(?:bonus|free credits?|libreng \d+\w*|free \d+\w*)\b');
final _deposit = RegExp(r'\b(?:deposit|withdraw|laro|games?|play)\b');

final _promo = RegExp(
  r'(?:\bpromo\b|\bsale\b|% off|\bdiscount|\bvouchers?\b|free shipping|shop now|register to|'
  r'\btext \w+ to \d{3,}|\bgigas?\d*\b|\bgosurf|\bdial \*\d+|\bcashback\b|\bunli)',
);

/// Judges a text on the phone alone.
PhoneCheck phoneCheck(String text) {
  final n = _normalize(text);
  // Lower-case, undo look-alike digits in words ("b0nus") and join lines so split requests still match.
  final t = n
      .toLowerCase()
      .replaceAllMapped(RegExp(r'(?<=[a-z])[0134@$5](?=[a-z])'), (m) => _leet[m[0]]!)
      .replaceAll(RegExp(r'\s+'), ' ');
  final links = _findLinks(n);

  final asksSecret = _secretRequest.allMatches(t).any((m) => !_negated(t, m.start));
  final prize = (_win.hasMatch(t) && (_claim.hasMatch(t) || links.isNotEmpty)) || _claimPrize.hasMatch(t);
  final gambling = _gamblingWord.hasMatch(t) || (_bonus.hasMatch(t) && _deposit.hasMatch(t));

  final signs = <Sign>[
    if (asksSecret && links.isNotEmpty) const Sign('otp_with_link', SignStrength.strong),
    if (asksSecret && links.isEmpty) const Sign('credential_request', SignStrength.strong),
    if (links.any(_isLookalike)) const Sign('lookalike_domain', SignStrength.strong),
    if (prize) const Sign('prize_claim', SignStrength.strong),
    if (_advanceFee.hasMatch(t)) const Sign('payment_request', SignStrength.strong),
    if (gambling) const Sign('gambling_ad', SignStrength.weak),
    if (_urgency.hasMatch(t)) const Sign('urgency', SignStrength.weak),
    if (_brand.hasMatch(t)) const Sign('brand_mention', SignStrength.weak),
    if (_family.hasMatch(t) && _moneyAsk.hasMatch(t)) const Sign('family_money', SignStrength.weak),
  ];
  final codes = {for (final s in signs) s.code};

  final Verdict verdict;
  if (codes.intersection(const {'otp_with_link', 'lookalike_domain', 'prize_claim'}).isNotEmpty) {
    verdict = Verdict.dangerous;
  } else if (codes.contains('credential_request') || codes.contains('payment_request')) {
    // A code or fee request alone may be a mix-up; with a brand, a rush or a gambling ad it's the classic scam.
    final backed = codes.intersection(const {'brand_mention', 'urgency', 'gambling_ad'}).isNotEmpty;
    verdict = backed ? Verdict.dangerous : Verdict.beCareful;
  } else if (gambling) {
    verdict = Verdict.beCareful;
  } else {
    verdict = Verdict.looksSafe;
  }
  final promo = verdict == Verdict.looksSafe && _promo.hasMatch(t);
  return PhoneCheck(verdict, signs, links, harmlessPromo: promo);
}

const _leet = {'0': 'o', '1': 'i', '3': 'e', '4': 'a', '@': 'a', r'$': 's', '5': 's'};

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
  // "https://bdo.com.ph@evil.example" really goes to evil.example, so the part before "@" counts too.
  final tokens = [
    ...labels.take(labels.length - 1),
    ...uri!.userInfo.toLowerCase().split(RegExp('[.:]')),
  ].expand((l) => l.split('-'));
  return tokens.any((tok) => officialDomains.keys.any((b) => _namesBrand(tok, b)));
}

bool _namesBrand(String token, String brand) {
  if (token == brand) return true;
  if (token.startsWith(brand)) return _brandAffixes.contains(token.substring(brand.length));
  if (token.endsWith(brand)) return _brandAffixes.contains(token.substring(0, token.length - brand.length));
  return false;
}

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
