import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _InfiniteDragMatchingScreenState extends ConsumerState<InfiniteDragMatchingScreen> with TickerProviderStateMixin {
  late List<_CellData> _cells;
  late Map<int, AnimationController> _pulseControllers;

  // Warna pembingkai presisi sesuai buku cetak asli:
  // Segitiga = Hijau
  // Lingkaran = Hitam
  // Segi Empat = Hitam
  static const Color colTriangle = Color(0xFF4CAF50); // Hijau
  static const Color colCircle = Colors.black87;      // Hitam
  static const Color colSquare = Colors.black87;      // Hitam

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 16 Angka presisi dari buku referensi
    final initialNumbers = [
      3, 1, 2, 3,
      1, 2, 3, 1,
      2, 3, 1, 2,
      3, 1, 2, 2,
    ];

    _cells = initialNumbers.map((num) => _CellData(number: num)).toList();

    _pulseControllers = {};
    for (int i = 0; i < _cells.length; i++) {
      _pulseControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _pulseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleDrop(ShapeType draggedShape, int index) {
    final cell = _cells[index];
    if (cell.isMatched) return;

    if (draggedShape == cell.requiredShape) {
      HapticService.success();
      // Play pop sound
      
      setState(() {
        cell.isMatched = true;
      });

      _pulseControllers[index]!.forward().then((_) {
        _pulseControllers[index]!.reverse();
      });

      // Cek kemenangan total
      if (_cells.every((c) => c.isMatched)) {
        _onLevelComplete();
      }
    } else {
      HapticService.failure();
    }
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 19,
      title: 'Hebat! Kamu Pintar Mengelompokkan!',
      message: 'Kamu berhasil membingkai semua angka dengan geometri yang benar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Konten Utama Scrollable
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildInstruction(),
                  
                  // Atas: Legenda Petunjuk Statis
                  _buildLegendCard(),
                  
                  // Tengah: Papan Utama (Grid 4x4)
                  Padding(
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
                      itemCount: _cells.length,
                      itemBuilder: (context, index) {
                        return _buildGridCell(index);
                      },
                    ),
                  ),
                  
                  // Jarak ekstra agar baris angka paling bawah tidak tertutup dock yang melayang
                  const SizedBox(height: 120),
                ],
              ),
            ),
            
            // Footer: Dock Geometri melayang di paling bawah
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildGeometryDock(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Perhatikan contoh, lalu bingkai setiap angka!',
              style: GoogleFonts.fredoka(
                fontSize: 16,
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
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(ShapeType.triangle, colTriangle, '1'),
              _buildLegendItem(ShapeType.circle, colCircle, '2'),
              _buildLegendItem(ShapeType.square, colSquare, '3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ShapeType type, Color color, String num) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 45,
              height: 45,
              child: CustomPaint(
                painter: _GeometryFramePainter(type: type, color: color, isFilled: false),
              ),
            ),
            Text(
              num,
              style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildGridCell(int index) {
    final cell = _cells[index];

    return DragTarget<ShapeType>(
      onWillAcceptWithDetails: (details) => !cell.isMatched,
      onAcceptWithDetails: (details) => _handleDrop(details.data, index),
      builder: (context, candidateData, rejectedData) {
        return ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.25).animate(
            CurvedAnimation(
              parent: _pulseControllers[index]!,
              curve: Curves.elasticOut,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: cell.isMatched ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              boxShadow: cell.isMatched
                  ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                  : null,
              border: Border.all(
                color: candidateData.isNotEmpty ? Colors.blue.shade300 : Colors.transparent,
                width: 2.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Layer Bawah: Bentuk Pembingkai (jika sukses)
                if (cell.isMatched)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomPaint(
                        painter: _GeometryFramePainter(
                          type: cell.requiredShape,
                          color: cell.requiredShape == ShapeType.triangle
                              ? colTriangle
                              : (cell.requiredShape == ShapeType.circle ? colCircle : colSquare),
                          isFilled: false,
                        ),
                      ),
                    ),
                  ),
                
                // Layer Atas: Angka Utama
                Text(
                  cell.number.toString(),
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cell.isMatched
                        ? Colors.blueGrey.shade800
                        : Colors.blueGrey.shade300,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeometryDock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfiniteDraggable(ShapeType.triangle, colTriangle),
          _buildInfiniteDraggable(ShapeType.circle, colCircle),
          _buildInfiniteDraggable(ShapeType.square, colSquare),
        ],
      ),
    );
  }

  Widget _buildInfiniteDraggable(ShapeType type, Color color) {
    return Draggable<ShapeType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2, // Bayangan bentuk saat digeser berukuran skala 1.2
          child: _buildDockItemContainer(type, color, isShadow: true),
        ),
      ),
      childWhenDragging: _buildDockItemContainer(type, color), // child aslinya tetap diam di footer
      child: _buildDockItemContainer(type, color),
    );
  }

  Widget _buildDockItemContainer(ShapeType type, Color color, {bool isShadow = false}) {
    return Container(
      width: 80, // Geometri murni yang besar dan jelas
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isShadow ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: isShadow ? 12 : 5,
            offset: Offset(0, isShadow ? 6 : 2),
          )
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: CustomPaint(
            painter: _GeometryFramePainter(type: type, color: color, isFilled: false),
            size: const Size(double.infinity, double.infinity),
          ),
        ),
      ),
    );
  }
}

// Custom Painter premium untuk membingkai geometri (Hollow Outline)
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
