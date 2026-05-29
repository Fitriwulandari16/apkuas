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

class CircleConditionalPatternsScreen extends ConsumerStatefulWidget {
  final int levelId;
  const CircleConditionalPatternsScreen({super.key, this.levelId = 30});

  @override
  ConsumerState<CircleConditionalPatternsScreen> createState() => _CircleConditionalPatternsScreenState();
}

enum CircleColor { yellow, green, blue, orange }

enum LinePattern { vertical, horizontal, diagonalUpRight, diagonalDownRight }

class ClassifiedLine {
  final Offset start;
  final Offset end;
  final LinePattern pattern;

  ClassifiedLine({
    required this.start,
    required this.end,
    required this.pattern,
  });
}

class CircleItem {
  final int id;
  final CircleColor colorType;
  bool isCorrect;
  List<ClassifiedLine> currentLines;

  CircleItem({
    required this.id,
    required this.colorType,
    this.isCorrect = false,
  }) : currentLines = [];

  Color get color {
    switch (colorType) {
      case CircleColor.yellow:
        return const Color(0xFFFFD54F);
      case CircleColor.green:
        return const Color(0xFF9CCC65);
      case CircleColor.blue:
        return const Color(0xFF3EA5E1);
      case CircleColor.orange:
        return const Color(0xFFEF5350);
    }
  }

  CircleColor get requiredColor {
    return colorType;
  }
}

class _CircleConditionalPatternsScreenState extends ConsumerState<CircleConditionalPatternsScreen> {
  late List<CircleItem> _circles;

  // Active drawing tracking
  int? _drawingCircleId;
  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 4x4 Latin Square layout matching textbook photo:
    // Row 1: Yellow, Green, Blue, Orange/Red
    // Row 2: Blue, Orange/Red, Yellow, Green
    // Row 3: Green, Blue, Orange/Red, Yellow
    // Row 4: Orange/Red, Yellow, Green, Blue
    final List<CircleColor> layout = [
      CircleColor.yellow, CircleColor.green,  CircleColor.blue,   CircleColor.orange,
      CircleColor.blue,   CircleColor.orange, CircleColor.yellow, CircleColor.green,
      CircleColor.green,  CircleColor.blue,   CircleColor.orange, CircleColor.yellow,
      CircleColor.orange, CircleColor.yellow, CircleColor.green,  CircleColor.blue,
    ];

