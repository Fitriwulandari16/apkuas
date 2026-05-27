import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class HexagonConditionalLinesScreen extends ConsumerStatefulWidget {
  final int levelId;
  const HexagonConditionalLinesScreen({super.key, this.levelId = 29});

  @override
  ConsumerState<HexagonConditionalLinesScreen> createState() => _HexagonConditionalLinesScreenState();
}

enum HexColor { blue, yellow, green, red }

enum LinePattern { vertical, horizontal, diagonalUpRight, diagonalDownRight }

class HexagonItem {
  final int id;
  final HexColor colorType;
  bool isCorrect;
  LinePattern? drawnPattern;

  HexagonItem({
    required this.id,
    required this.colorType,
    this.isCorrect = false,
    this.drawnPattern,
  });

  Color get color {
    switch (colorType) {
      case HexColor.blue:
        return const Color(0xFF3EA5E1);
      case HexColor.yellow:
        return const Color(0xFFFFD54F);
      case HexColor.green:
        return const Color(0xFF9CCC65);
      case HexColor.red:
        return const Color(0xFFEF5350);
    }
  }

  LinePattern get requiredPattern {
    switch (colorType) {
      case HexColor.blue:
        return LinePattern.vertical;
      case HexColor.yellow:
        return LinePattern.horizontal;
      case HexColor.green:
        return LinePattern.diagonalUpRight; // /
      case HexColor.red:
        return LinePattern.diagonalDownRight; // \
    }
  }
}

class _HexagonConditionalLinesScreenState extends ConsumerState<HexagonConditionalLinesScreen> {
  late List<HexagonItem> _hexagons;

  // Active drawing tracking
  int? _drawingHexagonId;
  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 4x4 Latin Square layout matching textbook photo:
    // Row 1: Blue, Yellow, Green, Red
    // Row 2: Green, Red, Blue, Yellow
    // Row 3: Yellow, Green, Red, Blue
    // Row 4: Red, Blue, Yellow, Green
    final List<HexColor> layout = [
      HexColor.blue,  HexColor.yellow, HexColor.green,  HexColor.red,
      HexColor.green, HexColor.red,    HexColor.blue,   HexColor.yellow,
      HexColor.yellow, HexColor.green,  HexColor.red,    HexColor.blue,
      HexColor.red,   HexColor.blue,   HexColor.yellow, HexColor.green,
    ];

