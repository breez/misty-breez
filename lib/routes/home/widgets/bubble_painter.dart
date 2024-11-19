import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';

const double _kBubbleRadius = 12;

class BubblePainter extends CustomPainter {
  final BuildContext context;

  late Paint bubblePaint;

  BubblePainter(
    this.context,
  ) {
    bubblePaint = Paint()
      ..color = Theme.of(context).bubblePaintColor
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    size = MediaQuery.of(context).size;
    final double height = (size.height - kToolbarHeight);
    canvas.drawCircle(
      Offset(size.width / 2, height * 0.4),
      _kBubbleRadius,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.39, height * 0.6),
      _kBubbleRadius * 1.5,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, height * 0.7),
      _kBubbleRadius * 1.25,
      bubblePaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, height * 0.8),
      _kBubbleRadius * 0.75,
      bubblePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