    _circles = List.generate(layout.length, (index) {
      return CircleItem(
        id: index,
        colorType: layout[index],
      );
    });
  }

  void _handlePanStart(int id, Offset localPos) {
    final item = _circles.firstWhere((c) => c.id == id);
    if (item.isCorrect) return;

    HapticService.light();
    setState(() {
      _drawingCircleId = id;
      _dragStart = localPos;
      _dragCurrent = localPos;
    });
  }

  void _handlePanUpdate(int id, Offset localPos) {
    if (_drawingCircleId != id) return;
    setState(() {
      _dragCurrent = localPos;
    });
  }

  void _handlePanEnd(int id, Size size) {
    if (_drawingCircleId != id || _dragStart == null || _dragCurrent == null) return;

    final item = _circles.firstWhere((c) => c.id == id);
    final w = size.width;
    final h = size.height;

    final dx = _dragCurrent!.dx - _dragStart!.dx;
    final dy = _dragCurrent!.dy - _dragStart!.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Minimum drag distance to register a line (avoiding accidental taps)
    if (distance > 15.0) {
      // Normalize coordinate metrics (0.0 to 1.0)
      final normStart = Offset(_dragStart!.dx / w, _dragStart!.dy / h);
      final normEnd = Offset(_dragCurrent!.dx / w, _dragCurrent!.dy / h);
      final normDx = normEnd.dx - normStart.dx;
      final normDy = normEnd.dy - normStart.dy;

      LinePattern? pattern;
      final absDx = normDx.abs();
      final absDy = normDy.abs();

      if (absDy > absDx * 1.6) {
        pattern = LinePattern.vertical;
      } else if (absDx > absDy * 1.6) {
        pattern = LinePattern.horizontal;
      } else if (absDx > 0.45 * absDy && absDy > 0.45 * absDx) {
        if (normDx * normDy < 0) {
          pattern = LinePattern.diagonalUpRight; // /
        } else {
          pattern = LinePattern.diagonalDownRight; // \
        }
      }

      if (pattern != null) {
        setState(() {
          item.currentLines.add(ClassifiedLine(
            start: normStart,
            end: normEnd,
            pattern: pattern!,
          ));
        });

        // Trigger validation if we have reached exactly 2 lines
        if (item.currentLines.length == 2) {
          _validateCircle(item);
        } else {
          HapticService.light();
        }
      } else {
        HapticService.failure();
      }
    } else {
      HapticService.failure();
    }

    setState(() {
      _drawingCircleId = null;
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _validateCircle(CircleItem item) {
    final line1 = item.currentLines[0];
    final line2 = item.currentLines[1];
    final pat1 = line1.pattern;
    final pat2 = line2.pattern;

    bool isMatch = false;

    switch (item.colorType) {
      case CircleColor.yellow: // Silang (X)
        // Must contain 1 diagonal up-right and 1 diagonal down-right
        isMatch = (pat1 == LinePattern.diagonalUpRight && pat2 == LinePattern.diagonalDownRight) ||
                  (pat1 == LinePattern.diagonalDownRight && pat2 == LinePattern.diagonalUpRight);
        break;

      case CircleColor.green: // Plus (+)
        // Must contain 1 vertical and 1 horizontal
        isMatch = (pat1 == LinePattern.vertical && pat2 == LinePattern.horizontal) ||
                  (pat1 == LinePattern.horizontal && pat2 == LinePattern.vertical);
        break;

      case CircleColor.blue: // Vertikal Sejajar (||)
        // Both vertical, separated horizontally
        if (pat1 == LinePattern.vertical && pat2 == LinePattern.vertical) {
          final midX1 = (line1.start.dx + line1.end.dx) / 2;
          final midX2 = (line2.start.dx + line2.end.dx) / 2;
          isMatch = (midX1 < 0.5 && midX2 > 0.5) || (midX1 > 0.5 && midX2 < 0.5);
        }
        break;

      case CircleColor.orange: // Horizontal Sejajar (=)
        // Both horizontal, separated vertically
        if (pat1 == LinePattern.horizontal && pat2 == LinePattern.horizontal) {
          final midY1 = (line1.start.dy + line1.end.dy) / 2;
          final midY2 = (line2.start.dy + line2.end.dy) / 2;
          isMatch = (midY1 < 0.5 && midY2 > 0.5) || (midY1 > 0.5 && midY2 < 0.5);
        }
        break;
    }

    if (isMatch) {
      SoundService.playSuccess();
      HapticService.success();
      setState(() {
        item.isCorrect = true;
      });

      // Check level completion
      if (_circles.every((c) => c.isCorrect)) {
        _onLevelComplete();
      }
    } else {
      HapticService.failure();
      // On failure, clear lines to let child redraw
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            item.currentLines.clear();
          });
        }
      });
    }
  }

  void _onLevelComplete() async {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    try {
      await UserService.updateProgress(30);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 30: $e');
    }

    if (!mounted) return;
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 31, // Next level stage placeholder
      title: 'Hore, Kamu Juara!',
      message: 'Kamu berhasil menggambar semua pola garis kompleks dengan benar!',
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
            // Guide circles legend
            _buildRulesLegend(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 12, thickness: 1),
            ),
            // Play Area Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _circles.length,
                  itemBuilder: (context, index) {
                    final item = _circles[index];
                    final isDrawingThis = _drawingCircleId == item.id;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);

                        return GestureDetector(
                          onPanStart: (details) => _handlePanStart(item.id, details.localPosition),
                          onPanUpdate: (details) => _handlePanUpdate(item.id, details.localPosition),
                          onPanEnd: (details) => _handlePanEnd(item.id, size),
                          child: CustomPaint(
                            painter: CircleCellPainter(
                              item: item,
                              isDrawing: isDrawingThis,
                              dragStart: _dragStart,
                              dragCurrent: _dragCurrent,
                            ),
                          ),
                        );
                      },
                    );
                  },
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
              'Level 30',
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gesture_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Buat garis yang tepat pada setiap warna sesuai contoh!',
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

  Widget _buildRulesLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendCell(CircleColor.yellow, 'X'),
          _buildLegendCell(CircleColor.green, '+'),
          _buildLegendCell(CircleColor.blue, '||'),
          _buildLegendCell(CircleColor.orange, '='),
        ],
      ),
    );
  }

  Widget _buildLegendCell(CircleColor colorType, String label) {
    // Generate dummy completed item for legend visual representation
    final dummyItem = CircleItem(id: -1, colorType: colorType);
    dummyItem.isCorrect = true;

    // Prefill the lines based on the type
    if (colorType == CircleColor.yellow) {
      dummyItem.currentLines = [
        ClassifiedLine(start: const Offset(0.15, 0.15), end: const Offset(0.85, 0.85), pattern: LinePattern.diagonalDownRight),
        ClassifiedLine(start: const Offset(0.15, 0.85), end: const Offset(0.85, 0.15), pattern: LinePattern.diagonalUpRight),
      ];
    } else if (colorType == CircleColor.green) {
      dummyItem.currentLines = [
        ClassifiedLine(start: const Offset(0.5, 0.05), end: const Offset(0.5, 0.95), pattern: LinePattern.vertical),
        ClassifiedLine(start: const Offset(0.05, 0.5), end: const Offset(0.95, 0.5), pattern: LinePattern.horizontal),
      ];
    } else if (colorType == CircleColor.blue) {
      dummyItem.currentLines = [
        ClassifiedLine(start: const Offset(0.28, 0.05), end: const Offset(0.28, 0.95), pattern: LinePattern.vertical),
        ClassifiedLine(start: const Offset(0.72, 0.05), end: const Offset(0.72, 0.95), pattern: LinePattern.vertical),
      ];
    } else {
      dummyItem.currentLines = [
        ClassifiedLine(start: const Offset(0.05, 0.28), end: const Offset(0.95, 0.28), pattern: LinePattern.horizontal),
        ClassifiedLine(start: const Offset(0.05, 0.72), end: const Offset(0.95, 0.72), pattern: LinePattern.horizontal),
      ];
    }

    return Column(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: CustomPaint(
            painter: CircleCellPainter(
              item: dummyItem,
              isDrawing: false,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class CircleCellPainter extends CustomPainter {
  final CircleItem item;
  final bool isDrawing;
  final Offset? dragStart;
  final Offset? dragCurrent;

  CircleCellPainter({
    required this.item,
    required this.isDrawing,
    this.dragStart,
    this.dragCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);

    // 1. Draw Circle Fill Background
    final fillPaint = Paint()
      ..color = item.color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    // 2. Draw Sphere-Style Glossy White Highlight on top-left
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(radius * 0.2, radius * 0.2, radius * 0.6, radius * 0.4),
      highlightPaint,
    );

    // 3. Draw Circle White Border
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, strokePaint);

    // 4. Draw Lines already correct or draft
    final linePaint = Paint()
      ..color = item.isCorrect ? const Color(0xFF212121) : const Color(0xFF37474F)
      ..strokeWidth = item.isCorrect ? 4.5 : 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var line in item.currentLines) {
      final startPixel = Offset(line.start.dx * size.width, line.start.dy * size.height);
      final endPixel = Offset(line.end.dx * size.width, line.end.dy * size.height);
      canvas.drawLine(startPixel, endPixel, linePaint);
    }

    // 5. Draw Active Line Drawing Preview
    if (isDrawing && dragStart != null && dragCurrent != null) {
      final previewPaint = Paint()
        ..color = const Color(0xFF37474F).withOpacity(0.6)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(dragStart!, dragCurrent!, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CircleCellPainter oldDelegate) {
    return oldDelegate.item.isCorrect != item.isCorrect ||
        oldDelegate.item.currentLines.length != item.currentLines.length ||
        oldDelegate.isDrawing != isDrawing ||
        oldDelegate.dragCurrent != dragCurrent;
  }
}
