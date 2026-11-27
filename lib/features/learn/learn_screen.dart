import 'package:flutter/material.dart';

import '../../app/check_page.dart';
import '../../app/motion.dart';
import '../../app/read_aloud.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// The eight common PH scam topics, in display order. Content lives in the .arb files; sources in SOURCES.md beside this file.
const learnTopics = ['phishing', 'prize', 'family', 'aid', 'parcel', 'job', 'investment', 'gambling'];

// Phone-check reason codes that point to a topic. Weak signs like urgency or brand_mention fit too many topics.
const _topicByReason = {
  'otp_with_link': 'phishing',
  'credential_request': 'phishing',
  'lookalike_domain': 'phishing',
  'prize_claim': 'prize',
  'payment_request': 'prize',
  'family_money': 'family',
  'gambling_ad': 'gambling',
};

/// The Learn topic for a verdict's reasons (most decisive first), or null when none fits.
String? learnTopicFor(List<String> reasons) =>
    reasons.map((r) => _topicByReason[r]).firstWhere((t) => t != null, orElse: () => null);

/// A topic's red flags as (phrase quoted from its sample, why it's a red flag).
List<(String, String)> redFlags(AppLocalizations l, String topic) => [
  for (final line in l.learnTopicFlags(topic).split('\n'))
    if (line.split('|') case [final phrase, final why]) (phrase, why),
];

List<(String, String)> _lines(String text) => [
  for (final line in text.split('\n'))
    if (line.split('|') case [final name, final detail]) (name, detail),
];

