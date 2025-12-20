import 'package:flutter/material.dart';
import 'dart:math' as math;

class AppBrandIcon extends StatelessWidget {
  final double size;
  const AppBrandIcon({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppBrandPainter(),
      ),
    );
  }
}

class _AppBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Orange rounded square background
    final bgPaint = Paint()..color = const Color(0xFFFF9500);
    final cornerRadius = size.width * 0.22;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(rect, bgPaint);

    // Horizontal lines (lighter orange/tan color)
    final linePaint = Paint()
      ..color = const Color(0xFFE8A040)
      ..strokeWidth = size.height * 0.028
      ..strokeCap = StrokeCap.round;

    final leftPad = size.width * 0.12;
    final rightPad = size.width * 0.12;
    final topPad = size.height * 0.15;
    final gap = size.height * 0.145;

    // Draw 5 horizontal lines
    for (int i = 0; i < 5; i++) {
      final y = topPad + gap * i;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        linePaint,
      );
    }

    // Pencil - positioned diagonally from upper-left to lower-right
    final pencilLen = size.width * 0.58;
    final pencilThickness = size.width * 0.12;
    const double pencilAngle = math.pi / 4; // 45 degrees
    final pencilCenter = Offset(size.width * 0.62, size.height * 0.68);

    canvas.save();
    canvas.translate(pencilCenter.dx, pencilCenter.dy);
    canvas.rotate(pencilAngle);

    // Pencil body (white with rounded ends)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(0, 0),
        width: pencilLen,
        height: pencilThickness,
      ),
      Radius.circular(pencilThickness * 0.5),
    );
    final bodyPaint = Paint()..color = Colors.white;
    canvas.drawRRect(bodyRect, bodyPaint);

    // Pencil tip (yellow triangle on right side)
    final tipPath = Path();
    final tipStartX = pencilLen * 0.40;
    tipPath.moveTo(tipStartX, -pencilThickness * 0.5);
    tipPath.lineTo(pencilLen * 0.58, 0);
    tipPath.lineTo(tipStartX, pencilThickness * 0.5);
    tipPath.close();
    final tipPaint = Paint()..color = const Color(0xFFFFD966);
    canvas.drawPath(tipPath, tipPaint);

    // Yellow dot on pencil body (grip/eraser detail)
    final dotPaint = Paint()..color = const Color(0xFFFFD966);
    canvas.drawCircle(
      Offset(-pencilLen * 0.08, 0),
      pencilThickness * 0.28,
      dotPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
