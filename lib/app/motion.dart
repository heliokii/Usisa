import 'dart:math' as math;

import 'package:flutter/widgets.dart';

// DESIGN.md motion. Every widget here goes still when the phone asks for reduced motion.

/// Staggered entrance: fade and 16px rise, 320ms ease-out, [index] x 60ms after the screen appears.
class EnterMotion extends StatelessWidget {
  const EnterMotion({super.key, required this.index, required this.child});
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

/// Shrinks [child] to 0.96 over 120ms while a finger is on it. Wrap any tile or button.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down && !MediaQuery.disableAnimationsOf(context) ? .96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Moves [child] in a 6px circle on a slow 6s loop. Use for one big decorative shape per screen.
class Drift extends StatefulWidget {
  const Drift({super.key, required this.child});
  final Widget child;

  @override
  State<Drift> createState() => _DriftState();
}

class _DriftState extends State<Drift> with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) {
      final a = _c.value * 2 * math.pi;
      return Transform.translate(offset: Offset(math.sin(a) * 6, math.cos(a) * 6), child: child);
    },
    child: widget.child,
  );
}

/// Page change for every pushed screen: the new page fades in while rising 4% (280ms, ease-out);
/// the page underneath dims slightly. Reduced motion: an instant swap.
class UsisaPageTransitionsBuilder extends PageTransitionsBuilder {
  const UsisaPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final under = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: .6).animate(under),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(enter),
          child: child,
        ),
      ),
    );
  }
}

/// Like [IndexedStack], but the newly shown child fades and rises in (220ms) when [index] changes.
/// Every child keeps its state; hidden ones are offstage with their tickers paused.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: 1);

  @override
  void didUpdateWidget(FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MediaQuery.disableAnimationsOf(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, child) in widget.children.indexed)
          Offstage(
            offstage: i != widget.index,
            child: TickerMode(
              enabled: i == widget.index,
              child: i == widget.index
                  ? FadeTransition(
                      opacity: t,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, .015), end: Offset.zero).animate(t),
                        child: child,
                      ),
                    )
                  : child,
            ),
          ),
      ],
    );
  }
}

/// Grows [child] from 60% with a slight overshoot and fades it in (420ms, after [delay]). For a verdict's mark.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = delay.inMilliseconds + 420;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay.inMilliseconds / total, 1, curve: Curves.easeOutBack),
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: .6 + .4 * t, child: child),
      ),
      child: child,
    );
  }
}

/// Three dots that rise and fall in turn while something is working. Reduced motion: still dots.
class BusyDots extends StatefulWidget {
  const BusyDots({super.key, this.color = const Color(0xFFFFFFFF), this.size = 7});
  final Color color;
  final double size;

  @override
  State<BusyDots> createState() => _BusyDotsState();
}

class _BusyDotsState extends State<BusyDots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

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
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * .35),
              child: Transform.translate(
                // Each dot lifts during its own third of the cycle.
                offset: Offset(0, -widget.size * .7 * math.max(0, math.sin((_c.value - i / 3) * 2 * math.pi))),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
