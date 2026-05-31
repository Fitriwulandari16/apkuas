import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ButterflyDotModel {
  final int index;
  final double relativeDx;
  final double relativeDy;
  final Color correctColor;
  Color? currentColor;

  ButterflyDotModel({
    required this.index,
    required this.relativeDx,
    required this.relativeDy,
    required this.correctColor,
    this.currentColor,
  });

  bool get isCorrect => currentColor == correctColor;
}

class SymmetryButterflyScreen extends ConsumerStatefulWidget {
  final int levelId;
  const SymmetryButterflyScreen({super.key, this.levelId = 37});

  @override
  ConsumerState<SymmetryButterflyScreen> createState() => _SymmetryButterflyScreenState();
}

class _SymmetryButterflyScreenState extends ConsumerState<SymmetryButterflyScreen> with SingleTickerProviderStateMixin {
  // 5 vibrant colors according to specification
  static const Color colRed = Color(0xFFEF4444);    // Merah
  static const Color colGreen = Color(0xFF22C55E);  // Hijau
  static const Color colBlue = Color(0xFF3B82F6);   // Biru
  static const Color colYellow = Color(0xFFFACC15); // Kuning
  static const Color colOrange = Color(0xFFF97316); // Oranye

  final Map<Color, String> _colorNames = {
    colRed: 'Merah',
    colGreen: 'Hijau',
    colBlue: 'Biru',
    colYellow: 'Kuning',
    colOrange: 'Oranye',
  };

  Color? _selectedColor;
  late List<ButterflyDotModel> _dots;
  int? _shakingDotIndex;

  // Animation controller for flapping wings upon completion
  late AnimationController _flapController;
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
    _flapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void dispose() {
    _flapController.dispose();
    super.dispose();
  }

  void _initLevel() {
    // 5 points on each wing, mirroring coordinates relative to center
    // relativeDx: horizontal distance from vertical symmetry axis (0.0 to 0.5)
    // relativeDy: vertical distance from center horizontal axis (-0.5 to 0.5)
    _dots = [
      ButterflyDotModel(
        index: 0,
        relativeDx: 0.35,
        relativeDy: -0.22,
        correctColor: colRed, // Atas Luar
      ),
      ButterflyDotModel(
        index: 1,
        relativeDx: 0.16,
        relativeDy: -0.15,
        correctColor: colGreen, // Atas Dalam
      ),
      ButterflyDotModel(
        index: 2,
        relativeDx: 0.28,
        relativeDy: 0.0,
        correctColor: colBlue, // Tengah
      ),
      ButterflyDotModel(
        index: 3,
        relativeDx: 0.32,
        relativeDy: 0.20,
        correctColor: colYellow, // Bawah Luar
      ),
      ButterflyDotModel(
        index: 4,
        relativeDx: 0.15,
        relativeDy: 0.12,
        correctColor: colOrange, // Bawah Dalam
      ),
    ];
  }

  void _handleDotTap(int index) {
    if (_isSolved) return;
    final dot = _dots[index];

    // Already correct
    if (dot.isCorrect) return;

    if (_selectedColor == null) {
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih warna di palet terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigoAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_selectedColor == dot.correctColor) {
      // Correct!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        dot.currentColor = _selectedColor;
      });

