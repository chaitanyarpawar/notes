import 'package:flutter/material.dart';

class LinedPaper extends StatelessWidget {
  final Widget child;
  final double lineSpacing;
  final EdgeInsetsGeometry padding;
  final bool showLines;

  const LinedPaper({
    super.key,
    required this.child,
    this.lineSpacing = 28.0, // Good spacing for handwriting
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.showLines = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background =
        isDark ? theme.colorScheme.surface : theme.colorScheme.surface;

    // More visible lines - blue tint like ruled paper
    final lineColor = isDark
        ? const Color(0xFF4A90E2)
            .withValues(alpha: 0.25) // Blue lines for dark mode
        : const Color(0xFFB8D4E8); // Light blue lines like ruled paper

    return Container(
      color: background,
      child: Stack(
        children: [
          if (showLines)
            CustomPaint(
              painter: _LinedPaperPainter(
                lineColor: lineColor,
                spacing: lineSpacing,
              ),
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
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Start from first line position
    double y = spacing;
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
