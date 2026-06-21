import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class CircleItem {
  final int id;
  final CircleColor colorType;
  bool isCorrect;
  String? placedPattern; // 'x', '+', '||', '='

  CircleItem({
    required this.id,
    required this.colorType,
    this.isCorrect = false,
    this.placedPattern,
  });

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
}

class _CircleConditionalPatternsScreenState extends ConsumerState<CircleConditionalPatternsScreen> {
  late List<CircleItem> _circles;

  @visibleForTesting
  List<CircleItem> get circles => _circles;

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

  void _resetLevel() {
    setState(() {
      _initLevel();
    });
  }

  void _handlePatternDrop(int id, String patternType) {
    final item = _circles.firstWhere((c) => c.id == id);
    if (item.isCorrect) return;

    // Check validation:
    // Yellow circle -> Hanya menerima 'x'
    // Green circle -> Hanya menerima '+'
    // Blue circle -> Hanya menerima '||'
    // Orange circle -> Hanya menerima '='
    bool isCorrect = false;
    switch (item.colorType) {
      case CircleColor.yellow:
        isCorrect = (patternType == 'x');
        break;
      case CircleColor.green:
        isCorrect = (patternType == '+');
        break;
      case CircleColor.blue:
        isCorrect = (patternType == '||');
        break;
      case CircleColor.orange:
        isCorrect = (patternType == '=');
        break;
    }

    if (isCorrect) {
      SoundService.playSuccess();
      HapticService.success();
      setState(() {
        item.isCorrect = true;
        item.placedPattern = patternType;

        if (_circles.every((c) => c.isCorrect)) {
          gameWin();
        }
      });
    } else {
      HapticFeedback.lightImpact();
      SoundService.playError();
    }
  }

