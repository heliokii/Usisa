import 'package:flutter/material.dart';

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.horizontalGutter,
    this.bottomPadding = 32,
    this.fillViewport = false,
    this.scrollable = true,
  });
  final Widget child;
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
      builder: (context, viewport) {
        final scrollBody = SingleChildScrollView(
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
        );
        return scrollBody;
      },
    );
  }
}
