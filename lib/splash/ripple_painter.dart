import 'package:flutter/material.dart';

class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  RipplePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 * 2.4; // Scale up to 2.4

    // 3 ripple rings with slightly offset scales and opacities
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.15;
      final currentAnimValue = (animationValue - delay).clamp(0.0, 1.0);
      
      if (currentAnimValue > 0) {
        final radius = maxRadius * currentAnimValue;
        // Opacity goes from 40% (0.4) down to 0%
        final opacity = 0.4 * (1.0 - currentAnimValue);
        
        final paint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

