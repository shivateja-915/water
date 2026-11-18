import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class HydrationRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0+
  final int currentMl;
  final int goalMl;
  final double size;

  const HydrationRing({
    super.key,
    required this.progress,
    required this.currentMl,
    required this.goalMl,
    this.size = 200,
  });

  String _formatMl(int ml) {
    if (ml >= 1000) {
      return '${(ml / 1000).toStringAsFixed(1)}L';
    }
    return '${ml}ml';
  }

  @override
  Widget build(BuildContext context) {
    final isGoalReached = progress >= 1.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: animatedProgress,
                  isGoalReached: isGoalReached,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(animatedProgress * 100).round()}%',
                    style: AppTypography.numberLg.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _formatMl(currentMl),
                    style: AppTypography.numberSm.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GOAL: ${_formatMl(goalMl)}',
                    style: AppTypography.labelSm.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final bool isGoalReached;

  _RingPainter({required this.progress, required this.isGoalReached});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 16.0;

    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + AppSpacing.borderWidth * 2;
    canvas.drawCircle(center, radius, bgPaint);

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color =
          isGoalReached ? const Color(0xFFFFDE00) : const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final sweepAngle = 2 * math.pi * math.min(progress, 1.0);
    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isGoalReached != isGoalReached;
  }
}
