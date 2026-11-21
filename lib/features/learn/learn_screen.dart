import 'package:flutter/material.dart';

import '../../app/motion.dart';
import '../../app/read_aloud.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// The eight common PH scam topics, in display order. Content lives in the .arb files; sources in docs/learn_sources.md.
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

/// The Learn tab: Golden rules, the eight topic cards, then Report a scam. Bundled, so it works offline.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, this.readAloud});
  final ReadAloud? readAloud;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Semantics(header: true, child: Text(l.navLearn, style: tt.headlineSmall)),
          const SizedBox(height: 4),
          Text(l.learnIntro, style: tt.bodyLarge?.copyWith(color: UsisaColors.inkMuted)),
          const SizedBox(height: 16),
          LearnCard(
            title: l.learnGoldenTitle,
            color: UsisaColors.yellow,
            readAloud: _readAloud,
            speech: (l) => '${l.learnGoldenTitle}. ${l.learnGoldenRules.replaceAll('\n', ' ')}',
            children: [
              for (final (i, rule) in l.learnGoldenRules.split('\n').indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}.', style: tt.titleMedium),
                      const SizedBox(width: 10),
                      Expanded(child: Text(rule, style: tt.bodyLarge)),
                    ],
                  ),
                ),
            ],
          ),
          for (final topic in learnTopics) TopicCard(topic: topic, readAloud: _readAloud),
          LearnCard(
            title: l.learnReportTitle,
            color: UsisaColors.mint,
            readAloud: _readAloud,
            speech: (l) => [
              l.learnReportTitle,
              l.learnReportIntro,
              for (final (name, detail) in _lines(l.learnReportChannels)) '$name. $detail',
            ].join(' '),
            children: [
              Text(l.learnReportIntro, style: tt.bodyLarge),
              for (final (name, detail) in _lines(l.learnReportChannels)) ...[
                const SizedBox(height: 12),
                Text(name, style: tt.titleMedium),
                Text(detail, style: tt.bodyLarge),
              ],
            ],
          ),
          Text(l.learnSourcesNote, style: tt.bodyMedium?.copyWith(color: UsisaColors.inkMuted)),
        ],
      ),
    );
  }
}

/// One scam topic: what it is, a sample fake text with its red flags highlighted, and why each is a red flag.
class TopicCard extends StatelessWidget {
  TopicCard({required this.topic, required this.readAloud}) : super(key: ValueKey('learn-$topic'));
  final String topic;
  final ReadAloud readAloud;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final flags = redFlags(l, topic);
    return LearnCard(
      title: l.learnTopicTitle(topic),
      color: UsisaColors.lilac,
      readAloud: readAloud,
      speech: (l) => [
        l.learnTopicTitle(topic),
        l.learnTopicAbout(topic),
        '${l.learnRedFlags}:',
        for (final (_, why) in redFlags(l, topic)) '$why.',
      ].join(' '),
      children: [
        Text(l.learnTopicAbout(topic), style: tt.bodyLarge),
        const SizedBox(height: 16),
        Text(l.learnSampleLabel, style: tt.titleMedium?.copyWith(color: UsisaColors.inkMuted)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: UsisaColors.background, borderRadius: BorderRadius.circular(20)),
          child: Text.rich(_highlight(l.learnTopicSample(topic), [for (final (p, _) in flags) p], tt.bodyLarge)),
        ),
        const SizedBox(height: 16),
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

/// A white Learn card with a colour stripe, a title, its content and an outlined Read aloud button.
class LearnCard extends StatelessWidget {
  const LearnCard({
    super.key,
    required this.title,
    required this.color,
    required this.readAloud,
    required this.speech,
    required this.children,
  });
  final String title;
  final Color color;
  final ReadAloud readAloud;

  /// The card's text in a given language, for Read aloud.
  final String Function(AppLocalizations l) speech;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: UsisaColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UsisaRadius.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(child: Container(height: 10, color: color)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(title, style: tt.titleLarge)),
                  const SizedBox(height: 10),
                  ...children,
                  const SizedBox(height: 16),
                  PressScale(
                    child: OutlinedButton(
                      onPressed: () => readAloudWithNote(context, readAloud, speech),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: UsisaColors.primary,
                        side: const BorderSide(color: UsisaColors.primary, width: 1.5),
                        minimumSize: const Size.fromHeight(56),
                        shape: const StadiumBorder(),
                        textStyle: tt.titleMedium,
                      ),
                      child: Text(AppLocalizations.of(context).readAloud, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One topic on its own page, opened from a verdict's Learn link.
class LearnTopicScreen extends StatefulWidget {
  const LearnTopicScreen({super.key, required this.topic, this.readAloud});
  final String topic;
  final ReadAloud? readAloud;

  @override
  State<LearnTopicScreen> createState() => _LearnTopicScreenState();
}

class _LearnTopicScreenState extends State<LearnTopicScreen> {
  late final ReadAloud _readAloud = widget.readAloud ?? ReadAloud();

  @override
  void dispose() {
    _readAloud.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: UsisaColors.background, title: Text(AppLocalizations.of(context).navLearn)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [TopicCard(topic: widget.topic, readAloud: _readAloud)],
    ),
  );
}
