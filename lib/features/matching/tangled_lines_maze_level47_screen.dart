import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

/// Level 47 — Tangled Lines Matching (formerly Level 28).
/// Identical logic; progress is now reported as level 47.
class TangledLinesMazeLevelScreen extends ConsumerStatefulWidget {
  final int levelId;
  const TangledLinesMazeLevelScreen({super.key, this.levelId = 47});

  @override
  ConsumerState<TangledLinesMazeLevelScreen> createState() =>
      _TangledLinesMazeLevelScreenState();
}

class _TangledLinesMazeLevelScreenState
    extends ConsumerState<TangledLinesMazeLevelScreen> {
  static const Color colOrange = Color(0xFFFFAA00);
  static const Color colGreen = Color(0xFF4CAF50);
  static const Color colBrown = Color(0xFF8D6E63);
  static const Color colPurple = Color(0xFFAB47BC);
  static const Color colYellow = Color(0xFFFFD54F);

  final Map<int, Color> _targetColorMap = {
    1: colOrange,
    2: colGreen,
    3: colBrown,
    4: colPurple,
    5: colYellow,
  };

  final Map<int, Color?> _placedColors = {
    1: null,
    2: null,
    3: null,
    4: null,
    5: null,
  };

  void _handleColorDrop(int number, Color draggedColor) {
    final correctColor = _targetColorMap[number];

    if (draggedColor == correctColor) {
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        _placedColors[number] = draggedColor;
      });

      if (_placedColors.values.every((c) => c != null)) {
        _onLevelComplete();
      }
    } else {
      HapticService.failure();
    }
  }

  void _onLevelComplete() async {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    try {
      await UserService.updateProgress(widget.levelId);
    } catch (e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    }

    if (!mounted) return;
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: widget.levelId + 1,
      title: 'Luar Biasa Hebat!',
      message: 'Kamu berhasil menelusuri semua jalur kusut dengan benar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildTangledCanvas(),
                      const SizedBox(height: 12),
                      _buildTargetBar(),
                      const SizedBox(height: 16),
                      _buildColorDock(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
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
              'Level ${widget.levelId}',
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
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gesture_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Telusuri setiap garis dan warnai lingkaran sesuai pasangannya!',
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

  Widget _buildTangledCanvas() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.deepPurple.shade100, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            Offset getPos(double dx, double dy) =>
                Offset(dx * size.width, dy * size.height);

            final nodePositions = {
              '1': getPos(0.50, 0.15),
              '2': getPos(0.18, 0.32),
              '3': getPos(0.32, 0.17),
              '4': getPos(0.68, 0.17),
              '5': getPos(0.18, 0.58),
              '3_col': getPos(0.85, 0.32),
              '4_col': getPos(0.85, 0.58),
              '5_col': getPos(0.32, 0.83),
              '2_col': getPos(0.50, 0.83),
              '1_col': getPos(0.68, 0.83),
            };

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: TangledLinesPainterL47(nodes: nodePositions),
                  ),
                ),
                _buildNumberNode('3', nodePositions['3']!),
                _buildNumberNode('1', nodePositions['1']!),
                _buildNumberNode('4', nodePositions['4']!),
                _buildNumberNode('2', nodePositions['2']!),
                _buildNumberNode('5', nodePositions['5']!),
                _buildStaticColorNode(colBrown, nodePositions['3_col']!),
                _buildStaticColorNode(colPurple, nodePositions['4_col']!),
                _buildStaticColorNode(colYellow, nodePositions['5_col']!),
                _buildStaticColorNode(colGreen, nodePositions['2_col']!),
                _buildStaticColorNode(colOrange, nodePositions['1_col']!),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumberNode(String label, Offset pos) {
    const double radius = 24.0;
    return Positioned(
      left: pos.dx - radius,
      top: pos.dy - radius,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticColorNode(Color color, Offset pos) {
    const double radius = 22.0;
    return Positioned(
      left: pos.dx - radius,
      top: pos.dy - radius,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetBar() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.deepPurple.shade50, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final int number = index + 1;
          final Color? placedColor = _placedColors[number];

          return Expanded(
            child: Column(
              children: [
                Text(
                  '$number',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                DragTarget<Color>(
                  onWillAcceptWithDetails: (details) =>
                      _placedColors[number] == null,
                  onAcceptWithDetails: (details) =>
                      _handleColorDrop(number, details.data),
                  builder: (context, candidateData, rejectedData) {
                    final bool isHovered = candidateData.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: placedColor ??
                            (isHovered
                                ? Colors.deepPurple.shade50
                                : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: placedColor != null
                              ? Colors.transparent
                              : (isHovered
                                  ? Colors.deepPurple
                                  : Colors.grey.shade300),
                          width: placedColor != null
                              ? 0
                              : (isHovered ? 2.5 : 1.5),
                          style: placedColor != null
                              ? BorderStyle.none
                              : BorderStyle.solid,
                        ),
                        boxShadow: [
                          if (placedColor != null)
                            BoxShadow(
                              color: placedColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: placedColor != null
                          ? const Center(
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildColorDock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfiniteDraggableColor(colGreen),
          _buildInfiniteDraggableColor(colOrange),
          _buildInfiniteDraggableColor(colYellow),
          _buildInfiniteDraggableColor(colPurple),
          _buildInfiniteDraggableColor(colBrown),
        ],
      ),
    );
  }

  Widget _buildInfiniteDraggableColor(Color color) {
    return Draggable<Color>(
      data: color,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: _buildColorBucket(color, isShadow: true),
        ),
      ),
      childWhenDragging: _buildColorBucket(color, isDragged: true),
      onDragStarted: () => HapticService.light(),
      onDraggableCanceled: (velocity, offset) => HapticService.failure(),
      child: _buildColorBucket(color),
    );
  }

  Widget _buildColorBucket(Color color,
      {bool isShadow = false, bool isDragged = false}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isDragged ? 0.3 : 1.0,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: isShadow ? Colors.black38 : color.withOpacity(0.35),
              blurRadius: isShadow ? 10 : 6,
              offset: Offset(0, isShadow ? 5 : 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.format_paint_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─── CustomPainter ───────────────────────────────────────────────────────────

class TangledLinesPainterL47 extends CustomPainter {
  final Map<String, Offset> nodes;
  TangledLinesPainterL47({required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final Map<Color, Path> coloredPaths = {
      const Color(0xFFFFAA00): Path()
        ..moveTo(nodes['1']!.dx, nodes['1']!.dy)
        ..cubicTo(
          nodes['1']!.dx - size.width * 0.05,
          nodes['1']!.dy + size.height * 0.25,
          nodes['1_col']!.dx + size.width * 0.1,
          nodes['1_col']!.dy - size.height * 0.35,
          nodes['1_col']!.dx,
          nodes['1_col']!.dy,
        ),
      const Color(0xFF4CAF50): Path()
        ..moveTo(nodes['2']!.dx, nodes['2']!.dy)
        ..cubicTo(
          nodes['2']!.dx + size.width * 0.35,
          nodes['2']!.dy + size.height * 0.05,
          nodes['2_col']!.dx - size.width * 0.3,
          nodes['2_col']!.dy - size.height * 0.3,
          nodes['2_col']!.dx,
          nodes['2_col']!.dy,
        ),
      const Color(0xFF8D6E63): Path()
        ..moveTo(nodes['3']!.dx, nodes['3']!.dy)
        ..cubicTo(
          nodes['3']!.dx + size.width * 0.3,
          nodes['3']!.dy + size.height * 0.3,
          nodes['3_col']!.dx - size.width * 0.2,
          nodes['3_col']!.dy - size.height * 0.1,
          nodes['3_col']!.dx,
          nodes['3_col']!.dy,
        ),
      const Color(0xFFAB47BC): Path()
        ..moveTo(nodes['4']!.dx, nodes['4']!.dy)
        ..cubicTo(
          nodes['4']!.dx - size.width * 0.15,
          nodes['4']!.dy + size.height * 0.35,
          nodes['4_col']!.dx - size.width * 0.15,
          nodes['4_col']!.dy - size.height * 0.15,
          nodes['4_col']!.dx,
          nodes['4_col']!.dy,
        ),
      const Color(0xFFFFD54F): Path()
        ..moveTo(nodes['5']!.dx, nodes['5']!.dy)
        ..cubicTo(
          nodes['5']!.dx + size.width * 0.25,
          nodes['5']!.dy + size.height * 0.1,
          nodes['5_col']!.dx - size.width * 0.1,
          nodes['5_col']!.dy - size.height * 0.25,
          nodes['5_col']!.dx,
          nodes['5_col']!.dy,
        ),
    };

    for (var entry in coloredPaths.entries) {
      final paint = Paint()
        ..color = entry.key.withOpacity(0.8)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      _drawDashedPath(canvas, entry.value, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    double dashWidth = 8.0;
    double dashSpace = 6.0;
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        double nextDistance = distance + dashWidth;
        if (nextDistance > measurePath.length) {
          nextDistance = measurePath.length;
        }
        canvas.drawPath(
          measurePath.extractPath(distance, nextDistance),
          paint,
        );
        distance = nextDistance + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
