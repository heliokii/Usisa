// PROTOTYPE (throwaway): Variant A, "Tile grid". Layered geometric indigo header, white sheet,
// the four features as a 2x2 grid of bright tiles (no icons, each has its own shape), SMS protection card underneath.
// Life comes from bolder colour, a slow-floating header shape, a staggered entrance and press feedback.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'shared.dart';

class VariantA extends StatelessWidget {
  const VariantA({super.key, required this.showVerdict, required this.verdict, required this.onCheck, required this.onBack});
  static const name = 'Tile grid';
  final bool showVerdict;
  final Verdict verdict;
  final VoidCallback onCheck;
  final VoidCallback onBack;

  // Bright tile colours with their motif colour; ink text on them is 9.8:1 to 11.2:1.
  static const tileColors = [
    (Color(0xFFFFD66B), Color(0xFFE08A00)), // message: sunny yellow
    (Color(0xFFC9C7FF), Color(0xFF4A44C9)), // link: lilac
    (Color(0xFFA8E6D4), Color(0xFF0F8A6E)), // screenshot: mint
    (Color(0xFFFFC2B8), Color(0xFFE5484D)), // AI: coral
  ];

  @override
  Widget build(BuildContext context) {
    if (showVerdict) return VerdictScreen(verdict: verdict, onBack: onBack);
    final tt = Theme.of(context).textTheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Magandang umaga!' : hour < 18 ? 'Magandang hapon!' : 'Magandang gabi!';
    return Scaffold(
      backgroundColor: T.primary,
      bottomNavigationBar: const ProtoNav(),
      body: SafeArea(
        bottom: false,
        child: ListView(padding: EdgeInsets.zero, children: [
          SizedBox(
            height: 230,
            child: Stack(clipBehavior: Clip.hardEdge, children: [
              const _Float(child: SizedBox(width: 150, height: 150, child: DecoratedBox(decoration: BoxDecoration(color: T.yellow, shape: BoxShape.circle))), right: -36, top: -30),
              Positioned(right: -10, bottom: 20, child: Container(width: 110, height: 110, decoration: const BoxDecoration(color: Color(0xFFFF8A4C), borderRadius: BorderRadius.only(topLeft: Radius.circular(110))))),
              Positioned(right: 118, top: 60, child: Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 6)))),
              dot(22, T.coral, right: 70, top: 140),
              dot(10, Colors.white, right: 190, top: 34),
              dot(14, T.yellow, left: 180, bottom: 44),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
                child: _Enter(index: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(greeting, style: tt.titleMedium?.copyWith(color: Colors.white.withValues(alpha: .9))),
                  const SizedBox(height: 4),
                  Text('Is this text\na scam?', style: tt.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.1)),
                ])),
              ),
            ]),
          ),
          Container(
            decoration: const BoxDecoration(color: T.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Enter(index: 1, child: Text('What do you want to check?', style: tt.titleLarge?.copyWith(color: T.ink, fontWeight: FontWeight.w800))),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: .95,
                children: [for (var i = 0; i < features.length; i++) _Enter(index: 2 + i, child: _Tile(i: i, feature: features[i], onTap: onCheck))],
              ),
              const SizedBox(height: 20),
              const _Enter(index: 6, child: SmsCard()),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({required this.i, required this.feature, required this.onTap});
  final int i;
  final Feature feature;
  final VoidCallback onTap;
  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool down = false;

  Widget _motif(int i, Color c) => switch (i) {
        0 => Stack(children: [dot(84, c.withValues(alpha: .35), right: -22, top: -22), dot(26, c, right: 50, top: 34)]),
        1 => Stack(children: [Positioned(right: -24, top: -24, child: Container(width: 96, height: 96, decoration: BoxDecoration(color: c.withValues(alpha: .4), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(96)))))]),
        2 => Stack(children: [dot(32, c.withValues(alpha: .7), right: 16, top: 16), dot(32, c.withValues(alpha: .35), right: 54, top: 16), dot(32, c.withValues(alpha: .35), right: 16, top: 54)]),
        _ => Stack(children: [dot(64, c.withValues(alpha: .3), right: 12, top: 12), dot(28, c, right: 30, top: 30)]),
      };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final (tint, accent) = VariantA.tileColors[widget.i];
    return GestureDetector(
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: down ? .96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(28)),
          child: Stack(children: [
            Positioned.fill(child: _motif(widget.i, accent)),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Spacer(),
                Text(widget.feature.title, style: tt.titleMedium?.copyWith(color: T.ink, fontWeight: FontWeight.w800, height: 1.15)),
                const SizedBox(height: 4),
                Text(widget.feature.subtitle, style: tt.bodySmall?.copyWith(color: T.ink.withValues(alpha: .78))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Staggered entrance: fade + 16px rise, 320ms ease-out, 60ms apart. Skipped when the phone asks for reduced motion.
class _Enter extends StatelessWidget {
  const _Enter({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 60),
      curve: Interval(index * 60 / (320 + index * 60), 1, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * 16), child: c)),
      child: child,
    );
  }
}

/// The big header circle drifts a few pixels, slowly. Still under reduced motion.
class _Float extends StatefulWidget {
  const _Float({required this.child, this.right, this.top});
  final Widget child;
  final double? right;
  final double? top;
  @override
  State<_Float> createState() => _FloatState();
}

class _FloatState extends State<_Float> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return Positioned(
      right: widget.right,
      top: widget.top,
      child: AnimatedBuilder(
        animation: c,
        builder: (_, child) => Transform.translate(offset: still ? Offset.zero : Offset(math.sin(c.value * 2 * math.pi) * 6, math.cos(c.value * 2 * math.pi) * 6), child: child),
        child: widget.child,
      ),
    );
  }
}
