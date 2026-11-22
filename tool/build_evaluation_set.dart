// Grows the labelled test set (#26, #27). Keeps every existing row unchanged, adds the source rows picked below
// (masked) and the hand-written rows in evaluation_additions.dart, and files each new row by its template's hash,
// so the sealed 30% grows without anyone choosing what goes in it. It never prints message text.
//
//   dart run tool/build_evaluation_set.dart <Yissuh merged-set.csv> <Kaggle-derived dataset.csv>
//
// Sources (see the licence fields in test/fixtures/evaluation/*.json):
//   Yissuh/Filipino-Spam-SMS-Detection-Model merged-set.csv (BSD 3-Clause); "yissuh-N" is data row N.
//   github.com/drvii/data-analysis-spam-sms-ph dataset.csv, a copy of bwandowando's Kaggle "Philippine Spam/Scam
//   SMS" (CC BY-NC-SA 4.0); "kaggle-N" is its row N. Kaggle-derived rows stay in their own kaggle_*.json files.
import 'dart:convert';
import 'dart:io';

import 'evaluation_additions.dart';
import 'evaluation_split.dart';

const _dir = 'test/fixtures/evaluation';
const _scam = 'scam', _gambling = 'gambling_ad', _promo = 'harmless_promo', _normal = 'normal';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: dart run tool/build_evaluation_set.dart <merged-set.csv> <dataset.csv>');
    exit(64);
  }
  final yissuh = _parseCsv(File(args[0]).readAsStringSync()).skip(1).toList();
  final kaggle = _parseCsv(File(args[1]).readAsStringSync()).skip(1).toList();

  final files = {for (final k in _fileKeys) k: _read(k)};
  final ids = {for (final f in files.values) for (final m in f.messages) m['id'] as String};
  final texts = {for (final f in files.values) for (final m in f.messages) _key(m['text'] as String)};
  final labelOf = {
    for (final f in files.values)
      for (final m in f.messages) m['template'] as String: m['label'] as String,
  };
  var added = 0, skipped = 0;

  void add(Row row, {required bool kaggleFile}) {
    final k = _key(row.text);
    if (ids.contains(row.id) || texts.contains(k) || k.length < 8) {
      skipped++;
      return;
    }
    final known = labelOf[row.template];
    if (known != null && known != row.label) throw StateError('${row.id}: template ${row.template} is $known');
    labelOf[row.template] = row.label;
    ids.add(row.id);
    texts.add(k);
    final file = '${kaggleFile ? 'kaggle_' : ''}${isSealedTemplate(row.template) ? 'sealed' : 'development'}';
    files[file]!.messages.add({
      'id': row.id,
      'template': row.template,
      'label': row.label,
      'reason': row.reason,
      'text': row.text,
    });
    added++;
  }

  final masker = _Masker();
  for (final row in handWritten) {
    add(row, kaggleFile: false);
  }
  for (final (i, r) in yissuh.indexed) {
    final row = _pick('yissuh-$i', r[0], r.length > 1 ? r[1] : '', masker);
    if (row != null) add(row, kaggleFile: false);
  }
  for (final r in kaggle) {
    final row = _pick('kaggle-${r[0]}', 'spam', r.length > 4 ? r[4] : '', masker);
    if (row != null) add(row, kaggleFile: true);
  }
  for (final e in files.entries) {
    File('$_dir/${e.key}.json').writeAsStringSync(e.value.encode());
  }
  final counts = {for (final e in files.entries) e.key: e.value.messages.length};
  stdout.writeln('added $added rows, skipped $skipped duplicates; now $counts');
}

const _fileKeys = ['development', 'sealed', 'kaggle_development', 'kaggle_sealed'];

class _Fixture {
  _Fixture(this.header, this.messages);
  final Map<String, dynamic> header;
  final List<Map<String, dynamic>> messages;

  String encode() {
    final b = StringBuffer('{\n');
    for (final e in header.entries) {
      b.writeln('  ${jsonEncode(e.key)}: ${jsonEncode(e.value)},');
    }
    b.writeln('  "messages": [');
    for (final (i, m) in messages.indexed) {
      final fields = m.entries.map((e) => '${jsonEncode(e.key)}: ${jsonEncode(e.value)}').join(', ');
      b.writeln('    {$fields}${i == messages.length - 1 ? '' : ','}');
    }
    b.write('  ]\n}\n');
    return b.toString();
  }
}

_Fixture _read(String key) {
  final json = jsonDecode(File('$_dir/$key.json').readAsStringSync()) as Map<String, dynamic>;
  final messages = (json.remove('messages') as List).cast<Map<String, dynamic>>();
  return _Fixture(json, messages);
}

/// The duplicate key the set's own test uses: lower-case, word characters only.
String _key(String text) => text.toLowerCase().replaceAll(RegExp(r'\W'), '');

