import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

enum ShapeType { square, circle, triangle }

class GeometricShapeModel {
  final int index;
  final ShapeType type;
  final double relativeX;
  final double relativeY;
  final double size;
  Color? currentColor;
  bool isSolved;

  GeometricShapeModel({
    required this.index,
    required this.type,
    required this.relativeX,
    required this.relativeY,
    this.size = 38.0,
    this.isSolved = false,
  });

  Color get targetColor {
    switch (type) {
      case ShapeType.square:
        return const Color(0xFF3B82F6); // Blue
      case ShapeType.circle:
        return const Color(0xFF22C55E); // Green
      case ShapeType.triangle:
        return const Color(0xFFEF4444); // Red
    }
  }
}

class BalloonShapeColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const BalloonShapeColoringScreen({super.key, this.levelId = 46});

  @override
  ConsumerState<BalloonShapeColoringScreen> createState() => _BalloonShapeColoringScreenState();
}

class _BalloonShapeColoringScreenState extends ConsumerState<BalloonShapeColoringScreen> with SingleTickerProviderStateMixin {
  // Available colors: Blue, Green, Red
  static const Color colBlue = Color(0xFF3B82F6);
  static const Color colGreen = Color(0xFF22C55E);
  static const Color colRed = Color(0xFFEF4444);

  Color _selectedColor = colBlue;
  late List<GeometricShapeModel> _shapes;
  int? _shakingShapeIndex;

