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

enum ArrowDirection { up, down, left, right }

class ArrowModel {
  final int index;
  final ArrowDirection direction;
  final double relativeX;
  final double relativeY;
  final double scale;
  bool isColored;

  ArrowModel({
    required this.index,
    required this.direction,
    required this.relativeX,
    required this.relativeY,
    this.scale = 1.0,
    this.isColored = false,
  });

  double get rotation {
    switch (direction) {
      case ArrowDirection.right:
        return 0.0;
      case ArrowDirection.down:
        return pi / 2;
      case ArrowDirection.left:
        return pi;
      case ArrowDirection.up:
        return -pi / 2;
    }
  }

  bool get isCorrectTarget => direction == ArrowDirection.right;
}

class ArrowFilteringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ArrowFilteringScreen({super.key, this.levelId = 43});

  @override
  ConsumerState<ArrowFilteringScreen> createState() => _ArrowFilteringScreenState();
}

class _ArrowFilteringScreenState extends ConsumerState<ArrowFilteringScreen> with TickerProviderStateMixin {
  static const Color colTargetGreen = Color(0xFF22C55E); // Green coloring

  late List<ArrowModel> _arrows;
  int? _shakingArrowIndex;

  // Completion slide animation
  late AnimationController _slideController;
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _initLevel() {
    // 25 scattered arrows based on workbook page 23 layout
    _arrows = [
      ArrowModel(index: 0, direction: ArrowDirection.right, relativeX: 0.05, relativeY: 0.02, scale: 1.25), // Reference Green top-left in book
      ArrowModel(index: 1, direction: ArrowDirection.down, relativeX: 0.28, relativeY: 0.04, scale: 0.95),
      ArrowModel(index: 2, direction: ArrowDirection.right, relativeX: 0.46, relativeY: 0.05, scale: 1.15),
      ArrowModel(index: 3, direction: ArrowDirection.up, relativeX: 0.65, relativeY: 0.02, scale: 1.30),
      ArrowModel(index: 4, direction: ArrowDirection.down, relativeX: 0.85, relativeY: 0.12, scale: 0.90),
      ArrowModel(index: 5, direction: ArrowDirection.left, relativeX: 0.22, relativeY: 0.16, scale: 1.05),
      ArrowModel(index: 6, direction: ArrowDirection.left, relativeX: 0.44, relativeY: 0.16, scale: 1.10),
      ArrowModel(index: 7, direction: ArrowDirection.up, relativeX: 0.04, relativeY: 0.20, scale: 1.00),
      ArrowModel(index: 8, direction: ArrowDirection.up, relativeX: 0.20, relativeY: 0.26, scale: 0.85),
      ArrowModel(index: 9, direction: ArrowDirection.right, relativeX: 0.32, relativeY: 0.24, scale: 1.00),
      ArrowModel(index: 10, direction: ArrowDirection.down, relativeX: 0.52, relativeY: 0.26, scale: 1.25),
      ArrowModel(index: 11, direction: ArrowDirection.right, relativeX: 0.69, relativeY: 0.25, scale: 0.80),
      ArrowModel(index: 12, direction: ArrowDirection.right, relativeX: 0.08, relativeY: 0.33, scale: 0.85),
      ArrowModel(index: 13, direction: ArrowDirection.down, relativeX: 0.04, relativeY: 0.45, scale: 0.90),
      ArrowModel(index: 14, direction: ArrowDirection.down, relativeX: 0.18, relativeY: 0.46, scale: 1.40),
      ArrowModel(index: 15, direction: ArrowDirection.right, relativeX: 0.38, relativeY: 0.46, scale: 1.15),
      ArrowModel(index: 16, direction: ArrowDirection.up, relativeX: 0.58, relativeY: 0.48, scale: 1.05),
      ArrowModel(index: 17, direction: ArrowDirection.up, relativeX: 0.72, relativeY: 0.34, scale: 1.45),
      ArrowModel(index: 18, direction: ArrowDirection.up, relativeX: 0.04, relativeY: 0.64, scale: 1.30),
      ArrowModel(index: 19, direction: ArrowDirection.right, relativeX: 0.22, relativeY: 0.68, scale: 0.95),
      ArrowModel(index: 20, direction: ArrowDirection.left, relativeX: 0.32, relativeY: 0.60, scale: 1.10),
      ArrowModel(index: 21, direction: ArrowDirection.left, relativeX: 0.46, relativeY: 0.58, scale: 1.00),
      ArrowModel(index: 22, direction: ArrowDirection.up, relativeX: 0.53, relativeY: 0.70, scale: 0.85),
      ArrowModel(index: 23, direction: ArrowDirection.right, relativeX: 0.63, relativeY: 0.58, scale: 1.00),
      ArrowModel(index: 24, direction: ArrowDirection.down, relativeX: 0.80, relativeY: 0.62, scale: 1.15),
    ];

    // Mark the first reference arrow as pre-colored to guide children
    _arrows[0].isColored = true;
  }