// ---------------------------------------------------------------------------------------------------------------
// Source row selection and labels. Every unused source row was read and judged by hand (#27); the rules below
// encode those judgements. Rows not covered here are left out.

/// Rows left out: unclear intent, not a phone text, or not in the four labels.
const _skip = {
  'yissuh-66', 'kaggle-66', 'yissuh-189', 'kaggle-192', 'yissuh-232', 'kaggle-238', 'yissuh-348', 'yissuh-380', //
  'yissuh-773', 'kaggle-268', 'kaggle-343', 'yissuh-423', 'yissuh-462', 'yissuh-465',
};

/// Source rows whose label isn't what their campaign or source label says.
const _labels = <String, (String, String, String)>{
  // id: (label, template, reason)
  'yissuh-62': (_scam, 'mybitglobal', 'Crypto app airdrop lure'),
  'kaggle-62': (_scam, 'mybitglobal', 'Crypto app airdrop lure'),
  'yissuh-337': (_scam, 'mybitglobal', 'Fake USDT prize in a crypto app'),
  'yissuh-365': (_scam, 'mybitglobal', 'Crypto app airdrop lure'),
  'yissuh-136': (_scam, 'bdo-alert-onhold', 'Bank on-hold notice with a look-alike domain'),
  'kaggle-136': (_scam, 'bdo-alert-onhold', 'Bank on-hold notice with a look-alike domain'),
  'kaggle-287': (_scam, 'bdo-reverification', 'Bank re-verification lure'),
  'kaggle-300': (_scam, 'bdo-onhold-shorten', 'Bank re-activation lure through a short link'),
  'kaggle-275': (_scam, 'cc-agent', 'Credit card offer from an unofficial processing team'),
  'kaggle-327': (_scam, 'cc-agent', 'Credit card offer from an unofficial processing team'),
  'yissuh-26': (_scam, 'shopee-eligible', 'Fake marketplace giveaway'),
  'kaggle-26': (_scam, 'shopee-eligible', 'Fake marketplace giveaway'),
  'yissuh-597': (_scam, 'email-contact-me', 'Stranger asking to be contacted by email'),
  'yissuh-598': (_scam, 'email-contact-me', 'Stranger asking to be contacted by email'),
  'yissuh-774': (_scam, 'email-contact-me', 'Stranger asking to be contacted by email'),
  'yissuh-788': (_scam, 'email-contact-me', 'Stranger asking to be contacted by email'),
  'yissuh-805': (_scam, 'email-contact-me', 'Stranger asking to be contacted by email'),
  'yissuh-599': (_gambling, 'melco', 'Casino club reactivation ad'),
  'kaggle-184': (_normal, 'foodpanda-otw', 'Rider on the way'),
  'yissuh-791': (_promo, 'cashbee', 'Loan app payment reminder ad'),
  'yissuh-797': (_promo, 'political-campaign', 'Political message'),
  'yissuh-798': (_promo, 'political-campaign', 'Political message'),
};