  // Fly-up flight animation
  late AnimationController _flightController;
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _flightController.dispose();
    super.dispose();
  }

  void _initLevel() {
    // 18 shapes scattered inside the balloon's top canopy
    _shapes = [
      GeometricShapeModel(index: 0, type: ShapeType.square, relativeX: 0.35, relativeY: 0.20),
      GeometricShapeModel(index: 1, type: ShapeType.square, relativeX: 0.52, relativeY: 0.20),
      GeometricShapeModel(index: 2, type: ShapeType.circle, relativeX: 0.70, relativeY: 0.22),
      GeometricShapeModel(index: 3, type: ShapeType.triangle, relativeX: 0.28, relativeY: 0.33),
      GeometricShapeModel(index: 4, type: ShapeType.circle, relativeX: 0.42, relativeY: 0.32),
      GeometricShapeModel(index: 5, type: ShapeType.triangle, relativeX: 0.58, relativeY: 0.31),
      GeometricShapeModel(index: 6, type: ShapeType.triangle, relativeX: 0.78, relativeY: 0.32),
      GeometricShapeModel(index: 7, type: ShapeType.circle, relativeX: 0.26, relativeY: 0.47),
      GeometricShapeModel(index: 8, type: ShapeType.square, relativeX: 0.44, relativeY: 0.45),
      GeometricShapeModel(index: 9, type: ShapeType.triangle, relativeX: 0.60, relativeY: 0.43),
      GeometricShapeModel(index: 10, type: ShapeType.square, relativeX: 0.70, relativeY: 0.43),
      GeometricShapeModel(index: 11, type: ShapeType.circle, relativeX: 0.82, relativeY: 0.45),
      GeometricShapeModel(index: 12, type: ShapeType.square, relativeX: 0.34, relativeY: 0.58),
      GeometricShapeModel(index: 13, type: ShapeType.triangle, relativeX: 0.50, relativeY: 0.58),
      GeometricShapeModel(index: 14, type: ShapeType.circle, relativeX: 0.66, relativeY: 0.58),
      GeometricShapeModel(index: 15, type: ShapeType.triangle, relativeX: 0.78, relativeY: 0.58),
      GeometricShapeModel(index: 16, type: ShapeType.circle, relativeX: 0.48, relativeY: 0.70),
      GeometricShapeModel(index: 17, type: ShapeType.square, relativeX: 0.64, relativeY: 0.70),
    ];
  }

  void _handleShapeTap(int index) {
    if (_isSolved) return;
    final shape = _shapes[index];

    if (shape.isSolved) return;

    if (shape.targetColor == _selectedColor) {
      // Correct color selected!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        shape.currentColor = _selectedColor;
        shape.isSolved = true;
      });

      // Check level completion
      if (_shapes.every((s) => s.isSolved)) {
        _onLevelComplete();
      }
    } else {
      // Wrong color selected
      _shakeShape(index);
    }
  }

  void _shakeShape(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingShapeIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _shakingShapeIndex = null;
      });
    }
  }

  void _onLevelComplete() async {
    setState(() {
      _isSolved = true;
    });

    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(46);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 46: $e');
    }

    // 3. Play fly-up animation
    _flightController.forward();
    await Future.delayed(const Duration(milliseconds: 1900));

    if (!mounted) return;

    // 4. Show success victory dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'BalloonSuccess',
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scaleValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: scaleValue,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.amber, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 110,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HEBAT! SIAP TERBANG!',
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hebat! Balon udaranya sudah siap terbang!',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        // Return back to Adventure Map
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close level 46 screen
                      },
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE), // Blue sky color
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Fluffy clouds background
            Positioned(
              top: 40,
              left: 20,
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  'assets/images/cloud.png',
                  width: 100,
                  errorBuilder: (c, e, s) => const Icon(Icons.cloud, color: Colors.white, size: 64),
                ),
              ),
            ),
            Positioned(
              top: 140,
              right: 30,
              child: Opacity(
                opacity: 0.6,
                child: Image.asset(
                  'assets/images/cloud.png',
                  width: 120,
                  errorBuilder: (c, e, s) => const Icon(Icons.cloud, color: Colors.white, size: 80),
                ),
              ),
            ),

            // 2. Main interface components
            Column(
              children: [
                _buildHeader(),
                _buildInstruction(),
                _buildLegendHeader(),
                const SizedBox(height: 10),
                // Play Area (Scattered shapes inside Hot Air Balloon)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AnimatedBuilder(
                      animation: _flightController,
                      builder: (context, child) {
                        // Curved ease-in-back flight up offset
                        final double flyOffsetY = -_flightController.value * 700.0;

                        return Transform.translate(
                          offset: Offset(0, flyOffsetY),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Giant Balloon backdrop
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: HotAirBalloonPainter(),
                                ),
                              ),

                              // Scattered Shapes over the Balloon Canopy
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double w = constraints.maxWidth;
                                    final double h = constraints.maxHeight;

                                    return Stack(
                                      children: _shapes.map((shape) {
                                        final double absX = shape.relativeX * (w - shape.size);
                                        final double absY = (shape.relativeY * 0.70) * (h - shape.size) + (h * 0.05);

                                        final isShaking = _shakingShapeIndex == shape.index;
                                        final double shakeX = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

                                        return Positioned(
                                          left: absX + shakeX,
                                          top: absY,
                                          width: shape.size,
                                          height: shape.size,
                                          child: GestureDetector(
                                            onTap: () => _handleShapeTap(shape.index),
                                            child: Container(
                                              color: Colors.transparent, // expand hit-test
                                              child: CustomPaint(
                                                painter: GeometricShapePainter(
                                                  type: shape.type,
                                                  isSolved: shape.isSolved,
                                                  color: shape.currentColor ?? Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPalette(),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 46',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CilikTheme.tealTua,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.palette_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Pilih warna, lalu warnai bentuk yang sama seperti contoh!',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(ShapeType.square, colBlue, 'Persegi'),
          _buildLegendItem(ShapeType.circle, colGreen, 'Lingkaran'),
          _buildLegendItem(ShapeType.triangle, colRed, 'Segitiga'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ShapeType type, Color color, String label) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CustomPaint(
            painter: GeometricShapePainter(
              type: type,
              isSolved: true,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildPalette() {
    final List<Color> colors = [colBlue, colGreen, colRed];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.map((color) {
          final isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() {
                _selectedColor = color;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent,
                  width: isSelected ? 4.0 : 0.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 28,
                      ),
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class HotAirBalloonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Center coordinates for balloon canopy (egg shaped circle)
    final double centerX = w / 2;
    final double centerY = h * 0.40;
    final double canopyRadius = w * 0.44;

    // Draw balloon canopy back shadow / body
    final canopyPaint = Paint()
      ..color = const Color(0xFFFCD34D) // Rich pastel yellow
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY), canopyRadius, canopyPaint);

    // Draw orange stripes on the balloon canopy
    final stripePaint = Paint()
      ..color = const Color(0xFFF59E0B) // Rich pastel orange
      ..style = PaintingStyle.fill;

    final stripePathLeft = Path()
      ..moveTo(centerX, centerY - canopyRadius)
      ..cubicTo(
        centerX - canopyRadius * 0.6, centerY - canopyRadius,
        centerX - canopyRadius * 0.8, centerY + canopyRadius * 0.5,
        centerX - canopyRadius * 0.35, centerY + canopyRadius,
      )
      ..lineTo(centerX - canopyRadius * 0.55, centerY + canopyRadius)
      ..cubicTo(
        centerX - canopyRadius * 0.9, centerY + canopyRadius * 0.5,
        centerX - canopyRadius * 0.8, centerY - canopyRadius,
        centerX, centerY - canopyRadius,
      )
      ..close();

    final stripePathRight = Path()
      ..moveTo(centerX, centerY - canopyRadius)
      ..cubicTo(
        centerX + canopyRadius * 0.6, centerY - canopyRadius,
        centerX + canopyRadius * 0.8, centerY + canopyRadius * 0.5,
        centerX + canopyRadius * 0.35, centerY + canopyRadius,
      )
      ..lineTo(centerX + canopyRadius * 0.55, centerY + canopyRadius)
      ..cubicTo(
        centerX + canopyRadius * 0.9, centerY + canopyRadius * 0.5,
        centerX + canopyRadius * 0.8, centerY - canopyRadius,
        centerX, centerY - canopyRadius,
      )
      ..close();

    canvas.drawPath(stripePathLeft, stripePaint);
    canvas.drawPath(stripePathRight, stripePaint);

    // Border line outline around the canopy
    final borderPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(centerX, centerY), canopyRadius, borderPaint);

    // Draw basket cables/ropes
    final ropePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final double neckY = centerY + canopyRadius;
    final double basketTopY = h * 0.88;
    final double basketLeft = centerX - w * 0.08;
    final double basketRight = centerX + w * 0.08;

    canvas.drawLine(Offset(centerX - canopyRadius * 0.2, neckY), Offset(basketLeft, basketTopY), ropePaint);
    canvas.drawLine(Offset(centerX + canopyRadius * 0.2, neckY), Offset(basketRight, basketTopY), ropePaint);

    // Draw basket body
    final basketPaint = Paint()
      ..color = const Color(0xFF9A3412) // Woven basket brown
      ..style = PaintingStyle.fill;
    final basketBorderPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final RRect basketRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(basketLeft - 4, basketTopY, basketRight + 4, basketTopY + 36),
      const Radius.circular(8),
    );

    canvas.drawRRect(basketRect, basketPaint);
    canvas.drawRRect(basketRect, basketBorderPaint);
  }

  @override
  bool shouldRepaint(covariant HotAirBalloonPainter oldDelegate) {
    return false;
  }
}

class GeometricShapePainter extends CustomPainter {
  final ShapeType type;
  final bool isSolved;
  final Color color;

  GeometricShapePainter({
    required this.type,
    required this.isSolved,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final fillPaint = Paint()
      ..color = isSolved ? color : Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSolved ? color.withOpacity(0.9) : const Color(0xFF475569)
      ..strokeWidth = isSolved ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    switch (type) {
      case ShapeType.square:
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, w - 4, h - 4),
          const Radius.circular(8),
        );
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, borderPaint);
        break;

      case ShapeType.circle:
        canvas.drawCircle(Offset(w / 2, h / 2), (w - 4) / 2, fillPaint);
        canvas.drawCircle(Offset(w / 2, h / 2), (w - 4) / 2, borderPaint);
        break;

      case ShapeType.triangle:
        final path = Path()
          ..moveTo(w / 2, 2)
          ..lineTo(w - 2, h - 2)
          ..lineTo(2, h - 2)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant GeometricShapePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.isSolved != isSolved ||
        oldDelegate.color != color;
  }
}