  void _handleArrowTap(int index) {
    if (_isSolved) return;
    final arrow = _arrows[index];

    if (arrow.isColored) return;

    if (arrow.isCorrectTarget) {
      // Correct: right-pointing arrow
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        arrow.isColored = true;
      });

      // Check if all right-pointing arrows are now green
      final targets = _arrows.where((a) => a.isCorrectTarget);
      if (targets.every((a) => a.isColored)) {
        _onLevelComplete();
      }
    } else {
      // Incorrect direction tapped
      _shakeArrow(index);
    }
  }

  void _shakeArrow(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingArrowIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _shakingArrowIndex = null;
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
      await UserService.updateProgress(widget.levelId);
    } catch (e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    }

    // 3. Play slide-off forward animation for target arrows
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // 4. Show success victory dialog
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: widget.levelId + 1,
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
            _buildLegendHeader(),
            const SizedBox(height: 4),
            // Play Area (Arrows Scatter Stack Board)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double boardW = constraints.maxWidth;
                        final double boardH = constraints.maxHeight;

                        // Base dimension size of a standard arrow
                        final double baseArrowW = boardW * 0.17;
                        final double baseArrowH = boardH * 0.10;

                        return AnimatedBuilder(
                          animation: _slideController,
                          builder: (context, child) {
                            return Stack(
                              children: _arrows.map((arrow) {
                                final double arrowW = baseArrowW * arrow.scale;
                                final double arrowH = baseArrowH * arrow.scale;

                                // Calculate absolute base coordinates
                                final double absoluteX = arrow.relativeX * (boardW - arrowW);
                                final double absoluteY = arrow.relativeY * (boardH - arrowH);

                                // Slide forward offset when solved
                                double slideX = 0.0;
                                if (_isSolved && arrow.isCorrectTarget) {
                                  // EaseIn forward slide offset
                                  slideX = _slideController.value * 500.0;
                                }

                                final isShaking = _shakingArrowIndex == arrow.index;
                                final double shakeX = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

                                return Positioned(
                                  left: absoluteX + shakeX + slideX,
                                  top: absoluteY,
                                  width: arrowW,
                                  height: arrowH,
                                  child: GestureDetector(
                                    onTap: () => _handleArrowTap(arrow.index),
                                    child: Transform.rotate(
                                      angle: arrow.rotation,
                                      child: Container(
                                        color: Colors.transparent, // expand hit-test
                                        child: CustomPaint(
                                          painter: ArrowShapePainter(
                                            isColored: arrow.isColored,
                                            fillColor: colTargetGreen,
                                            isSolved: _isSolved && arrow.isCorrectTarget,
                                            opacity: _isSolved && arrow.isCorrectTarget 
                                                ? (1.0 - _slideController.value).clamp(0.0, 1.0) 
                                                : 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
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
            _buildPalette(),
            const SizedBox(height: 16),
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
              'Level 43',
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
          const Icon(Icons.touch_app_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Ketuk semua anak panah yang menunjuk ke arah KANAN!',
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

  Widget _buildLegendHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Target:',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            height: 24,
            child: CustomPaint(
              painter: ArrowShapePainter(
                isColored: true,
                fillColor: colTargetGreen,
                isSolved: false,
                opacity: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(Panah Kanan)',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colTargetGreen,
            ),
          ),
        ],
      ),
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
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colTargetGreen,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2C3E50),
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: colTargetGreen.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Warna Aktif: HIJAU',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colTargetGreen,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ArrowShapePainter extends CustomPainter {
  final bool isColored;
  final Color fillColor;
  final bool isSolved;
  final double opacity;

  ArrowShapePainter({
    required this.isColored,
    required this.fillColor,
    required this.isSolved,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()
      ..color = isColored ? fillColor.withOpacity(opacity) : Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF334155).withOpacity(opacity)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double headW = w * 0.46;
    final double tailH = h * 0.44;

    final path = Path()
      ..moveTo(2, (h - tailH) / 2)
      ..lineTo(w - headW, (h - tailH) / 2)
      ..lineTo(w - headW, 2)
      ..lineTo(w - 2, h / 2)
      ..lineTo(w - headW, h - 2)
      ..lineTo(w - headW, (h + tailH) / 2)
      ..lineTo(2, (h + tailH) / 2)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Premium gloss highlight on upper edge of the arrow tail/head
    if (isColored) {
      final glossPaint = Paint()
        ..color = Colors.white.withOpacity(0.3 * opacity)
        ..style = PaintingStyle.fill;
      final glossPath = Path()
        ..moveTo(4, (h - tailH) / 2 + 1.5)
        ..lineTo(w - headW, (h - tailH) / 2 + 1.5)
        ..lineTo(w - headW, 4)
        ..lineTo(w - 6, h / 2)
        ..lineTo(w - headW + 2, h / 2)
        ..lineTo(w - headW + 2, (h - tailH) / 2 + 4)
        ..lineTo(4, (h - tailH) / 2 + 4)
        ..close();
      canvas.drawPath(glossPath, glossPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ArrowShapePainter oldDelegate) {
    return oldDelegate.isColored != isColored ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.isSolved != isSolved ||
        oldDelegate.opacity != opacity;
  }
}