  void gameWin() {
    _onLevelComplete();
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
      title: 'Hore, Kamu Juara!',
      message: 'Kamu berhasil memasangkan semua pola bentuk ke kotak warna yang sesuai!',
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
            _buildRulesLegend(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 12, thickness: 1),
            ),
            // Play Area Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _circles.length,
                  itemBuilder: (context, index) {
                    final item = _circles[index];

                    return DragTarget<String>(
                      key: ValueKey('circle_target_$index'),
                      onWillAcceptWithDetails: (details) {
                        return !item.isCorrect;
                      },
                      onAcceptWithDetails: (details) {
                        _handlePatternDrop(item.id, details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final bool isHovered = candidateData.isNotEmpty;

                        return CustomPaint(
                          painter: CircleCellPainter(
                            item: item,
                            isHovered: isHovered,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPartsBin(),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _resetLevel,
                icon: const Icon(Icons.refresh_rounded, color: Colors.orange, size: 22),
                label: const Text(
                  'Ulangi',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
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
          const Icon(Icons.rule_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Seret pola dari palet bawah ke kotak warna yang cocok!',
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
          _buildLegendCell(CircleColor.yellow, 'x', 'x'),
          _buildLegendCell(CircleColor.green, '+', '+'),
          _buildLegendCell(CircleColor.blue, '||', '||'),
          _buildLegendCell(CircleColor.orange, '=', '='),
        ],
      ),
    );
  }

  Widget _buildLegendCell(CircleColor colorType, String pattern, String label) {
    final dummyItem = CircleItem(id: -1, colorType: colorType, isCorrect: true, placedPattern: pattern);

    return SizedBox(
      width: 46,
      height: 46,
      child: CustomPaint(
        painter: CircleCellPainter(
          item: dummyItem,
        ),
      ),
    );
  }

  Widget _buildPartsBin() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'PALET PILIHAN',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDraggablePattern('x', 'Silang'),
              _buildDraggablePattern('+', 'Plus'),
              _buildDraggablePattern('||', 'Dua Vertikal'),
              _buildDraggablePattern('=', 'Dua Horizontal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePattern(String type, String label) {
    return Draggable<String>(
      key: ValueKey('draggable_pattern_$type'),
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: CustomPaint(painter: PartsBinItemPainter(type)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildPatternPiece(type, label),
      ),
      child: _buildPatternPiece(type, label),
    );
  }

  Widget _buildPatternPiece(String type, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: CustomPaint(painter: PartsBinItemPainter(type)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 10,
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
  final bool isHovered;

  CircleCellPainter({
    required this.item,
    this.isHovered = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final double w = size.width;
    final double h = size.height;

    // 1. Draw Subtle Shadow
    final path = Path()..addOval(Rect.fromLTWH(0, 0, w, h));
    canvas.drawShadow(
      path,
      Colors.black.withOpacity(0.22),
      isHovered ? 4.0 : 2.5,
      true,
    );

    // 2. Draw Circle Fill Background with Soft Gradient
    final baseColor = item.color;
    final colorLight = Color.alphaBlend(Colors.white.withOpacity(0.18), baseColor);
    final colorDark = Color.alphaBlend(Colors.black.withOpacity(0.08), baseColor);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorLight,
          colorDark,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    // 3. Draw Sphere-Style Glossy White Highlight on top-left
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.35, h * 0.18),
      highlightPaint,
    );

    // 4. Draw Circle White Border
    final strokePaint = Paint()
      ..color = isHovered ? Colors.amberAccent : Colors.white.withOpacity(0.8)
      ..strokeWidth = isHovered ? 3.5 : 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, strokePaint);

    // 5. Draw Placed Pattern
    if (item.isCorrect && item.placedPattern != null) {
      final linePaint = Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      switch (item.placedPattern) {
        case 'x':
          canvas.drawLine(Offset(w * 0.2, h * 0.2), Offset(w * 0.8, h * 0.8), linePaint);
          canvas.drawLine(Offset(w * 0.2, h * 0.8), Offset(w * 0.8, h * 0.2), linePaint);
          break;
        case '+':
          canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.85), linePaint);
          canvas.drawLine(Offset(w * 0.15, h * 0.5), Offset(w * 0.85, h * 0.5), linePaint);
          break;
        case '||':
          canvas.drawLine(Offset(w * 0.35, h * 0.15), Offset(w * 0.35, h * 0.85), linePaint);
          canvas.drawLine(Offset(w * 0.65, h * 0.15), Offset(w * 0.65, h * 0.85), linePaint);
          break;
        case '=':
          canvas.drawLine(Offset(w * 0.15, h * 0.35), Offset(w * 0.85, h * 0.35), linePaint);
          canvas.drawLine(Offset(w * 0.15, h * 0.65), Offset(w * 0.85, h * 0.65), linePaint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CircleCellPainter oldDelegate) {
    return oldDelegate.item.isCorrect != item.isCorrect ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.item.placedPattern != item.placedPattern;
  }
}

class PartsBinItemPainter extends CustomPainter {
  final String patternType;
  PartsBinItemPainter(this.patternType);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    double w = size.width;
    double h = size.height;

    switch (patternType) {
      case 'x':
        canvas.drawLine(Offset(w * 0.22, h * 0.22), Offset(w * 0.78, h * 0.78), paint);
        canvas.drawLine(Offset(w * 0.22, h * 0.78), Offset(w * 0.78, h * 0.22), paint);
        break;
      case '+':
        canvas.drawLine(Offset(w * 0.5, h * 0.18), Offset(w * 0.5, h * 0.82), paint);
        canvas.drawLine(Offset(w * 0.18, h * 0.5), Offset(w * 0.82, h * 0.5), paint);
        break;
      case '||':
        canvas.drawLine(Offset(w * 0.36, h * 0.18), Offset(w * 0.36, h * 0.82), paint);
        canvas.drawLine(Offset(w * 0.64, h * 0.18), Offset(w * 0.64, h * 0.82), paint);
        break;
      case '=':
        canvas.drawLine(Offset(w * 0.18, h * 0.36), Offset(w * 0.82, h * 0.36), paint);
        canvas.drawLine(Offset(w * 0.18, h * 0.64), Offset(w * 0.82, h * 0.64), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
