import 'package:flutter/material.dart';

import '../../app/check_page.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// The four ways to start a Check from home.
enum CheckKind { message, link, screenshot, ai }

/// The Check tab: indigo header, lavender sheet with four icon-free tiles and the SMS card.
/// Fills the screen exactly; it only scrolls when very large text can't fit.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onCheck,
    required this.smsOn,
    required this.onSmsChanged,
    this.checkedToday = 0,
    this.protectionLost = false,
    this.onFix,
    this.clock = DateTime.now,
  });

  final ValueChanged<CheckKind> onCheck;
  final bool smsOn;
  final ValueChanged<bool> onSmsChanged;

  /// Texts the Incoming SMS check finished today, shown while protection is on.
  final int checkedToday;

  /// Protection was turned on but Android has a permission revoked: show the banner with Fix.
  final bool protectionLost;
  final VoidCallback? onFix;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    final hour = clock().hour;
    final greeting = hour < 12
        ? l.greetingMorning
        : hour < 18
        ? l.greetingAfternoon
        : l.greetingEvening;
    final tiles = [
      (CheckKind.message, l.tileMessageTitle, l.tileMessageSubtitle),
      (CheckKind.link, l.tileLinkTitle, l.tileLinkSubtitle),
      (CheckKind.screenshot, l.tileScreenshotTitle, l.tileScreenshotSubtitle),
      (CheckKind.ai, l.tileAiTitle, l.tileAiSubtitle),
    ];
    Widget row(int first, bool compact) => Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = first; i < first + 2; i++) ...[
            if (i > first) const SizedBox(width: 14),
            Expanded(
              child: EnterMotion(
                index: 2 + i,
                child: CheckTile(
                  kind: tiles[i].$1,
                  title: tiles[i].$2,
                  subtitle: tiles[i].$3,
                  onTap: () => onCheck(tiles[i].$1),
                  compact: compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return ColoredBox(
      color: UsisaColors.primary,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          // Short screens (small phones) get a tighter header and tiles so everything still fits.
          builder: (context, box) {
            final compact = box.maxHeight < 760;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        greeting: greeting,
                        headline: l.homeHeadline,
                        subtitle: l.homeSubtitle,
                        tagline: l.appTagline,
                        compact: compact,
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: UsisaColors.background,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(UsisaRadius.sheet)),
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (protectionLost) ...[
                                _ProtectionOffBanner(
                                  title: l.smsOffBanner,
                                  body: l.smsOffBannerBody,
                                  fix: l.smsFix,
                                  onFix: onFix,
                                ),
                                const SizedBox(height: 16),
                              ],
                              EnterMotion(
                                index: 1,
                                child: Text(l.homePrompt, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [row(0, compact), const SizedBox(height: 14), row(2, compact)],
                                ),
                              ),
                              const SizedBox(height: 14),
                              EnterMotion(
                                index: 6,
                                child: _SmsCard(
                                  eyebrow: l.smsCardEyebrow,
                                  title: l.smsCardTitle,
                                  status: smsOn ? l.smsCardChecked(checkedToday) : l.smsCardOff,
                                  value: smsOn,
                                  onChanged: onSmsChanged,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _dot(double size, Color color, {double? top, double? left, double? right, double? bottom}) => Positioned(
  top: top,
  left: left,
  right: right,
  bottom: bottom,
  child: Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  ),
);

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.headline,
    required this.subtitle,
    required this.tagline,
    this.compact = false,
  });
  final bool compact;
  final String greeting;
  final String headline;
  final String subtitle;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // The closing "?" of the headline is drawn in yellow.
    final mark = headline.endsWith('?') ? '?' : '';
    final words = headline.substring(0, headline.length - mark.length);
    // Shapes may run past the header's bottom edge: the sheet covers them, except at its rounded corners,
    // where they show through as in the design instead of leaving an indigo notch.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -70,
                  top: 40,
                  child: Drift(
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: const BoxDecoration(color: UsisaColors.yellow, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: .7), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -20,
                  bottom: -46,
                  child: Container(
                    width: 156,
                    height: 156,
                    decoration: const BoxDecoration(
                      color: UsisaColors.orange,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(156)),
                    ),
                  ),
                ),
                _dot(6, Colors.white, right: 96, top: 92),
                _dot(5, Colors.white, right: 130, bottom: 24),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, compact ? 18 : 26),
          child: EnterMotion(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Wordmark(color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white.withValues(alpha: .6)),
                          ),
                          child: Text(
                            tagline.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 18),
                Text(greeting, style: tt.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .9))),
                const SizedBox(height: 8),
                // Leaves room on the right for the yellow circle.
                FractionallySizedBox(
                  widthFactor: .78,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: words),
                        TextSpan(
                          text: mark,
                          style: const TextStyle(color: UsisaColors.yellow),
                        ),
                      ],
                    ),
                    style: tt.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: compact ? 30 : 36,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  Text(subtitle, style: tt.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .9))),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One bright check tile: colour, a geometric motif top-right, title and subtitle at the bottom.
