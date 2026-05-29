import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

enum GeomShape {
  oval,
  horizontalOval,
  triangle,
  circle,
  star
}

class RocketShape {
  final int id;
  final GeomShape type;
  final Offset position; // Center position (x, y) in range [0..1]
  bool isColored;

  RocketShape({
    required this.id,
    required this.type,
    required this.position,
    this.isColored = false,
  });
}

class ComplexObjectColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ComplexObjectColoringScreen({super.key, this.levelId = 32});

  @override
  ConsumerState<ComplexObjectColoringScreen> createState() => _ComplexObjectColoringScreenState();
}

class _ComplexObjectColoringScreenState extends ConsumerState<ComplexObjectColoringScreen> {
  // Theme Color Palette
  static const Color colRed = Color(0xFFE53935);
  static const Color colGreen = Color(0xFF4CAF50);
  static const Color colYellow = Color(0xFFFFD54F);
  static const Color colBlue = Color(0xFF1E88E5);

  // Available bucket colors
  final List<Color> _paletteColors = [colRed, colGreen, colYellow, colBlue];
  Color? _selectedColor;

  // Track shake offsets for each shape
  final Map<int, double> _shakeOffsets = {};

  // List of all 21 shapes placed inside the rocket
  late final List<RocketShape> _shapes;

  @override
  void initState() {
    super.initState();
    _initShapes();
  }

  void _initShapes() {
    _shapes = [
      // --- Nose Cone / Dome shapes ---
      RocketShape(id: 0, type: GeomShape.oval, position: const Offset(0.42, 0.28)),
      RocketShape(id: 1, type: GeomShape.circle, position: const Offset(0.50, 0.20)),
      RocketShape(id: 2, type: GeomShape.oval, position: const Offset(0.58, 0.28)),

      // --- Left Wing shapes ---
      RocketShape(id: 3, type: GeomShape.circle, position: const Offset(0.24, 0.44)),
      RocketShape(id: 4, type: GeomShape.triangle, position: const Offset(0.18, 0.58)),
      RocketShape(id: 5, type: GeomShape.circle, position: const Offset(0.24, 0.72)),

      // --- Right Wing shapes ---
      RocketShape(id: 6, type: GeomShape.circle, position: const Offset(0.76, 0.44)),
      RocketShape(id: 7, type: GeomShape.triangle, position: const Offset(0.82, 0.58)),
      RocketShape(id: 8, type: GeomShape.circle, position: const Offset(0.76, 0.72)),

      // --- Main Body Row 1 ---
      RocketShape(id: 9, type: GeomShape.circle, position: const Offset(0.40, 0.42)),
      RocketShape(id: 10, type: GeomShape.star, position: const Offset(0.50, 0.45)),
      RocketShape(id: 11, type: GeomShape.circle, position: const Offset(0.60, 0.42)),

      // --- Main Body Row 2 ---
      RocketShape(id: 12, type: GeomShape.oval, position: const Offset(0.40, 0.54)),
      RocketShape(id: 13, type: GeomShape.horizontalOval, position: const Offset(0.50, 0.56)),
      RocketShape(id: 14, type: GeomShape.oval, position: const Offset(0.60, 0.54)),

      // --- Main Body Row 3 ---
      RocketShape(id: 15, type: GeomShape.triangle, position: const Offset(0.40, 0.67)),
      RocketShape(id: 16, type: GeomShape.star, position: const Offset(0.50, 0.67)),
      RocketShape(id: 17, type: GeomShape.triangle, position: const Offset(0.60, 0.67)),

      // --- Main Body Row 4 ---
      RocketShape(id: 18, type: GeomShape.star, position: const Offset(0.38, 0.78)),
      RocketShape(id: 19, type: GeomShape.triangle, position: const Offset(0.50, 0.80)),
      RocketShape(id: 20, type: GeomShape.star, position: const Offset(0.62, 0.78)),
    ];

    for (var shape in _shapes) {
      _shakeOffsets[shape.id] = 0.0;
    }
  }

  Color _getRequiredColor(GeomShape type) {
    switch (type) {
      case GeomShape.oval:
      case GeomShape.horizontalOval:
        return colRed;
      case GeomShape.triangle:
        return colGreen;
      case GeomShape.circle:
        return colYellow;
      case GeomShape.star:
        return colBlue;
    }
  }

