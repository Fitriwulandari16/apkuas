import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
import 'dart:math' as math;

class HotAirBalloonColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const HotAirBalloonColoringScreen({super.key, this.levelId = 10});

  @override
  ConsumerState<HotAirBalloonColoringScreen> createState() => _HotAirBalloonColoringScreenState();
}

class _HotAirBalloonColoringScreenState extends ConsumerState<HotAirBalloonColoringScreen> with TickerProviderStateMixin {
  late AnimationController _flyController;
  late Animation<Offset> _flyAnimation;
  late AnimationController _cloudController;
  late AnimationController _bobController;

  final List<_BalloonShape> _shapes = [];
  bool _isComplete = false;

  final Map<IconData, Color> _rule = {
    Icons.square: Colors.blue,
    Icons.circle: Colors.green,
    Icons.change_history: Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _flyAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.5)).animate(CurvedAnimation(parent: _flyController, curve: Curves.easeInOutBack));
    
    _cloudController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _bobController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _generateShapes();
  }

  void _generateShapes() {
    final random = math.Random();
    final icons = [Icons.square, Icons.circle, Icons.change_history];
    for (int i = 0; i < 9; i++) {
      // Improved distribution: centered in the balloon's upper circular area
      double angle = random.nextDouble() * 2 * math.pi;
      double radius = random.nextDouble() * 0.25; // Keep it in the middle 50%
      
      _shapes.add(_BalloonShape(
        icon: icons[i % 3],
        position: Offset(0.5 + radius * math.cos(angle), 0.35 + radius * math.sin(angle)),
        currentColor: Colors.white.withOpacity(0.8),
        bobDelay: random.nextDouble(),
      ));
    }
  }

  void _onShapeTap(int index) {
    if (_isComplete) return;
    setState(() {
      _shapes[index].currentColor = _rule[_shapes[index].icon]!;
    });
    HapticService.light();
    _checkWin();
  }

  void _checkWin() {
    bool allCorrect = _shapes.every((s) => s.currentColor == _rule[s.icon]);
    if (allCorrect) {
      _onWin();
    }
  }

  void _onWin() {
    setState(() => _isComplete = true);
    HapticService.success();
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _flyController.forward().then((_) {
        if (mounted) Navigator.pop(context);
      });
    });
  }

  @override
  void dispose() {
    _flyController.dispose();
    _cloudController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3E5FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildPalette(),
            Expanded(
              child: Stack(
                children: [
                  _buildAnimatedClouds(),
                  
                  SlideTransition(
                    position: _flyAnimation,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 0.8,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Detailed Balloon
                                Positioned.fill(
                                  child: CustomPaint(painter: _DetailedBalloonPainter()),
                                ),
                                // Interactive Shapes
                                ...List.generate(_shapes.length, (i) {
                                  final shape = _shapes[i];
                                  return AnimatedBuilder(
                                    animation: _bobController,
                                    builder: (context, child) {
                                      final bobOffset = math.sin((_bobController.value + shape.bobDelay) * 2 * math.pi) * 8;
                                      return Positioned(
                                        left: shape.position.dx * constraints.maxWidth - 25,
                                        top: shape.position.dy * constraints.maxHeight - 25 + bobOffset,
                                        child: child!,
                                      );
                                    },
                                    child: GestureDetector(
                                      onTap: () => _onShapeTap(i),
                                      child: _ShapeIcon(shape: shape),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Warnai Balon Udara',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2E4482), letterSpacing: 1),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PaletteItem(icon: Icons.square, color: Colors.blue, label: 'Kotak'),
          _PaletteItem(icon: Icons.circle, color: Colors.green, label: 'Lingkaran'),
          _PaletteItem(icon: Icons.change_history, color: Colors.red, label: 'Segitiga'),
        ],
      ),
    );
  }

  Widget _buildAnimatedClouds() {
    return AnimatedBuilder(
      animation: _cloudController,
      builder: (context, child) {
        return Stack(
          children: [
            _Cloud(top: 80, left: (_cloudController.value * 500) - 150, size: 100, opacity: 0.4),
            _Cloud(top: 220, left: ((1 - _cloudController.value) * 500) - 100, size: 140, opacity: 0.3),
            _Cloud(top: 450, left: (_cloudController.value * 450), size: 120, opacity: 0.5),
          ],
        );
      },
    );
  }
}

class _ShapeIcon extends StatelessWidget {
  final _BalloonShape shape;
  const _ShapeIcon({required this.shape});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: shape.currentColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: shape.currentColor.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: Icon(shape.icon, color: shape.currentColor == Colors.white.withOpacity(0.8) ? Colors.blueGrey.shade200 : Colors.white, size: 30),
      ),
    );
  }
}

class _PaletteItem extends StatelessWidget {
  final IconData icon; final Color color; final String label;
  const _PaletteItem({required this.icon, required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _Cloud extends StatelessWidget {
  final double top, left, size, opacity;
  const _Cloud({required this.top, required this.left, required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, left: left,
      child: Icon(Icons.cloud, size: size, color: Colors.white.withOpacity(opacity)),
    );
  }
}

class _DetailedBalloonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final balloonTop = size.height * 0.4;
    final balloonWidth = size.width * 0.75;
    final balloonHeight = size.height * 0.65;

    // 1. Draw Balloon Main Body with segments
    final List<Color> panelColors = [
      Colors.orange.shade400,
      Colors.yellow.shade600,
      Colors.orange.shade300,
      Colors.yellow.shade500,
      Colors.orange.shade500,
    ];

    for (int i = 0; i < 5; i++) {
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [panelColors[i], panelColors[i].withOpacity(0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
      final double startAngle = -math.pi + (i * math.pi / 5);
      final double sweepAngle = math.pi / 5;
      
      final path = Path()
        ..moveTo(centerX, balloonHeight * 0.9)
        ..arcTo(Rect.fromLTWH(centerX - balloonWidth/2, 0, balloonWidth, balloonHeight), startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, paint);
    }

    // 2. Draw Basket Ropes
    final ropePaint = Paint()..color = Colors.brown.shade300..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(centerX - balloonWidth * 0.25, balloonHeight * 0.75), Offset(centerX - 40, size.height * 0.85), ropePaint);
    canvas.drawLine(Offset(centerX + balloonWidth * 0.25, balloonHeight * 0.75), Offset(centerX + 40, size.height * 0.85), ropePaint);
    canvas.drawLine(Offset(centerX, balloonHeight * 0.8), Offset(centerX, size.height * 0.85), ropePaint);

    // 3. Draw Wicker Basket
    final basketRect = Rect.fromLTWH(centerX - 45, size.height * 0.85, 90, 50);
    final basketPaint = Paint()..color = Colors.brown.shade600..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(basketRect, const Radius.circular(10)), basketPaint);
    
    // Basket Texture (simple lines)
    final wickerPaint = Paint()..color = Colors.brown.shade800.withOpacity(0.3)..strokeWidth = 2;
    for (double y = basketRect.top + 5; y < basketRect.bottom; y += 10) {
      canvas.drawLine(Offset(basketRect.left, y), Offset(basketRect.right, y), wickerPaint);
    }
    for (double x = basketRect.left + 10; x < basketRect.right; x += 15) {
      canvas.drawLine(Offset(x, basketRect.top), Offset(x, basketRect.bottom), wickerPaint);
    }
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

class _BalloonShape {
  final IconData icon; Offset position; Color currentColor; final double bobDelay;
  _BalloonShape({required this.icon, required this.position, required this.currentColor, required this.bobDelay});
}
