// note_liner.dart
import 'package:flutter/material.dart';

class NotebookLiner extends StatelessWidget {
  final Widget child;
  final bool showHorizontalLines;

  const NotebookLiner({
    super.key,
    required this.child,
    this.showHorizontalLines = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: CustomPaint(
        foregroundPainter: showHorizontalLines ? _NotebookPainter() : null,
        child: child,
      ),
    );
  }
}

class _NotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Red Margin Line (Vertical)
    final marginPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.0;
    const marginX = 0.0;
    canvas.drawLine(
      Offset(marginX, 0),
      Offset(marginX, size.height),
      marginPaint,
    );

    // Blue Horizontal Lines
    final linePaint = Paint()
      ..color = Colors.blue.shade100
      ..strokeWidth = 1.0;
    const lineHeight = 24.0; // Standard line height
    for (double i = lineHeight; i < size.height; i += lineHeight) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
