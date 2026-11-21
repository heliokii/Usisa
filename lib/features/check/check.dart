import 'package:image_picker/image_picker.dart';

import '../scan/scan_models.dart';
import 'phone_check.dart';

export 'phone_check.dart' show PhoneCheck, Sign, SignStrength, isOfficialLink, phoneCheck;

/// The single answer a Check gives (GLOSSARY.md).
enum Verdict { looksSafe, beCareful, dangerous, couldntCheck }

/// Where the checked content came from.
enum CheckSource { message, link, screenshot, share, sms }

class CheckInput {
  const CheckInput(this.text, {required this.source, this.aiScan = false}) : image = null;

  /// A screenshot whose text is read first (OCR).
  const CheckInput.image(XFile this.image, {this.aiScan = false}) : text = '', source = CheckSource.screenshot;

  final String text;
  final XFile? image;
  final CheckSource source;
  final bool aiScan;
}

/// What the online link check found for one link.
enum LinkStatus { clean, flagged, shortenerBlocked, opensApp, unresolved }

class LinkCheck {
  const LinkCheck(this.link, this.status, {this.destination, this.hops = const []});
  final String link;
  final LinkStatus status;

  /// The Real destination after all redirects, when the gateway saw it.
  final String? destination;

  /// The redirect steps the gateway followed.
  final List<String> hops;
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
  const CheckResult({
    required this.text,
    required this.verdict,
    required this.reasons,
    required this.checkedOnPhone,
    this.destinations = const [],
    this.evidence = const [],
    this.aiUnavailable = false,
  });
  final String text;
  final Verdict verdict;

  /// At most 3 reason codes, most decisive first. The screen localizes them.
  final List<String> reasons;

  /// True when no online check (link or AI) gave an answer.
  final bool checkedOnPhone;

  /// Real destinations of the checked links, shown as "Really goes to ...".
  final List<String> destinations;

  /// Words from [text] the AI quoted as warning signs, highlighted on the verdict screen.
  final List<String> evidence;

  /// An AI scan the AI couldn't answer: shown as "AI couldn't look at this right now".
  final bool aiUnavailable;
}

typedef LinkChecker = Future<List<LinkCheck>> Function(List<String> links);
/// Asks the AI about [text], with what the online link check saw of its links. Null when it can't answer.
typedef AiChecker = Future<AiAnswer?> Function(String text, List<LinkCheck> links);

/// Reads the text in a picture (OCR). Throws [ScanException] when it can't.
typedef TextReader = Future<String> Function(XFile image);

/// What screens call to run a Check; [CheckPipeline.run] in the app, a fake in widget tests.
typedef RunCheck = Future<CheckResult> Function(CheckInput input);

/// The one entry point that runs a Check: phone check, online link check, AI, then the verdict.
/// Pass a checker only when the person has consented to online checks.
class CheckPipeline {
  const CheckPipeline({this.linkChecker, this.aiChecker, this.readText});
  final LinkChecker? linkChecker;
  final AiChecker? aiChecker;
  final TextReader? readText;

  /// Throws [ScanException] when a screenshot can't be read or has no text: no verdict is given.
  Future<CheckResult> run(CheckInput input) async {
    if (input.image != null) {
      if (readText == null) throw const ScanException('ocrUnavailable');
      final text = await readText!(input.image!);
      if (text.trim().isEmpty) throw const ScanException('noText');
      input = CheckInput(text, source: input.source, aiScan: input.aiScan);
    }
    final phone = phoneCheck(input.text);
    final pasted = input.text.trim();
    // A pasted link the phone check can't spot still goes online, so it is never passed as safe.
    final found = phone.links.isEmpty && input.source == CheckSource.link && pasted.isNotEmpty ? [pasted] : phone.links;
    final web = [for (final l in found) if (!opensApp(l)) l];
    var links = [for (final l in found) if (opensApp(l)) LinkCheck(l, LinkStatus.opensApp)];
    final online = linkChecker != null && web.isNotEmpty;
    if (online) {
      try {
        links = [...links, ...await linkChecker!(web)];
      } catch (_) {
        // Any failure means the links weren't checked, never that they're clean.
        links = [...links, for (final l in web) LinkCheck(l, LinkStatus.unresolved)];
      }
    } else {
      // Online checks declined: a link the phone can't judge is unchecked, never safe (rule 6).
      links = [...links, for (final l in web) if (!isOfficialLink(l)) LinkCheck(l, LinkStatus.unresolved)];
    }
    AiAnswer? ai;
    if (input.aiScan && aiChecker != null) {
      try {
        ai = await aiChecker!(input.text, links);
      } catch (_) {}
    }
    return decideVerdict(
      text: input.text,
      phone: phone,
      links: links,
      aiScan: input.aiScan,
      ai: ai,
      checkedOnline: online,
    );
  }
}

/// Whether a Check would send anything online: an AI scan, a text with a link, or Check a link.
bool needsOnline(CheckInput input) =>
    input.aiScan || input.source == CheckSource.link || phoneCheck(input.text).links.isNotEmpty;

/// A link with a non-web scheme (intent: and the like) that opens an app instead of a website.
bool opensApp(String link) {
  final scheme = RegExp(r'^([a-z][a-z0-9+-]*):(?!\d)', caseSensitive: false).firstMatch(link)?[1]?.toLowerCase();
  return scheme != null && scheme != 'http' && scheme != 'https';
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

  /// Whether the online link check ran; defaults to "some link has a result".
  bool? checkedOnline,
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
  final kept = [
    for (final s in ai?.signs ?? const <AiSign>[])
      if (s.quote == null || text.contains(s.quote!)) s,
  ];
  final aiSigns = [for (final s in kept) s.code];
  final useAi = aiScan && ai != null;

  final Verdict verdict;
  if (has(LinkStatus.flagged) || has(LinkStatus.shortenerBlocked)) {
    // Rule 1.
    verdict = Verdict.dangerous;
  } else {
    // Rules 2 and 3.
    var v = useAi ? _order[(ai.level.index + (strong.isEmpty ? 0 : 1)).clamp(0, 2)] : phone.verdict;
    // Rule 4.
    if (useAi && aiSigns.contains('gambling_ad')) v = _atLeast(v, Verdict.beCareful);
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
  if (reasons.isEmpty && verdict == Verdict.looksSafe) reasons.add('no_signs');

  return CheckResult(
    text: text,
    verdict: verdict,
    reasons: reasons,
    checkedOnPhone: !(checkedOnline ?? links.isNotEmpty) && ai == null,
    destinations: {for (final l in links) ?l.destination}.toList(),
    evidence: useAi ? {for (final s in kept) ?s.quote}.toList() : const [],
    aiUnavailable: aiScan && ai == null,
  );
}
