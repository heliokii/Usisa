import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// The four ways to start a Check from home.
enum CheckKind { message, link, screenshot, ai }

/// The Check tab: indigo header, lavender sheet with four icon-free tiles and the SMS card.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onCheck,
    required this.smsOn,
    required this.onSmsChanged,
    this.clock = DateTime.now,
  });

  final ValueChanged<CheckKind> onCheck;
  final bool smsOn;
  final ValueChanged<bool> onSmsChanged;
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
    return ColoredBox(
      color: UsisaColors.primary,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(greeting: greeting, headline: l.homeHeadline)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: UsisaColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(UsisaRadius.sheet)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Enter(index: 1, child: Text(l.homePrompt, style: tt.titleLarge)),
                    const SizedBox(height: 16),
                    // Rows instead of a fixed-ratio grid so large text grows the tiles instead of clipping.
                    for (var row = 0; row < 2; row++) ...[
                      if (row > 0) const SizedBox(height: 14),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var col = 0; col < 2; col++) ...[
                              if (col > 0) const SizedBox(width: 14),
                              Expanded(
                                child: _Enter(
                                  index: 2 + row * 2 + col,
                                  child: _Tile(
                                    kind: tiles[row * 2 + col].$1,
                                    title: tiles[row * 2 + col].$2,
                                    subtitle: tiles[row * 2 + col].$3,
                                    onTap: () => onCheck(tiles[row * 2 + col].$1),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _Enter(
                      index: 6,
                      child: _SmsCard(
                        title: l.smsCardTitle,
                        status: smsOn ? l.smsCardOn : l.smsCardOff,
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
    );
  }
}

Widget _dot(double size, Color color, {double? top, double? left, double? right, double? bottom}) =>
    Positioned(
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
  const _Header({required this.greeting, required this.headline});
  final String greeting;
  final String headline;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: Stack(
              children: [
                const _Drift(
                  right: -36,
                  top: -30,
                  child: SizedBox.square(
                    dimension: 150,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: UsisaColors.yellow, shape: BoxShape.circle),
                    ),
                  ),
                ),
                Positioned(
                  right: -10,
                  bottom: 20,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: UsisaColors.orange,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(110)),
                    ),
                  ),
                ),
                Positioned(
                  right: 118,
                  top: 60,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 6),
                    ),
                  ),
                ),
                _dot(22, UsisaColors.coralDot, right: 70, top: 140),
                _dot(10, Colors.white, right: 190, top: 34),
                _dot(14, UsisaColors.yellow, left: 180, bottom: 44),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 48),
          child: _Enter(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: tt.titleMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(headline, style: tt.headlineLarge?.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({required this.kind, required this.title, required this.subtitle, required this.onTap});
  final CheckKind kind;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _down = false;

  // Tile colour and its motif colour; ink on each tile is 9.8:1 or better.
  static const _colors = {
    CheckKind.message: (UsisaColors.yellow, Color(0xFFE08A00)),
    CheckKind.link: (UsisaColors.lilac, UsisaColors.primary),
    CheckKind.screenshot: (UsisaColors.mint, Color(0xFF0F8A6E)),
    CheckKind.ai: (UsisaColors.coral, Color(0xFFE5484D)),
  };

  Widget _motif(Color c) => switch (widget.kind) {
    // Two circles.
    CheckKind.message => Stack(
      children: [
        _dot(84, c.withValues(alpha: .35), right: -22, top: -22),
        _dot(26, c, right: 50, top: 34),
      ],
    ),
    // Quarter circle.
    CheckKind.link => Stack(
      children: [
        Positioned(
          right: -24,
          top: -24,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: c.withValues(alpha: .4),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(96)),
            ),
          ),
        ),
      ],
    ),
    // Dot cluster.
    CheckKind.screenshot => Stack(
      children: [
        _dot(32, c.withValues(alpha: .7), right: 16, top: 16),
        _dot(32, c.withValues(alpha: .35), right: 54, top: 16),
        _dot(32, c.withValues(alpha: .35), right: 16, top: 54),
      ],
    ),
    // Ring.
    CheckKind.ai => Stack(
      children: [
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c, width: 10),
            ),
          ),
        ),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (tint, accent) = _colors[widget.kind]!;
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: _down && !still ? .96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: tint,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UsisaRadius.card)),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (down) => setState(() => _down = down),
          child: Stack(
            children: [
              Positioned.fill(child: ExcludeSemantics(child: _motif(accent))),
              Padding(
                // Top padding leaves room for the motif above the words.
                padding: const EdgeInsets.fromLTRB(18, 72, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(widget.title, style: tt.titleMedium?.copyWith(height: 1.15)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle, style: tt.bodySmall),
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
  const _SmsCard({required this.title, required this.status, required this.value, required this.onChanged});
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
            _dot(70, const Color(0xFF6C66E0), left: -30, bottom: -36),
            _dot(16, UsisaColors.yellow, left: 140, top: -6),
            MergeSemantics(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: tt.titleMedium?.copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(status, style: tt.bodyMedium?.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    Switch(
                      value: value,
                      onChanged: onChanged,
                      activeThumbColor: UsisaColors.primary,
                      activeTrackColor: UsisaColors.yellow,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: .25),
                      trackOutlineColor: const WidgetStatePropertyAll(Colors.white),
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

/// Staggered entrance: fade and 16px rise, 320ms ease-out, 60ms apart. Off under reduced motion.
class _Enter extends StatelessWidget {
  const _Enter({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = index * 60;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delay),
      curve: Interval(delay / (320 + delay), 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
      ),
      child: child,
    );
  }
}

/// The big header circle drifts slowly on a 6s loop. Still under reduced motion.
class _Drift extends StatefulWidget {
  const _Drift({required this.child, this.right, this.top});
  final Widget child;
  final double? right;
  final double? top;

  @override
  State<_Drift> createState() => _DriftState();
}

class _DriftState extends State<_Drift> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    right: widget.right,
    top: widget.top,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final a = _c.value * 2 * math.pi;
        return Transform.translate(offset: Offset(math.sin(a) * 6, math.cos(a) * 6), child: child);
      },
      child: widget.child,
    ),
  );
}
