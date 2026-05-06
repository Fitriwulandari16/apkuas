import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
import 'dart:math' as math;

class AdvancedBalloonColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const AdvancedBalloonColoringScreen({super.key, this.levelId = 11});

  @override
  ConsumerState<AdvancedBalloonColoringScreen> createState() => _AdvancedBalloonColoringScreenState();
}

class _AdvancedBalloonColoringScreenState extends ConsumerState<AdvancedBalloonColoringScreen> with TickerProviderStateMixin {
  late AnimationController _flyController;
  late Animation<Offset> _flyAnimation;
  late AnimationController _cloudController;
  late AnimationController _bobController;

  final List<_BalloonShape> _shapes = [];
  Color? _selectedColor;
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
      double angle = random.nextDouble() * 2 * math.pi;
      double radius = random.nextDouble() * 0.25;
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
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih warna dulu! 🎨'), duration: Duration(milliseconds: 500)),
      );
      return;
    }
    setState(() {
      _shapes[index].currentColor = _selectedColor!;
    });
    HapticService.light();
    _checkWin();
  }

  void _checkWin() {
    // Level is complete only if all shapes match their rule color
    bool allFilled = _shapes.every((s) => s.currentColor != Colors.white.withOpacity(0.8));
    bool allCorrect = _shapes.every((s) => s.currentColor == _rule[s.icon]);
    
    if (allFilled && allCorrect) {
      _onWin();
    } else if (allFilled && !allCorrect) {
      // Feedback if everything is colored but some are wrong
      HapticService.failure();
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
            _buildInstructionPalette(),
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
                                Positioned.fill(child: CustomPaint(painter: _DetailedBalloonPainter())),
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
            _buildColorPicker(),
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
              'Petualangan Balon 2',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2E4482), letterSpacing: 1),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInstructionPalette() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SmallRule(icon: Icons.square, color: Colors.blue),
          _SmallRule(icon: Icons.circle, color: Colors.green),
          _SmallRule(icon: Icons.change_history, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PickerButton(
            color: Colors.red, 
            isSelected: _selectedColor == Colors.red,
            onTap: () => setState(() => _selectedColor = Colors.red),
          ),
          _PickerButton(
            color: Colors.green, 
            isSelected: _selectedColor == Colors.green,
            onTap: () => setState(() => _selectedColor = Colors.green),
          ),
          _PickerButton(
            color: Colors.blue, 
            isSelected: _selectedColor == Colors.blue,
            onTap: () => setState(() => _selectedColor = Colors.blue),
          ),
          // Eraser / Reset Button
          _PickerButton(
            color: Colors.white,
            icon: Icons.auto_fix_normal_rounded,
            isSelected: _selectedColor == Colors.white.withOpacity(0.8),
            onTap: () => setState(() => _selectedColor = Colors.white.withOpacity(0.8)),
          ),
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
            _Cloud(top: 450, left: ((1 - _cloudController.value) * 500) - 100, size: 120, opacity: 0.5),
          ],
        );
      },
    );
  }
}

class _PickerButton extends StatelessWidget {
  final Color color; final bool isSelected; final VoidCallback onTap; final IconData? icon;
  const _PickerButton({required this.color, required this.isSelected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 65 : 55, height: isSelected ? 65 : 55,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade300, width: isSelected ? 4 : 2),
          boxShadow: [if (isSelected) BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)],
        ),
        child: icon != null ? Icon(icon, color: Colors.blueGrey, size: 28) : null,
      ),
    );
  }
}

class _SmallRule extends StatelessWidget {
  final IconData icon; final Color color;
  const _SmallRule({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ],
    );
  }
}

class _ShapeIcon extends StatelessWidget {
  final _BalloonShape shape;
  const _ShapeIcon({required this.shape});
  @override
  Widget build(BuildContext context) {
    bool isEmpty = shape.currentColor == Colors.white.withOpacity(0.8);
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: shape.currentColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: shape.currentColor.withOpacity(0.4), blurRadius: 8)],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: Icon(shape.icon, color: isEmpty ? Colors.blueGrey.shade100 : Colors.white, size: 28),
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  final double top, left, size, opacity;
  const _Cloud({required this.top, required this.left, required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) {
    return Positioned(top: top, left: left, child: Icon(Icons.cloud, size: size, color: Colors.white.withOpacity(opacity)));
  }
}

class _DetailedBalloonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final balloonWidth = size.width * 0.75;
    final balloonHeight = size.height * 0.65;
    final paint = Paint()..color = Colors.orange.shade400..style = PaintingStyle.fill;
    final path = Path();
    path.addOval(Rect.fromLTWH(centerX - balloonWidth/2, 0, balloonWidth, balloonHeight));
    canvas.drawPath(path, paint);
    
    final stripePaint = Paint()..color = Colors.white.withOpacity(0.2)..style = PaintingStyle.fill;
    canvas.drawPath(Path()..addOval(Rect.fromLTWH(centerX - balloonWidth*0.1, 0, balloonWidth*0.2, balloonHeight)), stripePaint);

    final ropePaint = Paint()..color = Colors.brown.shade300..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(centerX - balloonWidth * 0.25, balloonHeight * 0.75), Offset(centerX - 40, size.height * 0.85), ropePaint);
    canvas.drawLine(Offset(centerX + balloonWidth * 0.25, balloonHeight * 0.75), Offset(centerX + 40, size.height * 0.85), ropePaint);
    
    final basketPaint = Paint()..color = Colors.brown.shade600..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(centerX - 45, size.height * 0.85, 90, 50), const Radius.circular(10)), basketPaint);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}

class _BalloonShape {
  final IconData icon; Offset position; Color currentColor; final double bobDelay;
  _BalloonShape({required this.icon, required this.position, required this.currentColor, required this.bobDelay});
}
