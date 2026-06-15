import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';

enum ShapeType {
  triangle,
  lShape,
  star8,
  circle,
  arrow,
  quarterCircle,
  heart,
  rect,
  star5,
  trapezoid,
  parallelogram,
  cross,
  star4,
  lightning,
}

class ShapeOption {
  final ShapeType type;
  final double rotation; // in radians
  final bool isCorrect;

  ShapeOption({
    required this.type,
    this.rotation = 0.0,
    required this.isCorrect,
  });
}

class RowChallenge {
  final int index;
  final Color color;
  final ShapeType targetType;
  final double targetRotation; // in radians
  final List<ShapeOption> options;
  bool isSolved;
  int? selectedOptionIndex;

  RowChallenge({
    required this.index,
    required this.color,
    required this.targetType,
    this.targetRotation = 0.0,
    required this.options,
    this.isSolved = false,
    this.selectedOptionIndex,
  });
}

class ComplementaryShapeMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ComplementaryShapeMatchingScreen({super.key, this.levelId = 36});

  @override
  ConsumerState<ComplementaryShapeMatchingScreen> createState() => _ComplementaryShapeMatchingScreenState();
}

class _ComplementaryShapeMatchingScreenState extends ConsumerState<ComplementaryShapeMatchingScreen> {
  late List<RowChallenge> _challenges;
  int? _shakingRowIndex;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    _challenges = [
      // Row 1: Orange - Triangle
      RowChallenge(
        index: 0,
        color: const Color(0xFFF97316),
        targetType: ShapeType.triangle,
        options: [
          ShapeOption(type: ShapeType.triangle, isCorrect: true),
          ShapeOption(type: ShapeType.rect, isCorrect: false),
          ShapeOption(type: ShapeType.circle, isCorrect: false),
          ShapeOption(type: ShapeType.rect, isCorrect: false), // Tall Rect represented here by rect with rotation or similar
        ],
      ),
      // Row 2: Green - L-Shape
      RowChallenge(
        index: 1,
        color: const Color(0xFF22C55E),
        targetType: ShapeType.lShape,
        targetRotation: pi, // cutout facing ceiling hook
        options: [
          ShapeOption(type: ShapeType.lShape, rotation: 0.0, isCorrect: false),
          ShapeOption(type: ShapeType.lShape, rotation: pi / 2, isCorrect: false),
          ShapeOption(type: ShapeType.lShape, rotation: 3 * pi / 2, isCorrect: false),
          ShapeOption(type: ShapeType.lShape, rotation: pi, isCorrect: true), // Correct matches cutout rotation
        ],
      ),
      // Row 3: Yellow - 8-pointed star
      RowChallenge(
        index: 2,
        color: const Color(0xFFFACC15),
        targetType: ShapeType.star8,
        options: [
          ShapeOption(type: ShapeType.triangle, isCorrect: false),
          ShapeOption(type: ShapeType.rect, isCorrect: false), // Capsule drawn as rounded rect
          ShapeOption(type: ShapeType.star5, isCorrect: false),
          ShapeOption(type: ShapeType.star8, isCorrect: true),
        ],
      ),
      // Row 4: Blue - Circle inside Donut Ring
      RowChallenge(
        index: 3,
        color: const Color(0xFF3B82F6),
        targetType: ShapeType.circle,
        options: [
          ShapeOption(type: ShapeType.triangle, isCorrect: false), // Right triangle path
          ShapeOption(type: ShapeType.trapezoid, isCorrect: false),
          ShapeOption(type: ShapeType.parallelogram, isCorrect: false),
          ShapeOption(type: ShapeType.circle, isCorrect: true),
        ],
      ),
      // Row 5: Pink - Arrow
      RowChallenge(
        index: 4,
        color: const Color(0xFFEC4899),
        targetType: ShapeType.arrow,
        options: [
          ShapeOption(type: ShapeType.arrow, rotation: 0.0, isCorrect: true), // facing right
          ShapeOption(type: ShapeType.arrow, rotation: 3 * pi / 2, isCorrect: false), // facing up
          ShapeOption(type: ShapeType.rect, isCorrect: false), // House shape drawn as block rect
          ShapeOption(type: ShapeType.arrow, rotation: pi / 2, isCorrect: false), // facing down
        ],
      ),
      // Row 6: Purple - Quarter Circle
      RowChallenge(
        index: 5,
        color: const Color(0xFFA855F7),
        targetType: ShapeType.quarterCircle,
        targetRotation: 0.0, // bottom-right quadrant cutout
        options: [
          ShapeOption(type: ShapeType.quarterCircle, rotation: pi, isCorrect: false),
          ShapeOption(type: ShapeType.circle, isCorrect: false), // 3/4 circle
          ShapeOption(type: ShapeType.rect, isCorrect: false), // semi circle
          ShapeOption(type: ShapeType.quarterCircle, rotation: 0.0, isCorrect: true), // correct matching bottom-right orientation
        ],
      ),
      // Row 7: Brown - Heart
      RowChallenge(
        index: 6,
        color: const Color(0xFF8B5A2B), // Brown color
        targetType: ShapeType.heart,
        options: [
          ShapeOption(type: ShapeType.cross, isCorrect: false),
          ShapeOption(type: ShapeType.star4, isCorrect: false),
          ShapeOption(type: ShapeType.heart, isCorrect: true),
          ShapeOption(type: ShapeType.lightning, isCorrect: false),
        ],
      ),
    ];
  }

  void _handleOptionTap(int rowIndex, int optIndex) {
    final challenge = _challenges[rowIndex];
    final option = challenge.options[optIndex];

    setState(() {
      challenge.selectedOptionIndex = optIndex;
    });

    if (option.isCorrect) {
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        challenge.isSolved = true;
      });

      // Check level completion
      if (_challenges.every((c) => c.isSolved)) {
        _onLevelComplete();
      }
    } else {
      _shakeRow(rowIndex);
    }
  }

  void _shakeRow(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingRowIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _shakingRowIndex = null;
        _challenges[index].selectedOptionIndex = null; // deselect on fail
      });
    }
  }

  void _onLevelComplete() async {
    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(widget.levelId);
    } catch (e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    }

    if (!mounted) return;

    // 3. Show Celebration and transition to next level
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: widget.levelId + 1,
      title: 'HEBAT! KAMU PINTAR!',
      message: 'Kamu berhasil mencocokkan semua bentuk pelengkap dengan sangat sempurna!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                physics: const BouncingScrollPhysics(),
                itemCount: _challenges.length,
                itemBuilder: (context, index) {
                  final challenge = _challenges[index];
                  return _buildRowChallenge(challenge);
                },
              ),
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
              'Level 36',
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
          const Icon(Icons.extension_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Pilih potongan bentuk yang tepat untuk mengisi lubang lingkaran di sebelah kiri!',
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

  Widget _buildRowChallenge(RowChallenge challenge) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: challenge.isSolved ? challenge.color.withOpacity(0.2) : const Color(0xFFF1F5F9),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Sisi Kiri (Soal)
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: QuestionShapePainter(
                type: challenge.targetType,
                rotation: challenge.targetRotation,
                color: challenge.color,
                isSolved: challenge.isSolved,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: challenge.isSolved ? challenge.color.withOpacity(0.4) : Colors.grey.shade300,
            size: 16,
          ),
          const SizedBox(width: 8),
          // Sisi Kanan (Pilihan Jawaban)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(challenge.options.length, (optIdx) {
                final option = challenge.options[optIdx];
                final isSelected = challenge.selectedOptionIndex == optIdx;
                final isShaking = _shakingRowIndex == challenge.index && challenge.selectedOptionIndex == optIdx;
                final double shakeX = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

                return Transform.translate(
                  offset: Offset(shakeX, 0),
                  child: GestureDetector(
                    onTap: challenge.isSolved ? null : () => _handleOptionTap(challenge.index, optIdx),
                    child: Container(
                      width: 52,
                      height: 52,
                      color: Colors.transparent, // expand hit-test area
                      child: CustomPaint(
                        painter: OptionShapePainter(
                          type: option.type,
                          rotation: option.rotation,
                          color: challenge.color,
                          isSelected: isSelected,
                          isSolved: challenge.isSolved,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionShapePainter extends CustomPainter {
  final ShapeType type;
  final double rotation;
  final Color color;
  final bool isSolved;

  QuestionShapePainter({
    required this.type,
    required this.rotation,
    required this.color,
    required this.isSolved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = min(w, h) * 0.44;

    // 1. Draw Circle Fill Background
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    // 2. Draw Sphere-Style Glossy White Highlight on top-left to make it premium 3D
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(cx - radius * 0.6, cy - radius * 0.8, radius * 0.8, radius * 0.4),
      highlightPaint,
    );

    // 3. Draw Circle Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    // 4. Draw Cutout (White if unsolved, or matching color with scaling/glow if solved)
    final cutoutPaint = Paint()
      ..color = isSolved ? Colors.white.withOpacity(0.4) : Colors.white
      ..style = PaintingStyle.fill;

    final path = _getShapePath(type, w, h);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);
    canvas.translate(-cx, -cy);
    canvas.drawPath(path, cutoutPaint);

    // Draw an extra inner border for the cutout to make it look carved-in
    final cutoutBorderPaint = Paint()
      ..color = isSolved ? color.withOpacity(0.8) : Colors.black12
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, cutoutBorderPaint);

    canvas.restore();
  }

  Path _getShapePath(ShapeType type, double w, double h) {
    // Reuses the exact same path math so they align perfectly!
    return OptionShapePainter(
      type: type,
      rotation: rotation,
      color: color,
      isSelected: false,
      isSolved: false,
    )._getShapePath(type, w, h);
  }

  @override
  bool shouldRepaint(covariant QuestionShapePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.rotation != rotation ||
        oldDelegate.color != color ||
        oldDelegate.isSolved != isSolved;
  }
}

class OptionShapePainter extends CustomPainter {
  final ShapeType type;
  final double rotation;
  final Color color;
  final bool isSelected;
  final bool isSolved;

  OptionShapePainter({
    required this.type,
    required this.rotation,
    required this.color,
    required this.isSelected,
    required this.isSolved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // 1. If selected, draw the thin dashed circle
    if (isSelected) {
      final borderPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      _drawDashedCircle(canvas, Offset(cx, cy), min(w, h) * 0.48, borderPaint);
    }

    // 2. Generate the path
    final path = _getShapePath(type, w, h);

    // 3. Draw the solid shape inside the path
    final shapePaint = Paint()
      ..color = isSolved ? color.withOpacity(0.4) : color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);
    canvas.translate(-cx, -cy);
    canvas.drawPath(path, shapePaint);
    canvas.restore();
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    final double circumference = 2 * pi * radius;
    final double dashWidth = 5.0;
    final double dashSpace = 4.0;
    final double totalDash = dashWidth + dashSpace;
    final int dashCount = (circumference / totalDash).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * totalDash) / circumference * 2 * pi;
      final double sweepAngle = dashWidth / circumference * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  Path _getShapePath(ShapeType type, double w, double h) {
    switch (type) {
      case ShapeType.triangle:
        return Path()
          ..moveTo(w / 2, h * 0.15)
          ..lineTo(w * 0.85, h * 0.85)
          ..lineTo(w * 0.15, h * 0.85)
          ..close();
      case ShapeType.lShape:
        final double cx = w / 2;
        final double cy = h / 2;
        final double u = min(w, h) / 6;
        return Path()
          ..moveTo(cx - u, cy - 2 * u)
          ..lineTo(cx + u, cy - 2 * u)
          ..lineTo(cx + u, cy)
          ..lineTo(cx + 2 * u, cy)
          ..lineTo(cx + 2 * u, cy + 2 * u)
          ..lineTo(cx - u, cy + 2 * u)
          ..close();
      case ShapeType.star8:
        final double cx = w / 2;
        final double cy = h / 2;
        final double rOuter = min(w, h) * 0.4;
        final double rInner = min(w, h) * 0.25;
        final path = Path();
        for (int i = 0; i < 16; i++) {
          final double angle = i * pi / 8;
          final double r = i.isEven ? rOuter : rInner;
          final double x = cx + r * cos(angle);
          final double y = cy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        return path;
      case ShapeType.circle:
        final double cx = w / 2;
        final double cy = h / 2;
        final double r = min(w, h) * 0.35;
        return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      case ShapeType.arrow:
        final double cx = w / 2;
        final double cy = h / 2;
        final double u = min(w, h) / 6;
        return Path()
          ..moveTo(cx - 2 * u, cy - u)
          ..lineTo(cx + u, cy - u)
          ..lineTo(cx + u, cy - 2 * u)
          ..lineTo(cx + 3 * u, cy)
          ..lineTo(cx + u, cy + 2 * u)
          ..lineTo(cx + u, cy + u)
          ..lineTo(cx - 2 * u, cy + u)
          ..close();
      case ShapeType.quarterCircle:
        final double cx = w / 2;
        final double cy = h / 2;
        final double r = min(w, h) * 0.4;
        final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
        final path = Path()
          ..moveTo(cx, cy)
          ..lineTo(cx + r, cy)
          ..arcTo(rect, 0, pi / 2, false)
          ..lineTo(cx, cy)
          ..close();
        return path;
      case ShapeType.heart:
        final double cx = w / 2;
        final double cy = h / 2;
        final double size = min(w, h) * 0.75;
        final double x = cx - size / 2;
        final double y = cy - size / 2;
        final path = Path();
        path.moveTo(x + size / 2, y + size * 0.25);
        path.cubicTo(x + size * 0.15, y, x, y + size * 0.35, x, y + size * 0.55);
        path.cubicTo(x, y + size * 0.77, x + size * 0.3, y + size * 0.9, x + size / 2, y + size);
        path.cubicTo(x + size * 0.7, y + size * 0.9, x + size, y + size * 0.77, x + size, y + size * 0.55);
        path.cubicTo(x + size, y + size * 0.35, x + size * 0.85, y, x + size / 2, y + size * 0.25);
        path.close();
        return path;
      case ShapeType.rect:
        final double cx = w / 2;
        final double cy = h / 2;
        final double width = w * 0.7;
        final double height = h * 0.45;
        return Path()..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: width, height: height),
          const Radius.circular(8),
        ));
      case ShapeType.star5:
        final double cx = w / 2;
        final double cy = h / 2;
        final double rOuter = min(w, h) * 0.4;
        final double rInner = min(w, h) * 0.18;
        final path = Path();
        for (int i = 0; i < 10; i++) {
          final double angle = i * pi / 5 - pi / 2;
          final double r = i.isEven ? rOuter : rInner;
          final double x = cx + r * cos(angle);
          final double y = cy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        return path;
      case ShapeType.trapezoid:
        return Path()
          ..moveTo(w * 0.15, h * 0.8)
          ..lineTo(w * 0.85, h * 0.8)
          ..lineTo(w * 0.7, h * 0.3)
          ..lineTo(w * 0.3, h * 0.3)
          ..close();
      case ShapeType.parallelogram:
        return Path()
          ..moveTo(w * 0.15, h * 0.8)
          ..lineTo(w * 0.7, h * 0.8)
          ..lineTo(w * 0.85, h * 0.3)
          ..lineTo(w * 0.3, h * 0.3)
          ..close();
      case ShapeType.cross:
        final double cx = w / 2;
        final double cy = h / 2;
        final double u = min(w, h) / 6;
        return Path()
          ..moveTo(cx - u, cy - 3 * u)
          ..lineTo(cx + u, cy - 3 * u)
          ..lineTo(cx + u, cy - u)
          ..lineTo(cx + 3 * u, cy - u)
          ..lineTo(cx + 3 * u, cy + u)
          ..lineTo(cx + u, cy + u)
          ..lineTo(cx + u, cy + 3 * u)
          ..lineTo(cx - u, cy + 3 * u)
          ..lineTo(cx - u, cy + u)
          ..lineTo(cx - 3 * u, cy + u)
          ..lineTo(cx - 3 * u, cy - u)
          ..lineTo(cx - u, cy - u)
          ..close();
      case ShapeType.star4:
        final double cx = w / 2;
        final double cy = h / 2;
        final double rOuter = min(w, h) * 0.4;
        final double rInner = min(w, h) * 0.15;
        final path = Path();
        for (int i = 0; i < 8; i++) {
          final double angle = i * pi / 4 - pi / 2;
          final double r = i.isEven ? rOuter : rInner;
          final double x = cx + r * cos(angle);
          final double y = cy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        return path;
      case ShapeType.lightning:
        final double cx = w / 2;
        final double cy = h / 2;
        final double u = min(w, h) / 7;
        return Path()
          ..moveTo(cx + u, cy - 3 * u)
          ..lineTo(cx - 2 * u, cy)
          ..lineTo(cx - u, cy)
          ..lineTo(cx - 2 * u, cy + 3 * u)
          ..lineTo(cx + u, cy)
          ..lineTo(cx, cy)
          ..close();
    }
  }

  @override
  bool shouldRepaint(covariant OptionShapePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.rotation != rotation ||
        oldDelegate.color != color ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isSolved != isSolved;
  }
}
