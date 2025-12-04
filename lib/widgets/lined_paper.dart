import 'package:flutter/material.dart';

class LinedPaper extends StatelessWidget {
  final Widget child;
  final double lineSpacing;
  final EdgeInsetsGeometry padding;

  const LinedPaper({
    super.key,
    required this.child,
    this.lineSpacing = 28.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? theme.colorScheme.surface : theme.colorScheme.surface;
    final lineColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);

    return Container(
      color: background,
      child: Stack(
        children: [
          CustomPaint(
            painter:
                _LinedPaperPainter(lineColor: lineColor, spacing: lineSpacing),
            size: Size.infinite,
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LinedPaperPainter extends CustomPainter {
  final Color lineColor;
  final double spacing;

  _LinedPaperPainter({required this.lineColor, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _LinedPaperPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.spacing != spacing;
  }
}
