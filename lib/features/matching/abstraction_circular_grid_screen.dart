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

class AbstractionCircleModel {
  final int index;
  final List<int> numbers; // [TL, TR, BL, BR]
  final List<bool> quadrantCorrect; // [TL, TR, BL, BR]

  AbstractionCircleModel({
    required this.index,
    required this.numbers,
    required this.quadrantCorrect,
  });

  bool get isFullyCorrect => quadrantCorrect.every((correct) => correct);
}

class AbstractionCircularGridScreen extends ConsumerStatefulWidget {
  final int levelId;
  const AbstractionCircularGridScreen({super.key, this.levelId = 35});

  @override
  ConsumerState<AbstractionCircularGridScreen> createState() => _AbstractionCircularGridScreenState();
}

class _AbstractionCircularGridScreenState extends ConsumerState<AbstractionCircularGridScreen> {
  // Vibrant Colors according to specification
  static const Color colOrange = Color(0xFFF97316); // Orange for '1'
  static const Color colGreen = Color(0xFF22C55E);  // Green for '2'
  static const Color colPink = Color(0xFFEC4899);   // Pink for '3'
  static const Color colBlue = Color(0xFF3B82F6);   // Blue for '4'

  final Map<int, Color> _numberColors = {
    1: colOrange,
    2: colGreen,
    3: colPink,
    4: colBlue,
  };

  final Map<Color, String> _colorNames = {
    colOrange: 'Oranye',
    colGreen: 'Hijau',
    colPink: 'Pink',
    colBlue: 'Biru',
  };

  Color? _selectedColor;
  late List<AbstractionCircleModel> _circles;
  int? _shakingIndex;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 3x3 Circular Grid matching Workbook page 14 patterns:
    // Circle 1: TL=1, TR=3, BL=4, BR=2
    // Circle 2: TL=2, TR=1, BL=3, BR=4
    // Circle 3: TL=4, TR=1, BL=2, BR=3
    // Circle 4: TL=3, TR=2, BL=1, BR=4
    // Circle 5: TL=1, TR=4, BL=3, BR=2
    // Circle 6: TL=2, TR=3, BL=4, BR=1
    // Circle 7: TL=4, TR=3, BL=1, BR=2
    // Circle 8: TL=3, TR=1, BL=2, BR=4
    // Circle 9: TL=2, TR=4, BL=1, BR=3
    final List<List<int>> layout = [
      [1, 3, 4, 2], // Circle 0
      [2, 1, 3, 4], // Circle 1
      [4, 1, 2, 3], // Circle 2
      [3, 2, 1, 4], // Circle 3
      [1, 4, 3, 2], // Circle 4
      [2, 3, 4, 1], // Circle 5
      [4, 3, 1, 2], // Circle 6
      [3, 1, 2, 4], // Circle 7
      [2, 4, 1, 3], // Circle 8
    ];

