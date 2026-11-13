import 'package:flutter/material.dart';

class UsisaActionButtonPainter extends CustomPainter {
  const UsisaActionButtonPainter({this.danger = false});

  final bool danger;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final green = [
      const Color(0xFF168363),
      const Color(0xFF0D6B51),
      const Color(0xFF075440),
      const Color(0xFF033E31),
    ];
    final coral = [
      const Color(0xFFFF806A),
      const Color(0xFFF2452E),
      const Color(0xFFDC3325),
      const Color(0xFFB92E22),
    ];
    final colors = danger ? coral : green;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: const [0, .3, .7, 1],
        ).createShader(bounds),
    );

    final width = size.width;
    final height = size.height;
    final upperCurve = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height * .25)
      ..cubicTo(
        width * .72,
        height * .22,
        width * .62,
        height * .3,
        width * .43,
        height * .32,
      )
      ..cubicTo(
        width * .24,
        height * .34,
        width * .14,
        height * .4,
        0,
        height * .57,
      )
      ..close();
    canvas.drawPath(
      upperCurve,
      Paint()
        ..color = (danger ? const Color(0xFFFFA291) : const Color(0xFF31A078))
            .withValues(alpha: .28),
    );

    final middleCurve = Path()
      ..moveTo(0, height * .57)
      ..cubicTo(
        width * .18,
        height * .4,
        width * .32,
        height * .5,
        width * .51,
        height * .55,
      )
      ..cubicTo(
        width * .72,
        height * .6,
        width * .82,
        height * .32,
        width,
        height * .3,
      )
      ..lineTo(width, height * .5)
      ..cubicTo(
        width * .8,
        height * .52,
        width * .67,
        height * .71,
        width * .47,
        height * .7,
      )
      ..cubicTo(
        width * .26,
        height * .69,
        width * .15,
        height * .61,
        0,
        height * .77,
      )
      ..close();
    canvas.drawPath(
      middleCurve,
      Paint()
        ..color = (danger ? const Color(0xFFED5A43) : const Color(0xFF126D51))
            .withValues(alpha: .52),
    );

    final lowerCurve = Path()
      ..moveTo(0, height * .77)
      ..cubicTo(
        width * .2,
        height * .62,
        width * .35,
        height * .78,
        width * .55,
        height * .79,
      )
      ..cubicTo(
        width * .78,
        height * .8,
        width * .87,
        height * .62,
        width,
        height * .55,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(
      lowerCurve,
      Paint()
        ..color = (danger ? const Color(0xFF9D241B) : const Color(0xFF013C30))
            .withValues(alpha: .38),
    );
  }

  @override
  bool shouldRepaint(UsisaActionButtonPainter oldDelegate) =>
      danger != oldDelegate.danger;
}
