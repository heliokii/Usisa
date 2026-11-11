import 'package:flutter/material.dart';

import '../theme/usisa_theme.dart';

class GlassSurface extends StatefulWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.focusHighlight = false,
    this.showShadow = true,
  });

  final Widget child;
  final Color? color;
  final BorderRadiusGeometry borderRadius;
  final bool focusHighlight;
  final bool showShadow;

  @override
  State<GlassSurface> createState() => _GlassSurfaceState();
}

class _GlassSurfaceState extends State<GlassSurface> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.surface;
    final shine = color.computeLuminance() < .24 ? .12 : .36;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 150);
    final surface = AnimatedContainer(
      duration: duration,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, shine)!,
            Color.lerp(color, UsisaTheme.cream, .12)!,
            color,
          ],
          stops: const [0, .3, 1],
        ),
        boxShadow: [
          if (widget.showShadow) ...[
            BoxShadow(
              color: Colors.white.withValues(alpha: .62),
              offset: const Offset(0, -1),
              blurRadius: 5,
              spreadRadius: -1,
            ),
            BoxShadow(
              color: UsisaTheme.forest.withValues(alpha: .08),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
            BoxShadow(
              color: UsisaTheme.forest.withValues(alpha: .12),
              offset: const Offset(0, 5),
              blurRadius: 13,
              spreadRadius: -2,
            ),
          ],
          if (_focused && widget.focusHighlight)
            BoxShadow(
              color: UsisaTheme.coral.withValues(alpha: .24),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );
    if (!widget.focusHighlight) return surface;
    return Focus(
      skipTraversal: true,
      onFocusChange: (focused) {
        if (focused != _focused) setState(() => _focused = focused);
      },
      child: surface,
    );
  }
}