    _circles = List.generate(layout.length, (i) {
      return AbstractionCircleModel(
        index: i,
        numbers: layout[i],
        quadrantCorrect: [false, false, false, false],
      );
    });
  }

  void _handleQuadrantTap(int circleIndex, int quadrantIndex) {
    final circle = _circles[circleIndex];

    // Already correct
    if (circle.quadrantCorrect[quadrantIndex]) return;

    if (_selectedColor == null) {
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih warna di bawah terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final int targetNumber = circle.numbers[quadrantIndex];
    final Color targetColor = _numberColors[targetNumber]!;

    if (_selectedColor == targetColor) {
      // Correct color selected
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        circle.quadrantCorrect[quadrantIndex] = true;
      });

      // Check level completion (36 quadrants total)
      bool allCorrect = _circles.every((c) => c.quadrantCorrect.every((q) => q));
      if (allCorrect) {
        _onLevelComplete();
      }
    } else {
      // Wrong color selected
      _shakeCircle(circleIndex);
    }
  }

  void _shakeCircle(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _shakingIndex = null;
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

    // 3. Show Celebration Overlay leading to next level
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: widget.levelId + 1,
      title: 'Hebat, Kamu Pintar!',
      message: 'Kamu berhasil mewarnai semua lingkaran abstrak dengan sangat rapi!',
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
            _buildRulesLegend(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 12, thickness: 1),
            ),
            // Play Area Circular Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _circles.length,
                    itemBuilder: (context, index) {
                      final circle = _circles[index];
                      final isShaking = _shakingIndex == index;
                      final double shakeX = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

                      return Transform.translate(
                        offset: Offset(shakeX, 0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double radius = constraints.maxWidth / 2;

                            return GestureDetector(
                              onTapDown: (details) {
                                final localPos = details.localPosition;
                                // Shift position to be relative to the center of the circle
                                final double dx = localPos.dx - radius;
                                final double dy = localPos.dy - radius;

                                // Check if touch lies inside the circle radius
                                if (dx * dx + dy * dy <= radius * radius) {
                                  int quadrantIndex;
                                  if (dx <= 0 && dy <= 0) {
                                    quadrantIndex = 0; // Top-Left
                                  } else if (dx > 0 && dy <= 0) {
                                    quadrantIndex = 1; // Top-Right
                                  } else if (dx <= 0 && dy > 0) {
                                    quadrantIndex = 2; // Bottom-Left
                                  } else {
                                    quadrantIndex = 3; // Bottom-Right
                                  }

                                  _handleQuadrantTap(index, quadrantIndex);
                                }
                              },
                              child: CustomPaint(
                                painter: CircularQuadrantPainter(
                                  numbers: circle.numbers,
                                  quadrantCorrect: circle.quadrantCorrect,
                                  numberColors: _numberColors,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
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
              'Level 35',
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
          const Icon(Icons.palette_outlined, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Sentuh warna di bawah lalu warnai angka sesuai petunjuk!',
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendCell(1, colOrange),
          _buildLegendCell(2, colGreen),
          _buildLegendCell(3, colPink),
          _buildLegendCell(4, colBlue),
        ],
      ),
    );
  }

  Widget _buildLegendCell(int number, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPalette() {
    final List<Color> colors = [colOrange, colGreen, colPink, colBlue];

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
                    child: Center(
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

class CircularQuadrantPainter extends CustomPainter {
  final List<int> numbers;
  final List<bool> quadrantCorrect;
  final Map<int, Color> numberColors;

  CircularQuadrantPainter({
    required this.numbers,
    required this.quadrantCorrect,
    required this.numberColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Default quadrant background colors
    final Color defaultBgColor = const Color(0xFFF1F5F9);

    // Draw the 4 quadrants
    final fillPaint = Paint()..style = PaintingStyle.fill;

    // Top-Left: index 0 (start angle pi, sweep angle pi/2)
    fillPaint.color = quadrantCorrect[0] ? numberColors[numbers[0]]! : defaultBgColor;
    canvas.drawArc(rect, pi, pi / 2, true, fillPaint);

    // Top-Right: index 1 (start angle 3*pi/2, sweep angle pi/2)
    fillPaint.color = quadrantCorrect[1] ? numberColors[numbers[1]]! : defaultBgColor;
    canvas.drawArc(rect, 3 * pi / 2, pi / 2, true, fillPaint);

    // Bottom-Left: index 2 (start angle pi/2, sweep angle pi/2)
    fillPaint.color = quadrantCorrect[2] ? numberColors[numbers[2]]! : defaultBgColor;
    canvas.drawArc(rect, pi / 2, pi / 2, true, fillPaint);

    // Bottom-Right: index 3 (start angle 0, sweep angle pi/2)
    fillPaint.color = quadrantCorrect[3] ? numberColors[numbers[3]]! : defaultBgColor;
    canvas.drawArc(rect, 0, pi / 2, true, fillPaint);

    // Draw the dividing lines (plus/cross)
    final linePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Vertical line
    canvas.drawLine(Offset(radius, 0), Offset(radius, size.height), linePaint);
    // Horizontal line
    canvas.drawLine(Offset(0, radius), Offset(size.width, radius), linePaint);

    // Draw the main circle outer border
    final borderPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw the quadrant numbers in the center of each quadrant
    final double textDist = radius * 0.48; // perfect offset from center

    // Top-Left text position
    _drawText(
      canvas,
      '${numbers[0]}',
      Offset(radius - textDist, radius - textDist),
      size.width * 0.24,
      quadrantCorrect[0] ? Colors.white : const Color(0xFF334155),
    );

    // Top-Right text position
    _drawText(
      canvas,
      '${numbers[1]}',
      Offset(radius + textDist, radius - textDist),
      size.width * 0.24,
      quadrantCorrect[1] ? Colors.white : const Color(0xFF334155),
    );

    // Bottom-Left text position
    _drawText(
      canvas,
      '${numbers[2]}',
      Offset(radius - textDist, radius + textDist),
      size.width * 0.24,
      quadrantCorrect[2] ? Colors.white : const Color(0xFF334155),
    );

    // Bottom-Right text position
    _drawText(
      canvas,
      '${numbers[3]}',
      Offset(radius + textDist, radius + textDist),
      size.width * 0.24,
      quadrantCorrect[3] ? Colors.white : const Color(0xFF334155),
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, double fontSize, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.fredoka(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offset = Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CircularQuadrantPainter oldDelegate) {
    return oldDelegate.numbers != numbers ||
        oldDelegate.quadrantCorrect != quadrantCorrect ||
        oldDelegate.numberColors != numberColors;
  }
}
