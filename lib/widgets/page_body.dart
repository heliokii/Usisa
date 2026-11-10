import 'package:flutter/material.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child});
  final Widget child;
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
    final gutter = gutterOf(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 32),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: child,
        ),
      ),
    );
  }
}