    _hexagons = List.generate(layout.length, (index) {
      return HexagonItem(
        id: index,
        colorType: layout[index],
      );
    });
  }

  void _handlePanStart(int id, Offset localPos) {
    final item = _hexagons.firstWhere((h) => h.id == id);
    if (item.isCorrect) return;

    HapticService.light();
    setState(() {
      _drawingHexagonId = id;
      _dragStart = localPos;
      _dragCurrent = localPos;
    });
  }

  void _handlePanUpdate(int id, Offset localPos) {
    if (_drawingHexagonId != id) return;
    setState(() {
      _dragCurrent = localPos;
    });
  }

  void _handlePanEnd(int id) {
    if (_drawingHexagonId != id || _dragStart == null || _dragCurrent == null) return;

    final item = _hexagons.firstWhere((h) => h.id == id);
    final dx = _dragCurrent!.dx - _dragStart!.dx;
    final dy = _dragCurrent!.dy - _dragStart!.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Minimum drag distance to register a line (avoiding accidental taps)
    if (distance > 20.0) {
      // Determine line slope and pattern
      LinePattern? pattern;
      final absDx = dx.abs();
      final absDy = dy.abs();

      if (absDy > absDx * 1.8) {
        pattern = LinePattern.vertical;
      } else if (absDx > absDy * 1.8) {
        pattern = LinePattern.horizontal;
      } else if (absDx > 0.5 * absDy && absDy > 0.5 * absDx) {
        // Diagonal check (Note: Y-axis is inverted in flutter canvas coordinates)
        if (dx * dy < 0) {
          pattern = LinePattern.diagonalUpRight; // Bottom-left to Top-right (/)
        } else {
          pattern = LinePattern.diagonalDownRight; // Top-left to Bottom-right (\)
        }
      }

      if (pattern != null && pattern == item.requiredPattern) {
        // Correct drawing matching condition!
        SoundService.playSuccess();
        HapticService.success();

        setState(() {
          item.isCorrect = true;
          item.drawnPattern = pattern;
        });

        // Check if all hexagons are correct
        if (_hexagons.every((h) => h.isCorrect)) {
          _onLevelComplete();
        }
      } else {
        // Incorrect
        HapticService.failure();
      }
    } else {
      HapticService.failure();
    }

    setState(() {
      _drawingHexagonId = null;
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 30, // Fallback for next stages
      title: 'Kamu Luar Biasa!',
      message: 'Semua garis kondisi logika berhasil digambar dengan sempurna!',
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
            // Legenda Aturan di Bagian Atas
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
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _hexagons.length,
                  itemBuilder: (context, index) {
                    final item = _hexagons[index];
                    final isDrawingThis = _drawingHexagonId == item.id;

                    return GestureDetector(
                      onPanStart: (details) => _handlePanStart(item.id, details.localPosition),
                      onPanUpdate: (details) => _handlePanUpdate(item.id, details.localPosition),
                      onPanEnd: (details) => _handlePanEnd(item.id),
                      child: CustomPaint(
                        painter: HexagonCellPainter(
                          item: item,
                          isDrawing: isDrawingThis,
                          dragStart: _dragStart,
                          dragCurrent: _dragCurrent,
                        ),
                      ),
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
              'Level 29',
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
          const Icon(Icons.rule_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Buat garis yang tepat pada setiap warna sesuai contoh!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesLegend() {
    // Show the 4 guide hexagons (Blue, Yellow, Green, Red) with their respective lines
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
          _buildLegendCell(HexColor.blue, LinePattern.vertical, '|'),
          _buildLegendCell(HexColor.yellow, LinePattern.horizontal, '—'),
          _buildLegendCell(HexColor.green, LinePattern.diagonalUpRight, '/'),
          _buildLegendCell(HexColor.red, LinePattern.diagonalDownRight, '\\'),
        ],
      ),
    );
  }

  Widget _buildLegendCell(HexColor colorType, LinePattern pattern, String label) {
    final dummyItem = HexagonItem(id: -1, colorType: colorType, isCorrect: true, drawnPattern: pattern);

    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 46,
          child: CustomPaint(
            painter: HexagonCellPainter(
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

class HexagonCellPainter extends CustomPainter {
  final HexagonItem item;
  final bool isDrawing;
  final Offset? dragStart;
  final Offset? dragCurrent;

  HexagonCellPainter({
    required this.item,
    required this.isDrawing,
    this.dragStart,
    this.dragCurrent,
  });

  Path _getHexagonPath(Size size) {
    final path = Path();
    double w = size.width;
    double h = size.height;
    // Flat top and bottom, pointy left and right
    path.moveTo(w * 0.25, 0);
    path.lineTo(w * 0.75, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.75, h);
    path.lineTo(w * 0.25, h);
    path.lineTo(0, h * 0.5);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getHexagonPath(size);

    // 1. Draw Hexagon Fill Background
    final fillPaint = Paint()
      ..color = item.color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 2. Draw Hexagon Highlight Flare (Top curve effect) for textbook realism
    final flarePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final flarePath = Path();
    flarePath.moveTo(size.width * 0.25, 0);
    flarePath.lineTo(size.width * 0.75, 0);
    flarePath.lineTo(size.width * 0.85, size.height * 0.2);
    flarePath.lineTo(size.width * 0.15, size.height * 0.2);
    flarePath.close();
    canvas.drawPath(flarePath, flarePaint);

    // 3. Draw Hexagon Outline
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // 4. Draw Correct Line (if completed)
    if (item.isCorrect && item.drawnPattern != null) {
      final linePaint = Paint()
        ..color = const Color(0xFF263238) // Solid slate/dark charcoal color for high visibility
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      _drawPatternLine(canvas, size, item.drawnPattern!, linePaint);
    }

    // 5. Draw Active Dragging Line Preview
    if (isDrawing && dragStart != null && dragCurrent != null) {
      final previewPaint = Paint()
        ..color = const Color(0xFF263238).withOpacity(0.6)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(dragStart!, dragCurrent!, previewPaint);
    }
  }

  void _drawPatternLine(Canvas canvas, Size size, LinePattern pattern, Paint paint) {
    double w = size.width;
    double h = size.height;

    switch (pattern) {
      case LinePattern.vertical:
        // Draw slightly exceeding or exactly centered vertical line
        canvas.drawLine(Offset(w * 0.5, h * -0.05), Offset(w * 0.5, h * 1.05), paint);
        break;
      case LinePattern.horizontal:
        // Horizontal line
        canvas.drawLine(Offset(w * -0.05, h * 0.5), Offset(w * 1.05, h * 0.5), paint);
        break;
      case LinePattern.diagonalUpRight: // /
        canvas.drawLine(Offset(w * 0.12, h * 0.88), Offset(w * 0.88, h * 0.12), paint);
        break;
      case LinePattern.diagonalDownRight: // \
        canvas.drawLine(Offset(w * 0.12, h * 0.12), Offset(w * 0.88, h * 0.88), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant HexagonCellPainter oldDelegate) {
    return oldDelegate.item.isCorrect != item.isCorrect ||
        oldDelegate.isDrawing != isDrawing ||
        oldDelegate.dragCurrent != dragCurrent;
  }
}