class CheckTile extends StatelessWidget {
  const CheckTile({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.compact = false,
  });

  /// Less room above the words, for short screens.
  final bool compact;
  final CheckKind kind;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const _navy = Color(0xFF2E2A7A);

  // Tile colour and text colour; text contrast is 7:1 or better on each.
  static const _colors = {
    CheckKind.message: (UsisaColors.yellow, UsisaColors.ink),
    CheckKind.link: (Color(0xFFFFA586), UsisaColors.ink),
    CheckKind.screenshot: (Color(0xFFDCDAF8), UsisaColors.ink),
    CheckKind.ai: (UsisaColors.primary, Colors.white),
  };

  Widget _motif() => switch (kind) {
    // Two overlapping circles.
    CheckKind.message => Stack(
      children: [_dot(40, _navy, right: 40, top: 18), _dot(40, const Color(0xD9E08A00), right: 16, top: 18)],
    ),
    // A quarter shape.
    CheckKind.link => Positioned(
      right: 18,
      top: 16,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFFA6452E),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(52)),
        ),
      ),
    ),
    // A scatter of dots.
    CheckKind.screenshot => Stack(
      children: [
        for (final (r, t) in [
          (52.0, 16.0),
          (36.0, 12.0),
          (20.0, 18.0),
          (44.0, 30.0),
          (28.0, 28.0),
          (56.0, 44.0),
          (38.0, 46.0),
          (22.0, 42.0),
        ])
          _dot(7, const Color(0xFF7A72C9), right: r, top: t),
      ],
    ),
    // A thin ring with a yellow dot on its edge.
    CheckKind.ai => Stack(
      children: [
        Positioned(
          right: 22,
          top: 16,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.2),
            ),
          ),
        ),
        _dot(8, UsisaColors.yellow, right: 18, top: 35),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (tint, ink) = _colors[kind]!;
    return PressScale(
      child: Material(
        color: tint,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UsisaRadius.card)),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(child: Stack(children: [_motif()])),
              ),
              Padding(
                // Top padding leaves room for the motif above the words.
                padding: EdgeInsets.fromLTRB(18, compact ? 50 : 64, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: tt.titleLarge?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: tt.bodySmall?.copyWith(color: ink.withValues(alpha: .85))),
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

class _SmsCard extends StatelessWidget {
  const _SmsCard({
    required this.eyebrow,
    required this.title,
    required this.status,
    required this.value,
    required this.onChanged,
  });
  final String eyebrow;
  final String title;
  final String status;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(UsisaRadius.card),
      child: ColoredBox(
        color: UsisaColors.primary,
        child: Stack(
          children: [
            // Decoration stays on the left so nothing sits behind the switch.
            Positioned(
              left: -40,
              bottom: -60,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)),
              ),
            ),
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(child: Eyebrow(eyebrow, color: Colors.white.withValues(alpha: .75))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(status, style: tt.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: .9))),
                        ],
                      ),
                    ),
                    Switch(
                      value: value,
                      onChanged: onChanged,
                      activeThumbColor: UsisaColors.primary,
                      activeTrackColor: UsisaColors.yellow,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: .3),
                      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectionOffBanner extends StatelessWidget {
  const _ProtectionOffBanner({required this.title, required this.body, required this.fix, required this.onFix});
  final String title;
  final String body;
  final String fix;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        decoration: BoxDecoration(
          color: UsisaColors.dangerTint,
          borderRadius: BorderRadius.circular(UsisaRadius.card),
          border: Border.all(color: UsisaColors.danger, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.titleMedium?.copyWith(color: UsisaColors.danger)),
                  const SizedBox(height: 2),
                  Text(body, style: tt.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onFix,
              style: FilledButton.styleFrom(
                backgroundColor: UsisaColors.danger,
                shape: const StadiumBorder(),
                minimumSize: const Size(64, 48),
              ),
              child: Text(fix),
            ),
          ],
        ),
      ),
    );
  }
}