/// Campaigns: rows of one campaign share a template so reworded variants never straddle the split.
/// Checked in order against the lower-cased text; the first match wins.
final _campaigns = <(RegExp, String, String, String)>[
  // (pattern, template, label, reason)
  (RegExp(r'won the prize|you have won'), 'won-prize-enter', _scam, 'Prize claim with a link'),
  (RegExp(r'c0ngratulat1on|masuwerteng nanal'), 'congrats-nanalo', _scam, 'Fake win with a sign-up link'),
  (RegExp(r'cash deposit of'), 'cash-deposit-login', _scam, 'Fake incoming money with a login link'),
  (RegExp(r'9910\.'), 'cyrillic-9910', _gambling, 'Casino prize ad on a Cyrillic domain'),
  (RegExp(r'1 ?pes[o0]\b|free 40p'), '1peso-jackpot', _gambling, 'One-peso bet for a big jackpot'),
  (RegExp(r'mybitglobal'), 'mybitglobal', _scam, 'Crypto app lure'),
  (RegExp(r'w\+|winning ?plus|winplus|wplus|winning\+|\bwp!'), 'wplus', _gambling, 'Online casino bonus ad'),
  (RegExp(r'\bs ?b ?e ?t\b|sbet|sb3t'), 'sbet', _gambling, 'Online sabong and casino ad'),
  (RegExp(r'jackp[o0]t ?city|jpc'), 'jackpotcity', _gambling, 'Online casino bonus ad'),
  (RegExp(r'sugar ?play|sugarbet|splay'), 'sugarplay', _gambling, 'Online casino bonus ad'),
  (RegExp(r'unibet|u ?b ?e ?t\b|unib|uninow'), 'unibet', _gambling, 'Online casino bonus ad'),
  (RegExp(r'betfil|bfil|betffil'), 'betfil', _gambling, 'Online casino bonus ad'),
  (RegExp(r'go ?jackpot|gojp|gjackpot'), 'gojackpot', _gambling, 'Online casino bonus ad'),
  (RegExp(r't1 ?bet'), 't1bet', _gambling, 'Online casino bonus ad'),
  (RegExp(r'w19'), 'w19', _gambling, 'Online casino cashback ad'),
  (RegExp(r'177 ?bet'), '177bet', _gambling, 'Betting site deposit bonus'),
  (RegExp(r'pwin ?777|p777'), 'pwin777', _gambling, 'Betting site red envelope promo'),
  (RegExp(r'bara-?ha|\bcard-\w\.life|s!ot|siot b0nus|best ba,raha'), 'baraha-life', _gambling, 'Card game bonus ad'),
  (RegExp(r'9y'), '9y-club', _gambling, 'Game club recharge bonus'),
  (RegExp(r'epicwin|betso88'), 'epicwin', _gambling, 'Online casino free credit ad'),
  (RegExp(r'kkbe'), 'kkbet', _gambling, 'Betting site promo'),
  (RegExp(r'bingo ?plus'), 'bingoplus', _gambling, 'Online bingo jackpot ad'),
  (RegExp(r'lolliplay'), 'lolliplay', _gambling, 'Online casino bonus ad'),
  (RegExp(r'richph|ri928'), 'richph', _gambling, 'Online casino bonus ad'),
  (RegExp(r'lodi ?646|lodibet'), 'lodi646', _gambling, 'Online casino bonus ad'),
  (RegExp(r'p99b|99 game'), '99game', _gambling, 'Game site sign-in bonus'),
  (RegExp(r'jili ?app|jlli app'), 'jili-app', _gambling, 'Slot app download bonus'),
  // After the named casinos, so a casino's own "free bonus, click" ad stays a gambling ad.
  (RegExp(r'free money|no deposit|free.*\?a=\d|p to you|for free\W+click'), 'free-money-login', _scam,
      'Free money lure with a login link'),
  (RegExp(r'pulang sobre|red envelope|red packet|ampao'), 'recharge-red-envelope', _gambling, 'Red envelope bonus'),
  (RegExp(r'to download and have a chance'), 'panalo-download', _gambling, 'Casino app download bonus'),
  (RegExp(r'clickhere\.cx'), 'clickhere-bets', _gambling, 'Small bet, big win slot ad'),
  (RegExp(r'phpromo'), 'phpromo-bets', _gambling, 'Small bet, big win slot ad'),
  (RegExp(r'p158|p18-p1188'), 'p158-mobile', _gambling, 'Mobile sign-up bonus'),
  (RegExp(r'\d+ ?pesos?\b.{0,40}\d+k'), 'slot-small-bet', _gambling, 'Small bet, big win slot ad'),
  (RegExp(r'/live\b|/liveph|/liveapp|/game\b|antiviruspedia|apkgametop|bartargame'), 'livegame-weekend', _gambling,
      'Casino site ad in chatty Taglish'),
  (RegExp(r'^\S+\.[a-z]{2,}/\S+ .*(?:deposit|deposito|libreng)'), 'random-domain-deposit', _gambling,
      'Deposit bonus ad from a random domain'),
];

final _gamblingWords = RegExp(
  r'casino|cas1n0|slot|s10t|bonus|b0nu|sabong|cockfight|jili|baccarat|bingo|jackpot|jackp0t|rebate|spin|'
  r'deposit|deposito|recharge|bet|taya|lucky|panalo|manalo|win|laro|games?\b|free \d|\d+ ?p\b|\d+p\b|cash out',
);

/// Ham rows by kind, reusing #26's templates so near-copies stay in one split. First match wins.
final _hamKinds = <(RegExp, String, String, String)>[
  (RegExp(r'huwag (?:po |pong |po kayong )?maniwala|ntc'), 'ntc-advisory', _normal, 'NTC scam warning'),
  (RegExp(r'paypal'), 'paypal-code', _normal, 'Login or verification code'),
  (RegExp(r'facebook'), 'facebook-code', _normal, 'Login or verification code'),
  (RegExp(r'binance'), 'binance-code', _normal, 'Login or verification code'),
  (RegExp(r'twitter'), 'twitter-code', _normal, 'Login or verification code'),
  (RegExp(r'telegram'), 'telegram-code', _normal, 'Login or verification code'),
  (RegExp(r'pag-ibig.*\b(?:otp|pin)\b'), 'pagibig-otp', _normal, 'Login or verification code'),
  (RegExp(r'\bcode\b|\botp\b|one-time|password'), 'generic-otp', _normal, 'Login or verification code'),
  (RegExp(r'loaded to'), 'smart-load-receipt', _normal, 'Load receipt'),
  (RegExp(r'prepaid credits was loaded'), 'globe-load-receipt', _normal, 'Load receipt'),
  (RegExp(r'received php .* of gcash'), 'gcash-received', _normal, 'Wallet transfer receipt'),
  (RegExp(r'payment of p.*successfully processed'), 'gcash-paid', _normal, 'Payment receipt'),
  (RegExp(r'j&t delivery!'), 'jnt-delivery', _normal, 'Courier delivery notice'),
  (RegExp(r'ginvest'), 'ginvest', _normal, 'Investment account registration notice'),
  (RegExp(r'will expire in|has expired|not included in your promo'), 'unli-expiry', _normal, 'Promo expiry notice'),
  (RegExp(r'smrt\.ph|smart app|\*123#|unli data|subscribe to your favorite promos'), 'smart-app-promo', _promo,
      'Telco app promo'),
  (RegExp(r'use \w+ to get .* rides?'), 'angkas-promo', _promo, 'Ride promo code'),
  (RegExp(r'humiram|borrow \d+mb|text \w+ to 3733'), 'tm-loan-sos', _promo, 'Telco load loan promo'),
];

