import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'brand_mark.dart';
import 'theme.dart';

/// The launch screen drawn over the app while it loads: the home header's yellow circle and orange quarter
/// grow in, the wordmark rises and its dot pops, then everything fades into the app.
/// It never blocks taps and stays up only until the app is [ready] and the short intro has played.
/// Reduced motion: a still frame that fades out as soon as the app is ready.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.ready, required this.onDone});
  final bool ready;
  final VoidCallback onDone;

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash> with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((_) => _maybeLeave());
    _exit.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      _intro.forward();
    }
  }

  @override
  void didUpdateWidget(LaunchSplash old) {
    super.didUpdateWidget(old);
    _maybeLeave();
  }

  void _maybeLeave() {
    if (widget.ready && _intro.isCompleted && _exit.isDismissed) _exit.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _exit.dispose();
    super.dispose();
  }

  Animation<double> _part(double from, double to, [Curve curve = Curves.easeOutCubic]) => CurvedAnimation(
    parent: _intro,
    curve: Interval(from, to, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final circle = _part(0, .5);
    final quarter = _part(.1, .6);
    final bubble = _part(0, .4, Curves.easeOutBack);
    final lens = _part(.25, .65);
    final word = _part(.45, .85);
    final dot = _part(.7, 1, Curves.easeOutBack);
    return IgnorePointer(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: FadeTransition(
          opacity: ReverseAnimation(_exit),
          child: Material(
            color: UsisaColors.primary,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  Positioned(
                    right: -90,
                    top: box.maxHeight * .12,
                    // A faint ring echoes the mark's lens without competing with it.
                    child: ScaleTransition(
                      scale: circle,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: .14), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: -40,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(-.4, .4), end: Offset.zero).animate(quarter),
                      child: FadeTransition(
                        opacity: quarter,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: const BoxDecoration(
                            color: UsisaColors.orange,
                            borderRadius: BorderRadius.only(topRight: Radius.circular(220)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The bubble pops in, then the lens glides onto it and the overlap lights up.
                          ExcludeSemantics(
                            child: AnimatedBuilder(
                              animation: _intro,
                              builder: (_, _) => BrandMark(size: 112, bubble: bubble.value, lens: lens.value),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Semantics(
                            label: 'Usisa',
                            excludeSemantics: true,
                            // Shrinks on very narrow screens instead of overflowing.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  FadeTransition(
                                    opacity: word,
                                    child: SlideTransition(
                                      position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(word),
                                      child: const Text('usisa', style: _wordStyle, textScaler: TextScaler.noScaling),
                                    ),
                                  ),
                                  ScaleTransition(
                                    scale: dot,
                                    child: const Text(
                                      '.',
                                      style: TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800,
                                        color: UsisaColors.orange,
                                        height: 1,
                                      ),
                                      textScaler: TextScaler.noScaling,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: dot,
                            child: Text(
                              l.appTagline.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .85),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                              ),
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
        ),
      ),
    );
  }
}

const _wordStyle = TextStyle(
  fontSize: 56,
  fontWeight: FontWeight.w800,
  color: Colors.white,
  letterSpacing: -1.5,
  height: 1,
);
