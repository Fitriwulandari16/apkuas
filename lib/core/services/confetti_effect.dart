import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiEffect extends StatefulWidget {
  final bool isPlaying;
  const ConfettiEffect({super.key, required this.isPlaying});

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = List.generate(50, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (widget.isPlaying) _controller.forward();
  }

  @override
  void didUpdateWidget(ConfettiEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.reset();
      _controller.forward();
    }
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
          painter: ConfettiPainter(particles: particles, progress: _controller.value),
          child: Container(),
        );
      },
    );
  }
}

class Particle {
  late double x;
  late double y;
  late Color color;
  late double size;
  late double velocity;
  late double angle;

  Particle() {
    reset();
  }

  void reset() {
    x = Random().nextDouble();
    y = -0.1;
    color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
    size = Random().nextDouble() * 10 + 5;
    velocity = Random().nextDouble() * 2 + 1;
    angle = Random().nextDouble() * pi * 2;
  }
}

class ConfettiPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    for (var p in particles) {
      double currentY = p.y + (progress * p.velocity);
      double currentX = p.x + (sin(progress * 5 + p.angle) * 0.05);
      
      final paint = Paint()..color = p.color.withOpacity(1 - progress);
      canvas.drawRect(
        Rect.fromLTWH(currentX * size.width, currentY * size.height, p.size, p.size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
