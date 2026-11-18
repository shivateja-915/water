import 'dart:math';
import 'package:flutter/material.dart';

class FloatingParticles extends StatefulWidget {
  final int count;
  final Color color;

  const FloatingParticles({
    super.key,
    this.count = 25,
    this.color = const Color(0xFF3BA7FF),
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particles = List.generate(
      widget.count,
      (index) => _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.05 + _random.nextDouble() * 0.1,
        size: 2.0 + _random.nextDouble() * 4.0,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color.withValues(alpha: 0.1),
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double size;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    for (var particle in particles) {
      // Calculate y based on progress and speed. Wraps around 0 to 1.
      double currentY = particle.y - (progress * particle.speed * 10);
      currentY = currentY - currentY.floor(); // Wrap around

      final xPos = particle.x * size.width;
      final yPos = currentY * size.height;

      // Add a slight sine wave to x for organic movement
      final xOffset = sin((progress * 2 * pi) + (particle.y * 10)) * 5;

      canvas.drawCircle(Offset(xPos + xOffset, yPos), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

