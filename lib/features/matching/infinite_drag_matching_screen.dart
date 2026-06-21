import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class InfiniteDragMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const InfiniteDragMatchingScreen({super.key, this.levelId = 18});

  @override
  ConsumerState<InfiniteDragMatchingScreen> createState() => _InfiniteDragMatchingScreenState();
}

enum ShapeType { triangle, circle, square }

class _CellData {
  final int number;
  final ShapeType requiredShape;
  bool isMatched;

  _CellData({required this.number})
      : requiredShape = number == 1
            ? ShapeType.triangle
            : (number == 2 ? ShapeType.circle : ShapeType.square),
        isMatched = false;
}

class _InfiniteDragMatchingScreenState extends ConsumerState<InfiniteDragMatchingScreen> {
  late List<_CellData> cells;
  ShapeType? selectedShape;

  static const Color colTriangle = Color(0xFF4CAF50); // Hijau
  static const Color colCircle = Colors.black87;      // Hitam
  static const Color colSquare = Colors.black87;      // Hitam

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    setState(() {
      selectedShape = null;
      final initialNumbers = [
        3, 1, 2, 3,
        1, 2, 3, 1,
        2, 3, 1, 2,
        3, 1, 2, 2,
      ];
      cells = initialNumbers.map((num) => _CellData(number: num)).toList();
    });
  }

  bool _handleShapeTap(int index, ShapeType? shape) {
    if (shape == null) return false;
    final cell = cells[index];

    if (cell.requiredShape == shape) {
      setState(() {
        cell.isMatched = true;
      });
      SoundService.playSuccess();
      HapticService.success();

      // Cek kemenangan
      if (cells.every((c) => c.isMatched)) {
        gameWin();
      }
      return true;
    } else {
      SoundService.playError();
      HapticFeedback.lightImpact();
      return false;
    }
  }

  void gameWin() {
    _onLevelComplete();
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    UserService.updateProgress(widget.levelId).catchError((e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    });
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 19,
      title: 'Hebat! Kamu Pintar Mengelompokkan!',
      message: 'Kamu berhasil membingkai semua angka dengan geometri yang benar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildInstruction(),
              
              // Legenda Petunjuk Atas (Bersih tanpa teks/angka di dalam geometri)
              _buildLegendCard(),
              
              // Area Grid 4x4
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: cells.length,
                        itemBuilder: (context, index) {
                          return _GridCellWidget(
                            index: index,
                            cell: cells[index],
                            selectedShape: selectedShape,
                            onShapeSubmitted: _handleShapeTap,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom Palette Area
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row of Shape Pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShapePickerItem(ShapeType.triangle, colTriangle),
              _buildShapePickerItem(ShapeType.circle, colCircle),
              _buildShapePickerItem(ShapeType.square, colSquare),
            ],
          ),
          const SizedBox(height: 16),
          // Symmetric Reset Button
          TextButton.icon(
            onPressed: _resetLevel,
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueGrey, size: 20),
            label: const Text(
              'Ulangi',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapePickerItem(ShapeType type, Color color) {
    final isSelected = selectedShape == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedShape = type;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedScale(
        scale: isSelected ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: isSelected 
                ? Border.all(color: Colors.black87, width: 3.5)
                : Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: CustomPaint(
            painter: _GeometryFramePainter(type: type, color: color, isFilled: false),
          ),
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
              'Level 18',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_rounded, color: Colors.indigo, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Pilih bingkai di bawah, lalu ketuk angka yang sesuai!',
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

  Widget _buildLegendCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Text(
            'Contoh Bingkai Angka',
            style: GoogleFonts.fredoka(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(ShapeType.triangle, colTriangle),
              _buildLegendItem(ShapeType.circle, colCircle),
              _buildLegendItem(ShapeType.square, colSquare),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ShapeType type, Color color) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _GeometryFramePainter(type: type, color: color, isFilled: false),
      ),
    );
  }
}

class _GridCellWidget extends StatefulWidget {
  final int index;
  final _CellData cell;
  final ShapeType? selectedShape;
  final bool Function(int, ShapeType?) onShapeSubmitted;

  const _GridCellWidget({
    required this.index,
    required this.cell,
    required this.selectedShape,
    required this.onShapeSubmitted,
  });

  @override
  State<_GridCellWidget> createState() => _GridCellWidgetState();
}

class _GridCellWidgetState extends State<_GridCellWidget> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cell = widget.cell;
    final isMatched = cell.isMatched;

    return GestureDetector(
      onTap: () {
        if (isMatched) return;
        bool correct = widget.onShapeSubmitted(widget.index, widget.selectedShape);
        if (!correct) {
          _shakeController.forward(from: 0);
        }
      },
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final double offset = math.sin(_shakeController.value * math.pi * 4) * 8 * (1 - _shakeController.value);
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isMatched ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isMatched
                ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
            border: Border.all(
              color: isMatched ? Colors.green.shade200 : Colors.grey.shade200,
              width: isMatched ? 1.5 : 1.0,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isMatched)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomPaint(
                      painter: _GeometryFramePainter(
                        type: cell.requiredShape,
                        color: cell.requiredShape == ShapeType.triangle
                            ? const Color(0xFF4CAF50)
                            : Colors.black87,
                        isFilled: false,
                      ),
                    ),
                  ),
                ),
              
              Text(
                cell.number.toString(),
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isMatched
                      ? Colors.blueGrey.shade800
                      : Colors.blueGrey.shade300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeometryFramePainter extends CustomPainter {
  final ShapeType type;
  final Color color;
  final bool isFilled;

  _GeometryFramePainter({required this.type, required this.color, this.isFilled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();

    switch (type) {
      case ShapeType.triangle:
        path.moveTo(size.width / 2, 4);
        path.lineTo(size.width - 4, size.height - 4);
        path.lineTo(4, size.height - 4);
        path.close();
        break;
      case ShapeType.circle:
        canvas.drawCircle(center, size.width / 2 - 4, paint);
        return;
      case ShapeType.square:
        final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
        return;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