/// The Learn tab: a yellow Golden rules card, the eight red-flag cards, then Report a scam.
/// Each card opens its own article page. Bundled, so it works offline.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key, this.readAloud, this.onCheckMessage});
  final ReadAloud? readAloud;

  /// Opens a message check from an article's button; no button when null.
  final VoidCallback? onCheckMessage;

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: UsisaColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                children: [
                  Eyebrow(l.learnEyebrow, color: UsisaColors.primary),
                  const SizedBox(height: 10),
                  Semantics(
                    header: true,
                    child: Text(
                      l.learnTitle,
                      style: tt.headlineLarge?.copyWith(fontSize: 34, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l.learnIntro, style: tt.bodyLarge?.copyWith(color: UsisaColors.inkMuted)),
                  const SizedBox(height: 24),
                  EnterMotion(
                    index: 1,
                    child: _GoldenCard(
                      onTap: () =>
                          _open(context, GoldenRulesScreen(readAloud: readAloud, onCheckMessage: onCheckMessage)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(header: true, child: Text(l.learnRedFlagsHeading, style: tt.titleLarge)),
                  const SizedBox(height: 14),
                  for (final (i, topic) in learnTopics.indexed)
                    EnterMotion(
                      index: i < 5 ? 2 + i : 0,
                      child: _TopicLinkCard(
                        topic: topic,
                        onTap: () => _open(
                          context,
                          LearnTopicScreen(topic: topic, readAloud: readAloud, onCheckMessage: onCheckMessage),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _ReportCard(onTap: () => _open(context, ReportScamScreen(readAloud: readAloud))),
                  const SizedBox(height: 20),
                  Text(l.learnSourcesNote, style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The yellow hero card with a ring in the corner; opens the Golden rules.
class _GoldenCard extends StatelessWidget {
  const _GoldenCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return PressScale(
      child: Material(
        color: UsisaColors.yellow,
        borderRadius: BorderRadius.circular(UsisaRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: ExcludeSemantics(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: UsisaColors.ink.withValues(alpha: 0.07), width: 30),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(l.learnGoldenTitle, color: UsisaColors.ink),
                    const SizedBox(height: 22),
                    Text(
                      l.learnGoldenHeadline,
                      style: tt.headlineLarge?.copyWith(fontSize: 38, fontWeight: FontWeight.w800, height: 1.08),
                    ),
                    const SizedBox(height: 14),
                    Text(l.learnGoldenLede, style: tt.bodyLarge),
                    const SizedBox(height: 22),
                    Text(
                      l.learnReadGuide,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A white red-flag card: topic in small capitals, its headline and one line; opens the topic.
class _TopicLinkCard extends StatelessWidget {
  _TopicLinkCard({required this.topic, required this.onTap}) : super(key: ValueKey('learn-card-$topic'));
  final String topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressScale(
        child: Material(
          color: UsisaColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: UsisaColors.hairline, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(l.learnTopicTitle(topic), color: UsisaColors.primary),
                  const SizedBox(height: 10),
                  Text(l.learnTopicHeadline(topic), style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(l.learnTopicTeaser(topic), style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lavender Report a scam box at the end of the list; opens where to report.
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return PressScale(
      child: Material(
        color: _calloutColor,
        borderRadius: BorderRadius.circular(UsisaRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.learnReportTitle, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(l.learnReportIntro, style: tt.bodyLarge?.copyWith(color: UsisaColors.inkMuted)),
                const SizedBox(height: 16),
                Text(
                  l.learnReportLink,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Lilac softened to a pale lavender; ink on it stays above 4.5:1.
final _calloutColor = Color.alphaBlend(UsisaColors.lilac.withValues(alpha: 0.5), UsisaColors.surface);

/// One Learn article page: back link, eyebrow, big title, lede, a short yellow rule, the body,
/// Read aloud, then the "Not sure? Check it first." box and an optional Check a message button.
class LearnArticle extends StatefulWidget {
  const LearnArticle({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.lede,
    required this.speech,
    required this.children,
    this.readAloud,
    this.onCheckMessage,
  });
  final String eyebrow;
  final String title;
  final String lede;

  /// The page's text in a given language, for Read aloud.
  final String Function(AppLocalizations l) speech;
  final List<Widget> children;
  final ReadAloud? readAloud;
  final VoidCallback? onCheckMessage;

  @override
  State<LearnArticle> createState() => _LearnArticleState();
}

class _LearnArticleState extends State<LearnArticle> {
  late final ReadAloud _readAloud = widget.readAloud ?? ReadAloud();

  @override
  void dispose() {
    _readAloud.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: UsisaColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  BackLink(l.backToLearn),
                  const SizedBox(height: 16),
                  Eyebrow(widget.eyebrow, color: UsisaColors.primary),
                  const SizedBox(height: 10),
                  Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      style: tt.headlineLarge?.copyWith(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.lede,
                    style: tt.titleMedium?.copyWith(color: UsisaColors.inkMuted, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ExcludeSemantics(
                      child: Container(
                        width: 56,
                        height: 5,
                        decoration: BoxDecoration(color: UsisaColors.yellow, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...widget.children,
                  const SizedBox(height: 24),
                  PressScale(
                    child: ReadAloudButton(
                      readAloud: _readAloud,
                      speechKey: widget.title,
                      onRead: () => readAloudWithNote(context, _readAloud, widget.speech, key: widget.title),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: _calloutColor, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.learnCalloutTitle, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(l.learnCalloutBody, style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted)),
                      ],
                    ),
                  ),
                  if (widget.onCheckMessage case final onCheck?) ...[
                    const SizedBox(height: 24),
                    PrimaryPillButton(label: l.learnCheckButton, onPressed: onCheck),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Golden rules article: three numbered habits.
class GoldenRulesScreen extends StatelessWidget {
  const GoldenRulesScreen({super.key, this.readAloud, this.onCheckMessage});
  final ReadAloud? readAloud;
  final VoidCallback? onCheckMessage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return LearnArticle(
      eyebrow: l.learnGoldenTitle,
      title: l.learnGoldenHeadline,
      lede: l.learnGoldenLede,
      readAloud: readAloud,
      onCheckMessage: onCheckMessage,
      speech: (l) => '${l.learnGoldenHeadline} ${l.learnGoldenRules.replaceAll('\n', ' ')}',
      children: [
        for (final (i, rule) in l.learnGoldenRules.split('\n').indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}.', style: tt.titleMedium),
                const SizedBox(width: 10),
                Expanded(child: Text(rule, style: tt.bodyLarge?.copyWith(height: 1.6))),
              ],
            ),
          ),
      ],
    );
  }
}

/// One scam topic: what it is, a sample fake text with its red flags highlighted, and why each is a red flag.
/// Opened from the Learn tab and from a verdict's Learn link.
class LearnTopicScreen extends StatelessWidget {
  const LearnTopicScreen({super.key, required this.topic, this.readAloud, this.onCheckMessage});
  final String topic;
  final ReadAloud? readAloud;
  final VoidCallback? onCheckMessage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final flags = redFlags(l, topic);
    return LearnArticle(
      key: ValueKey('learn-$topic'),
      eyebrow: l.learnTopicTitle(topic),
      title: l.learnTopicHeadline(topic),
      lede: l.learnTopicTeaser(topic),
      readAloud: readAloud,
      onCheckMessage: onCheckMessage,
      speech: (l) => [
        l.learnTopicTitle(topic),
        l.learnTopicAbout(topic),
        '${l.learnRedFlags}:',
        for (final (_, why) in redFlags(l, topic)) '$why.',
      ].join(' '),
      children: [
        Text(l.learnTopicAbout(topic), style: tt.bodyLarge?.copyWith(height: 1.6)),
        const SizedBox(height: 24),
        Text(l.learnSampleLabel, style: tt.titleMedium?.copyWith(color: UsisaColors.inkMuted)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: fieldDecoration(),
          child: Text.rich(_highlight(l.learnTopicSample(topic), [for (final (p, _) in flags) p], tt.bodyLarge)),
        ),
        const SizedBox(height: 20),
        Text(l.learnRedFlags, style: tt.titleMedium),
        for (final (phrase, why) in flags)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text.rich(
              TextSpan(
                style: tt.bodyLarge,
                children: [
                  TextSpan(
                    text: '"$phrase"',
                    style: const TextStyle(color: UsisaColors.danger, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ': $why'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Where to report a scam: the official channels.
class ReportScamScreen extends StatelessWidget {
  const ReportScamScreen({super.key, this.readAloud});
  final ReadAloud? readAloud;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return LearnArticle(
      eyebrow: l.navLearn,
      title: l.learnReportTitle,
      lede: l.learnReportIntro,
      readAloud: readAloud,
      speech: (l) => [
        l.learnReportTitle,
        l.learnReportIntro,
        for (final (name, detail) in _lines(l.learnReportChannels)) '$name. $detail',
      ].join(' '),
      children: [
        for (final (name, detail) in _lines(l.learnReportChannels))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: tt.titleMedium),
                const SizedBox(height: 2),
                Text(detail, style: tt.bodyLarge),
              ],
            ),
          ),
        Text(l.learnSourcesNote, style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted)),
      ],
    );
  }
}

/// [sample] with each of [phrases] shown bold on a danger tint (not colour alone: also bold, and listed below).
TextSpan _highlight(String sample, List<String> phrases, TextStyle? style) {
  final spans = <TextSpan>[];
  var at = 0;
  while (at < sample.length) {
    final hits = [
      for (final p in phrases)
        if (sample.indexOf(p, at) case final i when i >= 0) (i, p),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (hits.isEmpty) break;
    final (i, p) = hits.first;
    spans
      ..add(TextSpan(text: sample.substring(at, i)))
      ..add(
        TextSpan(
          text: p,
          style: const TextStyle(
            color: UsisaColors.danger,
            backgroundColor: UsisaColors.dangerTint,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    at = i + p.length;
  }
  spans.add(TextSpan(text: sample.substring(at)));
  return TextSpan(style: style, children: spans);
}