  void _handleShapeTap(RocketShape shape) {
    if (shape.isColored) return; // Already correctly filled

    if (_selectedColor == null) {
      // Prompt selection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih warna dari palet di bawah terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      HapticService.light();
      return;
    }

    final requiredColor = _getRequiredColor(shape.type);

    if (_selectedColor == requiredColor) {
      // Success match!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        shape.isColored = true;
      });

      // Check level completion
      if (_shapes.every((s) => s.isColored)) {
        _onLevelComplete();
      }
    } else {
      // Wrong color chosen! Shake the item
      _shakeShape(shape.id);
    }
  }

  void _shakeShape(int id) async {
    SoundService.playError();
    HapticService.failure();

    final offsets = [8.0, -8.0, 6.0, -6.0, 4.0, -4.0, 0.0];
    for (var offset in offsets) {
      if (!mounted) return;
      setState(() {
        _shakeOffsets[id] = offset;
      });
      await Future.delayed(const Duration(milliseconds: 35));
    }
  }

  void _onLevelComplete() async {
    // 1. Update local progress notifier
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Save progress to Firestore with try-catch block for resilience
    try {
      await UserService.updateProgress(32);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 32: $e');
    }

    if (!mounted) return;
    // 3. Trigger celebration dialog
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 33,
      title: 'Hebat Luar Biasa!',
      message: 'Kamu berhasil mewarnai semua bentuk roket dengan benar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLegend(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    final W = size.width;
                    final H = size.height;

                    // Responsive shape scaling
                    final double baseShapeSize = min(W * 0.08, 42.0);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Rocket illustration background outline
                        Positioned.fill(
                          child: CustomPaint(
                            painter: RocketIllustrationPainter(),
                          ),
                        ),

                        // Interactive shapes rendered exactly in rocket segments
                        ..._shapes.map((shape) {
                          final double shakeX = _shakeOffsets[shape.id] ?? 0.0;
                          final shapeCenter = Offset(
                            shape.position.dx * W + shakeX,
                            shape.position.dy * H,
                          );

                          // Shape-specific sizes for perfect aspect ratio
                          double width = baseShapeSize;
                          double height = baseShapeSize;
                          if (shape.type == GeomShape.oval) {
                            width = baseShapeSize * 0.8;
                            height = baseShapeSize * 1.1;
                          } else if (shape.type == GeomShape.horizontalOval) {
                            width = baseShapeSize * 1.25;
                            height = baseShapeSize * 0.8;
                          }

                          final shapeColor = shape.isColored
                              ? _getRequiredColor(shape.type)
                              : Colors.white;

                          return Positioned(
                            left: shapeCenter.dx - width / 2,
                            top: shapeCenter.dy - height / 2,
                            child: GestureDetector(
                              onTap: () => _handleShapeTap(shape),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: width,
                                height: height,
                                child: CustomPaint(
                                  size: Size(width, height),
                                  painter: ShapePainter(
                                    shape: shape.type,
                                    fillColor: shapeColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
            _buildPalette(),
            const SizedBox(height: 12),
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
              'Level 32',
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

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'Legenda Aturan',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: CilikTheme.tealTua,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(GeomShape.oval, colRed, 'Oval', 'Merah'),
              _buildLegendItem(GeomShape.triangle, colGreen, 'Segitiga', 'Hijau'),
              _buildLegendItem(GeomShape.circle, colYellow, 'Lingkaran', 'Kuning'),
              _buildLegendItem(GeomShape.star, colBlue, 'Bintang', 'Biru'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(GeomShape shape, Color color, String name, String colorName) {
    double iconW = 26;
    double iconH = 26;
    if (shape == GeomShape.oval) {
      iconW = 20;
      iconH = 28;
    }
    return Column(
      children: [
        CustomPaint(
          size: Size(iconW, iconH),
          painter: ShapePainter(shape: shape, fillColor: color),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          colorName,
          style: GoogleFonts.fredoka(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPalette() {
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
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _paletteColors.map((color) {
          final isSelected = _selectedColor == color;
          String colorText = '';
          if (color == colRed) colorText = 'Merah';
          if (color == colGreen) colorText = 'Hijau';
          if (color == colYellow) colorText = 'Kuning';
          if (color == colBlue) colorText = 'Biru';

          return GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() {
                _selectedColor = color;
              });
            },
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
                        width: isSelected ? 3.5 : 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.format_paint_rounded,
                        color: color == colYellow ? Colors.black87 : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    colorText,
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class RocketIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    final outlinePaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFF5F7FA)
      ..style = PaintingStyle.fill;

    // 1. Draw Tail / Exhaust (at the very bottom, y from 0.82 to 0.94)
    final tailPath = Path()
      ..moveTo(W * 0.35, H * 0.84)
      ..quadraticBezierTo(W * 0.35, H * 0.91, W * 0.42, H * 0.91)
      ..quadraticBezierTo(W * 0.50, H * 0.95, W * 0.58, H * 0.91)
      ..quadraticBezierTo(W * 0.65, H * 0.91, W * 0.65, H * 0.84)
      ..close();
    canvas.drawPath(tailPath, fillPaint);
    canvas.drawPath(tailPath, outlinePaint);

    // 2. Draw Left Wing (y from 0.38 to 0.78, x from 0.12 to 0.32)
    final leftWingPath = Path()
      ..moveTo(W * 0.32, H * 0.38)
      ..cubicTo(
        W * 0.08, H * 0.42,
        W * 0.08, H * 0.74,
        W * 0.32, H * 0.78,
      )
      ..close();
    canvas.drawPath(leftWingPath, fillPaint);
    canvas.drawPath(leftWingPath, outlinePaint);

    // 3. Draw Right Wing (y from 0.38 to 0.78, x from 0.68 to 0.88)
    final rightWingPath = Path()
      ..moveTo(W * 0.68, H * 0.38)
      ..cubicTo(
        W * 0.92, H * 0.42,
        W * 0.92, H * 0.74,
        W * 0.68, H * 0.78,
      )
      ..close();
    canvas.drawPath(rightWingPath, fillPaint);
    canvas.drawPath(rightWingPath, outlinePaint);

    // 4. Draw Main Fuselage / Capsule (Fuselage body + Nose Cone)
    final fuselagePath = Path()
      ..moveTo(W * 0.32, H * 0.84)
      ..lineTo(W * 0.32, H * 0.35)
      ..cubicTo(
        W * 0.32, H * 0.12,
        W * 0.68, H * 0.12,
        W * 0.68, H * 0.35,
      )
      ..lineTo(W * 0.68, H * 0.84)
      ..quadraticBezierTo(W * 0.50, H * 0.87, W * 0.32, H * 0.84)
      ..close();
    canvas.drawPath(fuselagePath, fillPaint);
    canvas.drawPath(fuselagePath, outlinePaint);

    // 5. Draw horizontal dividing line between nose cone and body
    final dividingPath = Path()
      ..moveTo(W * 0.32, H * 0.35)
      ..quadraticBezierTo(W * 0.50, H * 0.37, W * 0.68, H * 0.35);
    canvas.drawPath(dividingPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShapePainter extends CustomPainter {
  final GeomShape shape;
  final Color fillColor;

  ShapePainter({required this.shape, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    switch (shape) {
      case GeomShape.oval:
      case GeomShape.horizontalOval:
      case GeomShape.circle:
        final rect = Rect.fromLTWH(1.5, 1.5, w - 3, h - 3);
        canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, strokePaint);
        break;
      case GeomShape.triangle:
        final path = Path()
          ..moveTo(w / 2, 1.5)
          ..lineTo(w - 1.5, h - 1.5)
          ..lineTo(1.5, h - 1.5)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
      case GeomShape.star:
        final path = _getStarPath(w, h);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }

  Path _getStarPath(double width, double height) {
    double cx = width / 2;
    double cy = height / 2;
    int points = 5;
    double outerRadius = width / 2 - 1.5;
    double innerRadius = outerRadius * 0.45;
    double rot = -pi / 2;
    double step = pi / points;

    Path path = Path();
    path.moveTo(cx + cos(rot) * outerRadius, cy + sin(rot) * outerRadius);
    for (int i = 0; i < points * 2; i++) {
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double x = cx + cos(rot) * r;
      double y = cy + sin(rot) * r;
      path.lineTo(x, y);
      rot += step;
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.fillColor != fillColor;
  }
}