      // Check level completion
      if (_dots.every((d) => d.isCorrect)) {
        _onLevelComplete();
      }
    } else {
      // Wrong color selected
      _shakeDot(index);
    }
  }

  void _shakeDot(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingDotIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _shakingDotIndex = null;
      });
    }
  }

  void _onLevelComplete() async {
    // 1. Trigger flap animation
    setState(() {
      _isSolved = true;
    });
    _flapController.forward();

    // 2. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 3. Sync to cloud database
    try {
      await UserService.updateProgress(37);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 37: $e');
    }

    // 4. Wait for wing flap animation to complete before showing dialog
    await Future.delayed(const Duration(milliseconds: 2600));

    if (!mounted) return;

    // 5. Show premium victory dialog and return back to Map
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'SymmetrySuccess',
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
                      'WOW! KAMU HEBAT!',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kupu-kupu sekarang terlihat sangat indah dan simetris berkat bantuanmu!',
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
                        Navigator.pop(context); // close level 37 screen
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
    final List<Color> colors = [colRed, colGreen, colBlue, colYellow, colOrange];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 16),
            // Play Area (Butterfly symmetry board)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        final double h = constraints.maxHeight;
                        final double cx = w / 2;
                        final double cy = h / 2;

                        return AnimatedBuilder(
                          animation: _flapController,
                          builder: (context, child) {
                            return GestureDetector(
                              onTapDown: (details) {
                                final localPos = details.localPosition;
                                // We check tap distance to any right wing dots
                                for (int i = 0; i < _dots.length; i++) {
                                  final dot = _dots[i];
                                  final double rx = cx + dot.relativeDx * w;
                                  final double ry = cy + dot.relativeDy * h;

                                  final double distance = sqrt(pow(localPos.dx - rx, 2) + pow(localPos.dy - ry, 2));
                                  if (distance <= 24.0) {
                                    _handleDotTap(i);
                                    break;
                                  }
                                }
                              },
                              child: CustomPaint(
                                size: Size(w, h),
                                painter: ButterflyPainter(
                                  flapValue: _flapController.value,
                                  dots: _dots,
                                  isSolved: _isSolved,
                                  shakingDotIndex: _shakingDotIndex,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPalette(colors),
            const SizedBox(height: 20),
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
              'Level 37',
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          const Icon(Icons.compare_arrows_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Lengkapi titik sayap kanan agar sama (simetris) dengan sayap kiri!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
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

  Widget _buildPalette(List<Color> colors) {
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
          final String colorName = _colorNames[color]!;

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
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.format_paint_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    colorName,
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ButterflyPainter extends CustomPainter {
  final double flapValue;
  final List<ButterflyDotModel> dots;
  final bool isSolved;
  final int? shakingDotIndex;

  ButterflyPainter({
    required this.flapValue,
    required this.dots,
    required this.isSolved,
    this.shakingDotIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // Calculate flapping scale factor (flapping 4 times during the animation)
    final double scaleX = 1.0 - 0.5 * sin(flapValue * pi * 4).abs();

    final bodyPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    // Soft baby-pink/rose for the reference left wing and cool light blue/grey for the interactive right wing
    final leftWingPaint = Paint()
      ..color = const Color(0xFFFFECEF)
      ..style = PaintingStyle.fill;

    final rightWingPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // 1. Draw Left Wing (mirrored shape)
    final leftWingPath = Path();
    leftWingPath.moveTo(cx, cy - 20);
    leftWingPath.cubicTo(
      cx - 160 * scaleX, cy - 160,
      cx - 200 * scaleX, cy - 60,
      cx - 80 * scaleX, cy,
    );
    leftWingPath.cubicTo(
      cx - 150 * scaleX, cy + 120,
      cx - 80 * scaleX, cy + 160,
      cx, cy + 40,
    );
    leftWingPath.close();
    canvas.drawPath(leftWingPath, leftWingPaint);
    canvas.drawPath(leftWingPath, borderPaint);

    // 2. Draw Right Wing (mirrored shape)
    final rightWingPath = Path();
    rightWingPath.moveTo(cx, cy - 20);
    rightWingPath.cubicTo(
      cx + 160 * scaleX, cy - 160,
      cx + 200 * scaleX, cy - 60,
      cx + 80 * scaleX, cy,
    );
    rightWingPath.cubicTo(
      cx + 150 * scaleX, cy + 120,
      cx + 80 * scaleX, cy + 160,
      cx, cy + 40,
    );
    rightWingPath.close();
    canvas.drawPath(rightWingPath, rightWingPaint);
    canvas.drawPath(rightWingPath, borderPaint);

    // 3. Draw Axis of Symmetry
    final axisPaint = Paint()
      ..color = Colors.indigo.withOpacity(0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, Offset(cx, 20), Offset(cx, h - 20), axisPaint);

    // 4. Draw Butterfly Body
    // Abdomen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 30), width: 14, height: 100),
        const Radius.circular(7),
      ),
      bodyPaint,
    );
    // Thorax
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 30), width: 18, height: 35),
      bodyPaint,
    );
    // Head
    canvas.drawCircle(Offset(cx, cy - 54), 10, bodyPaint);
    // Antennae
    final antennaPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final antennaLeft = Path()
      ..moveTo(cx - 3, cy - 62)
      ..quadraticBezierTo(cx - 15, cy - 80, cx - 25, cy - 78);
    final antennaRight = Path()
      ..moveTo(cx + 3, cy - 62)
      ..quadraticBezierTo(cx + 15, cy - 80, cx + 25, cy - 78);
    canvas.drawPath(antennaLeft, antennaPaint);
    canvas.drawPath(antennaRight, antennaPaint);
    canvas.drawCircle(Offset(cx - 25, cy - 78), 3, bodyPaint);
    canvas.drawCircle(Offset(cx + 25, cy - 78), 3, bodyPaint);

    // 5. Draw Left Wing Dots (fixed reference colors)
    for (final dot in dots) {
      final double lx = cx - dot.relativeDx * w * scaleX;
      final double ly = cy + dot.relativeDy * h;
      
      final dotPaint = Paint()
        ..color = dot.correctColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(lx, ly), 16, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(lx, ly), 16, borderPaint..strokeWidth = 2.0);
      canvas.drawCircle(Offset(lx, ly), 12, dotPaint);
    }

    // 6. Draw Right Wing Dots (current state / target outline)
    for (final dot in dots) {
      final isShaking = shakingDotIndex == dot.index;
      final double shakeOffset = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

      final double rx = cx + dot.relativeDx * w * scaleX + shakeOffset;
      final double ry = cy + dot.relativeDy * h;

      canvas.drawCircle(Offset(rx, ry), 16, Paint()..color = Colors.white);
      
      if (dot.currentColor != null) {
        final dotPaint = Paint()
          ..color = dot.currentColor!
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(rx, ry), 16, borderPaint..strokeWidth = 2.0);
        canvas.drawCircle(Offset(rx, ry), 12, dotPaint);
      } else {
        final emptyBorderPaint = Paint()
          ..color = isShaking ? Colors.red : Colors.grey.shade400
          ..strokeWidth = isShaking ? 2.5 : 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(rx, ry), 16, emptyBorderPaint);
        canvas.drawCircle(Offset(rx, ry), 4, Paint()..color = Colors.grey.shade300);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    final double distance = (p2 - p1).distance;
    final int dashCount = (distance / (dashWidth + dashSpace)).floor();
    final Offset direction = (p2 - p1) / distance;

    for (int i = 0; i < dashCount; i++) {
      final double start = i * (dashWidth + dashSpace);
      final double end = start + dashWidth;
      canvas.drawLine(
        p1 + direction * start,
        p1 + direction * end,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ButterflyPainter oldDelegate) {
    return oldDelegate.flapValue != flapValue ||
        oldDelegate.dots != dots ||
        oldDelegate.isSolved != isSolved ||
        oldDelegate.shakingDotIndex != shakingDotIndex;
  }
}
