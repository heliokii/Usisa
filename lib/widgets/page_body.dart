import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.showBrandWave = true,
    this.horizontalGutter,
    this.bottomPadding = 32,
    this.fillViewport = false,
    this.scrollable = true,
  });
  final Widget child;
  final bool showBrandWave;
  final double? horizontalGutter;
  final double bottomPadding;
  final bool fillViewport;
  final bool scrollable;
  static double gutterOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < 360
        ? 16
        : width >= 600
        ? 32
        : 20;
  }

  @override
  Widget build(BuildContext context) {
    final gutter = horizontalGutter ?? gutterOf(context);
    return LayoutBuilder(
      builder: (context, viewport) => Stack(
        children: [
          if (showBrandWave)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 42,
              child: BrandWave(),
            ),
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: scrollable ? null : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(gutter, 20, gutter, bottomPadding),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 720,
                  minHeight: fillViewport
                      ? (viewport.maxHeight - 20 - bottomPadding)
                            .clamp(0.0, double.infinity)
                            .toDouble()
                      : 0,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandWave extends StatelessWidget {
  const BrandWave({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/illustrations/brand_wave.svg',
      fit: BoxFit.fill,
    ),
  );
}
