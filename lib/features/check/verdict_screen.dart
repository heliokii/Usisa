import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/motion.dart';
import '../../app/read_aloud.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../learn/learn_screen.dart';
import 'check.dart';
import 'verdict_actions.dart';

/// Colour, tint and icon for each Verdict. Colour is never the only carrier: each also has an icon and a word.
const verdictLooks = {
  Verdict.looksSafe: (UsisaColors.safe, UsisaColors.safeTint, Icons.check_circle_rounded),
  Verdict.beCareful: (UsisaColors.careful, UsisaColors.carefulTint, Icons.error_rounded),
  Verdict.dangerous: (UsisaColors.danger, UsisaColors.dangerTint, Icons.dangerous_rounded),
  Verdict.couldntCheck: (UsisaColors.unknown, UsisaColors.unknownTint, Icons.help_rounded),
};

/// Displays a Check result: verdict-coloured header, then a white sheet with the action line and reasons.
class VerdictScreen extends StatelessWidget {
  const VerdictScreen({super.key, required this.result, this.checkedAt, this.onCheckAgain, this.onAskAi, this.readAloud, this.share});
  final CheckResult result;

  /// Read aloud and Send to family; widget tests pass fakes, otherwise the phone's own.
  final ReadAloud? readAloud;
  final ShareText? share;

  /// Set when reopening a saved History entry: shows "Checked on" with the date and time.
  final DateTime? checkedAt;

  /// Shown as Check again on a reopened History entry.
  final VoidCallback? onCheckAgain;

  /// Shown as Ask AI to look closer; the caller decides when it applies.
  final VoidCallback? onAskAi;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final (color, tint, icon) = verdictLooks[result.verdict]!;
    final verdict = result.verdict.name;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: color,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: Stack(
                          children: [
                            _circle(150, Colors.white.withValues(alpha: .12), right: -40, top: -50),
                            _circle(60, UsisaColors.yellow.withValues(alpha: .9), right: 90, top: 30),
                            _circle(22, UsisaColors.coral, right: 40, top: 120),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BackButton(color: Colors.white),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 8),
                            child: EnterMotion(
                              index: 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(icon, color: Colors.white, size: 44),
                                  const SizedBox(height: 10),
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      l.verdictWord(verdict),
                                      style: tt.headlineLarge?.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  if (result.checkedOnPhone) ...[
                                    const SizedBox(height: 4),
                                    Text(l.checkedOnPhone, style: tt.bodyMedium?.copyWith(color: Colors.white)),
                                  ],
                                  if (result.aiUnavailable) ...[
                                    const SizedBox(height: 4),
                                    Text(l.aiUnavailable, style: tt.bodyMedium?.copyWith(color: Colors.white)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: UsisaColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(UsisaRadius.sheet)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EnterMotion(
                        index: 1,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            l.verdictAction(verdict),
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w500, height: 1.35),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      EnterMotion(
                        index: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(header: true, child: Text(l.verdictWhy, style: tt.titleLarge)),
                            const SizedBox(height: 8),
                            for (final code in result.reasons)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 7),
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(l.reason(code), style: tt.bodyLarge)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (learnTopicFor(result.reasons) case final topic?)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => LearnTopicScreen(topic: topic, readAloud: readAloud),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: EdgeInsets.zero,
                              foregroundColor: UsisaColors.primary,
                              textStyle: tt.titleMedium?.copyWith(decoration: TextDecoration.underline),
                            ),
                            child: Text(l.learnMore(l.learnTopicTitle(topic))),
                          ),
                        ),
                      for (final destination in result.destinations) ...[
                        const SizedBox(height: 16),
                        Text(l.reallyGoesTo(destination), style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                      if (onAskAi != null) ...[
                        const SizedBox(height: 24),
                        PressScale(
                          child: FilledButton(
                            onPressed: onAskAi,
                            style: FilledButton.styleFrom(
                              backgroundColor: UsisaColors.primary,
                              minimumSize: const Size.fromHeight(56),
                              shape: const StadiumBorder(),
                              textStyle: tt.titleMedium,
                            ),
                            child: Text(l.askAiLookCloser),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      VerdictActions(result: result, readAloud: readAloud, share: share),
                      const SizedBox(height: 24),
                      EnterMotion(
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.youChecked, style: tt.titleMedium?.copyWith(color: UsisaColors.inkMuted)),
                            const SizedBox(height: 4),
                            Text.rich(
                              _highlight(
                                result.text,
                                result.evidence,
                                const TextStyle(
                                  color: UsisaColors.ink,
                                  fontWeight: FontWeight.w700,
                                  backgroundColor: UsisaColors.yellow,
                                ),
                              ),
                              style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      if (checkedAt != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          l.checkedOnDate(formatCheckedAt(context, checkedAt!)),
                          style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted),
                        ),
                      ],
                      if (onCheckAgain != null) ...[
                        const SizedBox(height: 12),
                        PressScale(
                          child: FilledButton(
                            onPressed: onCheckAgain,
                            style: FilledButton.styleFrom(
                              backgroundColor: UsisaColors.primary,
                              minimumSize: const Size.fromHeight(56),
                              shape: const StadiumBorder(),
                              textStyle: tt.titleMedium,
                            ),
                            child: Text(l.checkAgain),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [text] with every occurrence of each AI quote marked, so the person sees the evidence themselves.
TextSpan _highlight(String text, List<String> quotes, TextStyle mark) {
  final marked = List.filled(text.length, false);
  for (final q in quotes.where((q) => q.isNotEmpty)) {
    for (var i = text.indexOf(q); i >= 0; i = text.indexOf(q, i + q.length)) {
      marked.fillRange(i, i + q.length, true);
    }
  }
  final spans = <TextSpan>[];
  for (var start = 0; start < text.length;) {
    var end = start;
    while (end < text.length && marked[end] == marked[start]) {
      end++;
    }
    spans.add(TextSpan(text: text.substring(start, end), style: marked[start] ? mark : null));
    start = end;
  }
  return TextSpan(children: spans);
}

/// Date and time in the app's language, e.g. "Nov 21, 2026, 3:05 PM".
String formatCheckedAt(BuildContext context, DateTime at) {
  final m = MaterialLocalizations.of(context);
  return '${m.formatMediumDate(at)}, ${m.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
}

Widget _circle(double size, Color color, {double? top, double? right}) => Positioned(
  top: top,
  right: right,
  child: Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  ),
);
