import 'package:flutter/widgets.dart';

import 'theme.dart';

/// The Usisa mark (design/icon/usisa-mark.svg): a message bubble and a "second look" lens over its corner,
/// orange where they overlap.
/// [bubble] scales the bubble in (0 to 1); [lens] glides the lens from up-right onto the bubble (0 to 1).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 120, this.bubble = 1, this.lens = 1});
  final double size;
  final double bubble;
  final double lens;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Usisa',
    child: CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(bubble: bubble, lens: lens),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.bubble, required this.lens});
  final double bubble;
  final double lens;

  // Geometry on the 256 canvas of usisa-mark.svg; the mark's own centre is about (136, 124).
  static final _bubble = Path()
    ..moveTo(72, 213.3)
    ..arcToPoint(const Offset(34.7, 164.7), radius: const Radius.circular(80), largeArc: true, clockwise: false)
    ..cubicTo(31, 186, 27, 206, 26, 220)
    ..arcToPoint(const Offset(39, 229), radius: const Radius.circular(9), clockwise: false)
    ..cubicTo(51, 225, 62, 220, 72, 213.3)
    ..close();
  static const _bubbleCentre = Offset(112, 144);
  static const _lensCentre = Offset(177, 88);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Fit the mark's bounding box (26..247 x 18..229) into the square.
    final k = size.width / 228;
    canvas.scale(k);
    canvas.translate(-22.5, -14);

    final b = bubble.clamp(0.0, 1.2);
    final bubblePath = _bubble.transform(
      (Matrix4.identity()
            ..translateByDouble(_bubbleCentre.dx, _bubbleCentre.dy, 0, 1)
            ..scaleByDouble(b, b, 1, 1)
            ..translateByDouble(-_bubbleCentre.dx, -_bubbleCentre.dy, 0, 1))
          .storage,
    );
    final t = lens.clamp(0.0, 1.0);
    final centre = _lensCentre + Offset(46, -46) * (1 - t);
    final lensPath = Path()..addOval(Rect.fromCircle(center: centre, radius: 70));

    canvas.drawPath(bubblePath, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawPath(lensPath, Paint()..color = UsisaColors.yellow.withValues(alpha: t));
    canvas.drawPath(
      Path.combine(PathOperation.intersect, bubblePath, lensPath),
      Paint()..color = UsisaColors.orange.withValues(alpha: t),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.bubble != bubble || old.lens != lens;
}
