import 'package:flutter/material.dart';

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
    final bgPaint = Paint()..color = const Color(0xFFFF9500);

    final rect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: const Radius.circular(32),
      topRight: const Radius.circular(32),
      bottomLeft: const Radius.circular(32),
      bottomRight: const Radius.circular(32),
    );
    canvas.drawRRect(rect, bgPaint);

    // Lines
    final linePaint = Paint()
      ..color = const Color(0xFFFFD083)
      ..strokeWidth = size.height * 0.04
      ..strokeCap = StrokeCap.round;

    final leftPad = size.width * 0.14;
    final rightPad = size.width * 0.10;
    final topPad = size.height * 0.22;
    final gap = size.height * 0.17;

    for (int i = 0; i < 4; i++) {
      final y = topPad + gap * i;
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width - rightPad, y), linePaint);
    }

    // Pencil base (white body)
    final pencilLen = size.width * 0.55;
    final pencilThickness = size.width * 0.12;
    const double pencilAngle = -0.35; // radians
    final center = Offset(size.width * 0.60, size.height * 0.68);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pencilAngle);

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

    // Pencil tip (triangle)
    final tipWidth = pencilThickness * 0.9;
    final tipHeight = tipWidth;
    final tipPath = Path()
      ..moveTo(pencilLen * 0.5, 0)
      ..lineTo(pencilLen * 0.5 - tipHeight, -tipWidth * 0.5)
      ..lineTo(pencilLen * 0.5 - tipHeight, tipWidth * 0.5)
      ..close();
    final tipPaint = Paint()..color = const Color(0xFFFFC54D);
    canvas.drawPath(tipPath, tipPaint);

    // Pencil grip (small rounded yellow)
    final gripPaint = Paint()..color = const Color(0xFFFFD083);
    final gripRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-pencilLen * 0.1, 0),
        width: pencilThickness * 0.9,
        height: pencilThickness * 0.9,
      ),
      Radius.circular(pencilThickness * 0.45),
    );
    canvas.drawRRect(gripRect, gripPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
