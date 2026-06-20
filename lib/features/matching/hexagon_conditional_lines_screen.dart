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

class HexagonConditionalLinesScreen extends ConsumerStatefulWidget {
  final int levelId;
  const HexagonConditionalLinesScreen({super.key, this.levelId = 29});

  @override
  ConsumerState<HexagonConditionalLinesScreen> createState() => _HexagonConditionalLinesScreenState();
}

enum HexColor { blue, yellow, green, red }

class HexagonItem {
  final int id;
  final HexColor colorType;
  bool isCorrect;
  String? drawnLine; // '—', '|', '\\', '/'

  HexagonItem({
    required this.id,
    required this.colorType,
    this.isCorrect = false,
    this.drawnLine,
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
}

class _HexagonConditionalLinesScreenState extends ConsumerState<HexagonConditionalLinesScreen> {
  late List<HexagonItem> _hexagons;

  @visibleForTesting
  List<HexagonItem> get hexagons => _hexagons;

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

  void _resetLevel() {
    setState(() {
      _initLevel();
    });
  }

  void _handleLineDrop(int id, String lineType) {
    final item = _hexagons.firstWhere((h) => h.id == id);
    if (item.isCorrect) return;

    // Check validation:
    // Segienam Biru (Blue) -> Hanya menerima Garis Horizontal (—)
    // Segienam Kuning (Yellow) -> Hanya menerima Garis Vertikal (|)
    // Segienam Hijau (Green) -> Hanya menerima Garis Miring Kiri (\)
    // Segienam Merah (Red) -> Hanya menerima Garis Miring Kanan (/)
    bool isCorrect = false;
    switch (item.colorType) {
      case HexColor.blue:
        isCorrect = (lineType == '—');
        break;
      case HexColor.yellow:
        isCorrect = (lineType == '|');
        break;
      case HexColor.green:
        isCorrect = (lineType == '\\');
        break;
      case HexColor.red:
        isCorrect = (lineType == '/');
        break;
    }

    if (isCorrect) {
      SoundService.playSuccess();
      HapticService.success();
      setState(() {
        item.isCorrect = true;
        item.drawnLine = lineType;

        if (_hexagons.every((h) => h.isCorrect)) {
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
      title: 'Kamu Luar Biasa!',
      message: 'Semua garis kondisi logika berhasil dicocokkan dengan sempurna!',
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
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _hexagons.length,
                  itemBuilder: (context, index) {
                    final item = _hexagons[index];

                    return DragTarget<String>(
                      key: ValueKey('hexagon_target_$index'),
                      onWillAcceptWithDetails: (details) {
                        return !item.isCorrect;
                      },
                      onAcceptWithDetails: (details) {
                        _handleLineDrop(item.id, details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final bool isHovered = candidateData.isNotEmpty;

                        return CustomPaint(
                          painter: HexagonCellPainter(
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
            _buildLineBin(),
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
              'Seret garis ke segienam dengan warna yang cocok!',
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
          _buildLegendCell(HexColor.blue, '—', '—'),
          _buildLegendCell(HexColor.yellow, '|', '|'),
          _buildLegendCell(HexColor.green, '\\', '\\'),
          _buildLegendCell(HexColor.red, '/', '/'),
        ],
      ),
    );
  }

  Widget _buildLegendCell(HexColor colorType, String lineType, String label) {
    final dummyItem = HexagonItem(id: -1, colorType: colorType, isCorrect: true, drawnLine: lineType);

    return Column(
      children: [
        SizedBox(
          width: 50,
          height: 46,
          child: CustomPaint(
            painter: HexagonCellPainter(
              item: dummyItem,
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

  Widget _buildLineBin() {
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
            'PALET GARIS',
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
              _buildDraggableLine('—', 'Horizontal'),
              _buildDraggableLine('|', 'Vertikal'),
              _buildDraggableLine('\\', 'Miring Kiri'),
              _buildDraggableLine('/', 'Miring Kanan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableLine(String type, String label) {
    return Draggable<String>(
      key: ValueKey('draggable_line_$type'),
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: CustomPaint(painter: LineBinItemPainter(type)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildLinePiece(type, label),
      ),
      child: _buildLinePiece(type, label),
    );
  }

  Widget _buildLinePiece(String type, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: CustomPaint(painter: LineBinItemPainter(type)),
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

class HexagonCellPainter extends CustomPainter {
  final HexagonItem item;
  final bool isHovered;

  HexagonCellPainter({
    required this.item,
    this.isHovered = false,
  });

  Path _getHexagonPath(Size size) {
    final path = Path();
    double w = size.width;
    double h = size.height;
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
      ..color = item.color.withOpacity(isHovered ? 0.95 : 0.85)
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
      ..color = isHovered ? Colors.amberAccent : Colors.white.withOpacity(0.9)
      ..strokeWidth = isHovered ? 3.5 : 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // 4. Draw Correct Line (if completed)
    if (item.isCorrect && item.drawnLine != null) {
      final linePaint = Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      double w = size.width;
      double h = size.height;

      switch (item.drawnLine) {
        case '—':
          canvas.drawLine(Offset(w * -0.05, h * 0.5), Offset(w * 1.05, h * 0.5), linePaint);
          break;
        case '|':
          canvas.drawLine(Offset(w * 0.5, h * -0.05), Offset(w * 0.5, h * 1.05), linePaint);
          break;
        case '\\':
          canvas.drawLine(Offset(w * 0.12, h * 0.12), Offset(w * 0.88, h * 0.88), linePaint);
          break;
        case '/':
          canvas.drawLine(Offset(w * 0.12, h * 0.88), Offset(w * 0.88, h * 0.12), linePaint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant HexagonCellPainter oldDelegate) {
    return oldDelegate.item.isCorrect != item.isCorrect ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.item.drawnLine != item.drawnLine;
  }
}

class LineBinItemPainter extends CustomPainter {
  final String lineType;
  LineBinItemPainter(this.lineType);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    double w = size.width;
    double h = size.height;

    switch (lineType) {
      case '—':
        canvas.drawLine(Offset(w * 0.15, h * 0.5), Offset(w * 0.85, h * 0.5), paint);
        break;
      case '|':
        canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.85), paint);
        break;
      case '\\':
        canvas.drawLine(Offset(w * 0.2, h * 0.2), Offset(w * 0.8, h * 0.8), paint);
        break;
      case '/':
        canvas.drawLine(Offset(w * 0.2, h * 0.8), Offset(w * 0.8, h * 0.2), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
