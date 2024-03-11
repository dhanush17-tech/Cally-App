import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;

  WaveformPainter({required this.amplitudes});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;

    double gap = size.width / amplitudes.length;
    for (int i = 0; i < amplitudes.length; i++) {
      double startX = i * gap;
      double endX = startX + gap;

      // Normalize amplitude to fit within the canvas height
      double normalizedHeight = (amplitudes[i] / 255) * size.height;
      double startY = size.height / 2 - normalizedHeight / 2;
      double endY = startY + normalizedHeight;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
