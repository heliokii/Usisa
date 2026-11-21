import 'phone_check.dart';

export 'phone_check.dart' show PhoneCheck, Sign, SignStrength, phoneCheck, officialDomains, shorteners;

/// The single answer a Check gives (GLOSSARY.md).
enum Verdict { looksSafe, beCareful, dangerous, couldntCheck }

/// Where the checked content came from.
enum CheckSource { message, link, screenshot, share, sms }

class CheckInput {
  const CheckInput(this.text, {required this.source, this.aiScan = false});
  final String text;
  final CheckSource source;
  final bool aiScan;
}

/// What the online link check found for one link.
enum LinkStatus { clean, flagged, shortenerBlocked, opensApp, unresolved }

class LinkCheck {
  const LinkCheck(this.link, this.status);
  final String link;
  final LinkStatus status;
}

enum AiLevel { low, caution, high }

/// One warning sign from the AI. [quote] must appear in the checked text.
class AiSign {
  const AiSign(this.code, {this.quote});
  final String code;
  final String? quote;
}

class AiAnswer {
  const AiAnswer(this.level, [this.signs = const []]);
  final AiLevel level;
  final List<AiSign> signs;
}

/// What a Check returns; screens only display this.
class CheckResult {
  const CheckResult({required this.text, required this.verdict, required this.reasons, required this.checkedOnPhone});
  final String text;
  final Verdict verdict;

  /// At most 3 reason codes, most decisive first. The screen localizes them.
  final List<String> reasons;

  /// True when no online check (link or AI) gave an answer.
  final bool checkedOnPhone;
}

typedef LinkChecker = Future<List<LinkCheck>> Function(List<String> links);
typedef AiChecker = Future<AiAnswer?> Function(String text);

/// What screens call to run a Check; [CheckPipeline.run] in the app, a fake in widget tests.
typedef RunCheck = Future<CheckResult> Function(CheckInput input);

/// The one entry point that runs a Check: phone check, online link check, AI, then the verdict.
/// Pass a checker only when the person has consented to online checks.
class CheckPipeline {
  const CheckPipeline({this.linkChecker, this.aiChecker});
  final LinkChecker? linkChecker;
  final AiChecker? aiChecker;

  Future<CheckResult> run(CheckInput input) async {
    final phone = phoneCheck(input.text);
    var links = const <LinkCheck>[];
    if (linkChecker != null && phone.links.isNotEmpty) {
      try {
        links = await linkChecker!(phone.links);
      } catch (_) {
        // Any failure means the links weren't checked, never that they're clean.
        links = [for (final l in phone.links) LinkCheck(l, LinkStatus.unresolved)];
      }
    }
    AiAnswer? ai;
    if (input.aiScan && aiChecker != null) {
      try {
        ai = await aiChecker!(input.text);
      } catch (_) {}
    }
    return decideVerdict(text: input.text, phone: phone, links: links, aiScan: input.aiScan, ai: ai);
  }
}

const _order = [Verdict.looksSafe, Verdict.beCareful, Verdict.dangerous];

Verdict _atLeast(Verdict v, Verdict floor) => _order.indexOf(v) < _order.indexOf(floor) ? floor : v;

/// The verdict decision: spec rules 1-6, in order. Pure.
CheckResult decideVerdict({
  required String text,
  required PhoneCheck phone,
  required List<LinkCheck> links,
  required bool aiScan,
  AiAnswer? ai,
}) {
  bool has(LinkStatus s) => links.any((l) => l.status == s);
  final strong = [
    for (final s in phone.signs)
      if (s.strength == SignStrength.strong) s.code,
  ];
  final weak = [
    for (final s in phone.signs)
      if (s.strength == SignStrength.weak) s.code,
  ];
  // A sign quoting words that aren't in the text is dropped on its own.
  final aiSigns = [
    for (final s in ai?.signs ?? const <AiSign>[])
      if (s.quote == null || text.contains(s.quote!)) s.code,
  ];
  final useAi = aiScan && ai != null;

  final Verdict verdict;
  if (has(LinkStatus.flagged) || has(LinkStatus.shortenerBlocked)) {
    // Rule 1.
    verdict = Verdict.dangerous;
  } else {
    // Rules 2 and 3.
    var v = useAi ? _order[(ai.level.index + (strong.isEmpty ? 0 : 1)).clamp(0, 2)] : phone.verdict;
    // Rule 4.
    if ((useAi && aiSigns.contains('gambling_ad')) || weak.contains('gambling_ad')) v = _atLeast(v, Verdict.beCareful);
    // Rule 5.
    if (has(LinkStatus.opensApp)) v = _atLeast(v, Verdict.beCareful);
    // Rule 6: a warning beats Couldn't check, and Couldn't check beats Looks safe.
    if (has(LinkStatus.unresolved) && v == Verdict.looksSafe) v = Verdict.couldntCheck;
    verdict = v;
  }

  final reasons = <String>{
    if (has(LinkStatus.flagged)) 'flagged_link',
    if (has(LinkStatus.shortenerBlocked)) 'shortener_blocked',
    if (useAi) ...aiSigns,
    ...strong,
    if (has(LinkStatus.opensApp)) 'opens_app',
    if (has(LinkStatus.unresolved)) 'unresolved_link',
    ...weak,
  }.take(3).toList();
  if (reasons.isEmpty && verdict == Verdict.looksSafe) reasons.add(phone.harmlessPromo ? 'harmless_promo' : 'no_signs');

  return CheckResult(text: text, verdict: verdict, reasons: reasons, checkedOnPhone: links.isEmpty && ai == null);
}
