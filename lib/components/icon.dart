import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'foundation.dart';

enum ImHereGlyph {
  place,
  friends,
  add,
  history,
  settings,
  bell,
  home,
  back,
  chevron,
  close,
  check,
  person,
}

class ImHereIcon extends StatelessWidget {
  const ImHereIcon({
    super.key,
    required this.glyph,
    this.size = 24,
    this.color,
  });

  final ImHereGlyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final extent = ImHereMetrics.of(context).resolve(size);
    return CustomPaint(
      size: Size.square(extent),
      painter: _ImHereIconPainter(
        glyph,
        color ?? IconTheme.of(context).color ?? ImHereColors.of(context).text,
      ),
    );
  }
}

class _ImHereIconPainter extends CustomPainter {
  const _ImHereIconPainter(this.glyph, this.color);

  final ImHereGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (glyph) {
      case ImHereGlyph.place:
        canvas.drawPath(
          Path()
            ..moveTo(12, 21)
            ..cubicTo(9.5, 18, 4.5, 12.8, 4.5, 9.5)
            ..arcToPoint(
              const Offset(19.5, 9.5),
              radius: const Radius.circular(7.5),
            )
            ..cubicTo(19.5, 12.8, 14.5, 18, 12, 21)
            ..close(),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 9.5), 2.4, stroke);
      case ImHereGlyph.friends:
        canvas.drawCircle(const Offset(9, 8.5), 3, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 20)
            ..cubicTo(3.5, 16.2, 5.4, 14.5, 9, 14.5)
            ..cubicTo(12.6, 14.5, 14.5, 16.2, 14.5, 20),
          stroke,
        );
        canvas.drawPath(
          Path()..arcTo(
            Rect.fromCircle(center: const Offset(17.5, 9.5), radius: 2.5),
            -math.pi * 0.65,
            math.pi * 1.3,
            false,
          ),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(17.5, 15)
            ..cubicTo(20.2, 15, 21.5, 16.7, 21.5, 20),
          stroke,
        );
      case ImHereGlyph.add:
        canvas.drawLine(const Offset(12, 4), const Offset(12, 20), stroke);
        canvas.drawLine(const Offset(4, 12), const Offset(20, 12), stroke);
      case ImHereGlyph.history:
        canvas.drawArc(
          const Rect.fromLTWH(4, 4, 16, 16),
          -math.pi * 0.75,
          math.pi * 1.7,
          false,
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4, 4.5)
            ..lineTo(4, 9.5)
            ..lineTo(9, 9.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12, 7.5)
            ..lineTo(12, 12)
            ..lineTo(15, 13.5),
          stroke,
        );
      case ImHereGlyph.settings:
        canvas.drawLine(const Offset(4, 6), const Offset(9, 6), stroke);
        canvas.drawLine(const Offset(15, 6), const Offset(20, 6), stroke);
        canvas.drawCircle(const Offset(12, 6), 3, stroke);
        canvas.drawLine(const Offset(4, 18), const Offset(10, 18), stroke);
        canvas.drawLine(const Offset(16, 18), const Offset(20, 18), stroke);
        canvas.drawCircle(const Offset(13, 18), 3, stroke);
      case ImHereGlyph.bell:
        canvas.drawPath(
          Path()
            ..moveTo(5, 17)
            ..lineTo(7, 14.5)
            ..lineTo(7, 10)
            ..cubicTo(7, 6.9, 9, 5, 12, 5)
            ..cubicTo(15, 5, 17, 6.9, 17, 10)
            ..lineTo(17, 14.5)
            ..lineTo(19, 17)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 20)
            ..quadraticBezierTo(12, 22, 14, 20),
          stroke,
        );
      case ImHereGlyph.home:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 10.5)
            ..lineTo(12, 3.5)
            ..lineTo(20.5, 10.5)
            ..moveTo(5.5, 9.5)
            ..lineTo(5.5, 20)
            ..lineTo(18.5, 20)
            ..lineTo(18.5, 9.5),
          stroke,
        );
      case ImHereGlyph.back:
        canvas.drawPath(
          Path()
            ..moveTo(14.5, 5)
            ..lineTo(7.5, 12)
            ..lineTo(14.5, 19),
          stroke,
        );
      case ImHereGlyph.person:
        canvas.drawCircle(const Offset(12, 8.5), 3.5, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 20)
            ..cubicTo(4.5, 15.6, 7.5, 14, 12, 14)
            ..cubicTo(16.5, 14, 19.5, 15.6, 19.5, 20),
          stroke,
        );
      case ImHereGlyph.check:
        canvas.drawPath(
          Path()
            ..moveTo(5, 12.5)
            ..lineTo(10, 17.5)
            ..lineTo(19, 7),
          stroke,
        );
      case ImHereGlyph.close:
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), stroke);
        canvas.drawLine(const Offset(18, 6), const Offset(6, 18), stroke);
      case ImHereGlyph.chevron:
        canvas.drawPath(
          Path()
            ..moveTo(9.5, 5)
            ..lineTo(16.5, 12)
            ..lineTo(9.5, 19),
          stroke,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ImHereIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