Row? _pick(String id, String sourceLabel, String raw, _Masker masker) {
  if (_skip.contains(id)) return null;
  final text = masker.mask(id, raw);
  if (text.isEmpty) return null;
  final t = text.toLowerCase();
  final override = _labels[id];
  if (override != null) return (id: id, template: override.$2, label: override.$1, reason: override.$3, text: text);

  if (sourceLabel == 'ham') {
    if (RegExp(r'\S+').allMatches(text).length < 3) return null; // "Okay", "Kuya": too short to judge anything.
    for (final (pattern, template, label, reason) in _hamKinds) {
      if (pattern.hasMatch(t)) return (id: id, template: template, label: label, reason: reason, text: text);
    }
    return (id: id, template: 'personal-${id.split('-').last}', label: _normal, reason: 'Personal text', text: text);
  }

  for (final (pattern, template, label, reason) in _campaigns) {
    if (pattern.hasMatch(t)) return (id: id, template: template, label: label, reason: reason, text: text);
  }
  // Spam rows without a known campaign: the hand review found them all to be gambling ads.
  if (!_gamblingWords.hasMatch(t)) return null;
  return (id: id, template: 'auto-${_firstWords(t)}', label: _gambling, reason: 'Unsolicited betting or casino ad', text: text);
}

/// A template for rows of no known campaign: their first four words, so near-copies still group together.
String _firstWords(String t) =>
    RegExp(r'[a-z]+').allMatches(t.replaceAll(RegExp(r'\b(?:ana|ben|carlo|ella|ferdie|dodong|carla)\b'), ''))
        .take(4)
        .map((m) => m[0])
        .join('-');

/// Masks personal details the way #26 did: names, phone numbers and e-mail user names.
class _Masker {
  static const _names = ['Ana', 'Ben', 'Carlo', 'Ella', 'Ferdie', 'Dodong', 'Carla'];
  // First names that appear in the picked personal texts, replaced like <REAL NAME>.
  static final _personal = RegExp(
    r'\b(?:Roberto Villarico|Emedia|Genaro|Pam|neco|rianna|edmond|von|oliver|tina|kel|Fe|IVANA)\b',
  );
  final _phones = <String, String>{};
  var _name = 0, _email = 0;

  String mask(String id, String raw) {
    var s = raw.replaceAll(RegExp(r'\\r|\\n'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.isEmpty || s.contains('Content not supported')) return '';
    s = s.replaceAllMapped(RegExp(r'<REAL NAME>|' + _personal.pattern), (_) => _names[_name++ % _names.length]);
    s = s.replaceAllMapped(RegExp(r'\b([\w.+-]+)@((?:gmail|yahoo|hotmail|outlook|ymail)\.com)\b'),
        (m) => 'sender${100 + _email++}@${m[2]}');
    // 09XXXXXXXXX, 639XXXXXXXXX and +639XXXXXXXXX become stable 0917000XXXX numbers in their original shape.
    s = s.replaceAllMapped(RegExp(r'(\+?63|\b0)(9\d{9})\b'), (m) {
      final masked = _phones.putIfAbsent(m[2]!, () => '917000${(2000 + _phones.length).toString().padLeft(4, '0')}');
      return '${m[1]}$masked';
    });
    return s;
  }
}

List<List<String>> _parseCsv(String s) {
  final rows = <List<String>>[];
  var row = <String>[], field = StringBuffer(), quoted = false;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (quoted) {
      if (c == '"' && i + 1 < s.length && s[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (c == '"') {
        quoted = false;
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field = StringBuffer();
    } else if (c == '\n') {
      row.add(field.toString());
      rows.add(row);
      row = [];
      field = StringBuffer();
    } else if (c != '\r') {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) rows.add([...row, field.toString()]);
  return rows;
}
