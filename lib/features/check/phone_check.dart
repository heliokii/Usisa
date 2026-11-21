import 'check.dart' show Verdict;

enum SignStrength { strong, weak }

/// A warning sign the phone found, by reason code.
class Sign {
  const Sign(this.code, this.strength);
  final String code;
  final SignStrength strength;
}

class PhoneCheck {
  const PhoneCheck(this.verdict, this.signs, this.links);
  final Verdict verdict;
  final List<Sign> signs;
  final List<String> links;
}

// shortcut: a minimal phone check with a few strong signs for the tracer; #25 rewrites it in full.
final _link = RegExp(
  r'(?:https?://|intent:|www\.)[^\s<>"]+'
  r'|\b(?:[a-z0-9-]+\.)+(?:com|net|org|ph|xyz|top|info|ly|io|me|site|online|click|link|app|cc)\b(?:/[^\s<>"]*)?',
  caseSensitive: false,
);
final _secret = RegExp(r'\b(?:otp|one[- ]time (?:pin|password)|password|pin|verification code)\b');
final _prize = RegExp(r'\b(?:you (?:have )?won|nanalo ka|claim your (?:prize|reward))\b');
final _urgency = RegExp(
  r'\b(?:urgent|immediately|within \d+ ?(?:hours?|hrs?|minutes?|mins?)|ngayon na|agad|locked|suspended)\b',
);
const _officialDomains = {
  'gcash': ['gcash.com'],
  'maya': ['maya.ph', 'paymaya.com'],
  'bdo': ['bdo.com.ph'],
  'bpi': ['bpi.com.ph'],
  'landbank': ['landbank.com'],
  'metrobank': ['metrobank.com.ph'],
  'sss': ['sss.gov.ph'],
};

/// Judges a text on the phone alone.
PhoneCheck phoneCheck(String text) {
  // Lower-case and join lines so requests split across lines still match.
  final t = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  final links = [
    for (final m in _link.allMatches(text)) m[0]!.replaceFirst(RegExp(r'[.,!?;:)]+$'), ''),
  ];
  final signs = <Sign>[
    if (links.isNotEmpty && _secret.hasMatch(t)) const Sign('otp_with_link', SignStrength.strong),
    if (links.any(_isLookalike)) const Sign('lookalike_domain', SignStrength.strong),
    if (_prize.hasMatch(t)) const Sign('prize_claim', SignStrength.strong),
    if (_urgency.hasMatch(t)) const Sign('urgency', SignStrength.weak),
  ];
  final verdict = signs.any((s) => s.strength == SignStrength.strong)
      ? Verdict.dangerous
      : Verdict.looksSafe;
  return PhoneCheck(verdict, signs, links);
}

/// A host that names a known brand but isn't on that brand's own domain.
bool _isLookalike(String link) {
  final host = Uri.tryParse(link.contains('://') ? link : 'http://$link')?.host.toLowerCase() ?? '';
  final words = host.split(RegExp(r'[.-]'));
  return _officialDomains.entries.any(
    (e) => words.contains(e.key) && !e.value.any((d) => host == d || host.endsWith('.$d')),
  );
}
