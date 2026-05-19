import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SequenceCompletionScreen extends ConsumerStatefulWidget {
  final int levelId;
  const SequenceCompletionScreen({super.key, this.levelId = 17});

  @override
  ConsumerState<SequenceCompletionScreen> createState() => _SequenceCompletionScreenState();
}

enum ShapeType { triangle, circle, square }

enum CandyType {
  purple,        // Target: Segitiga
  red,           // Target: Lingkaran
  green,         // Target: Kotak/Segi Empat
  cupcake,       // Pengecoh
  iceCreamCone,  // Pengecoh
  iceCreamStick, // Pengecoh
  lollipop,      // Pengecoh
  cakeSlice,     // Pengecoh
  pinkCake,      // Pengecoh
  chocolateCake, // Pengecoh
  rollCake,      // Pengecoh
  domeCookie     // Pengecoh
}

class _GridCell {
  final CandyType type;
  final ShapeType? requiredShape;
  bool isMatched;

  _GridCell({required this.type})
      : requiredShape = type == CandyType.purple
            ? ShapeType.triangle
            : (type == CandyType.red
                ? ShapeType.circle
                : (type == CandyType.green ? ShapeType.square : null)),
        isMatched = false;
}

class _SequenceCompletionScreenState extends ConsumerState<SequenceCompletionScreen> with TickerProviderStateMixin {
  late List<_GridCell> _cells;
  late Map<int, AnimationController> _pulseControllers;

  // Warna garis pembingkai geometri:
  // Segitiga = Hijau/Ungu sesuai legenda permen
  static const Color colTriangle = Color(0xFF4CAF50); // Hijau
  static const Color colCircle = Color(0xFF2196F3);   // Biru
  static const Color colSquare = Color(0xFFF44336);   // Merah

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 5x5 Grid dari gambar buku cetak asli:
    final layout = [
      // Row 1
      CandyType.green, CandyType.cupcake, CandyType.red, CandyType.iceCreamCone, CandyType.purple,
      // Row 2
      CandyType.cakeSlice, CandyType.green, CandyType.purple, CandyType.lollipop, CandyType.red,
      // Row 3
      CandyType.red, CandyType.iceCreamStick, CandyType.green, CandyType.purple, CandyType.chocolateCake,
      // Row 4
      CandyType.green, CandyType.pinkCake, CandyType.red, CandyType.domeCookie, CandyType.purple,
      // Row 5
      CandyType.iceCreamCone, CandyType.purple, CandyType.rollCake, CandyType.red, CandyType.green,
    ];

    _cells = layout.map((type) => _GridCell(type: type)).toList();

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

    if (cell.requiredShape == draggedShape) {
      HapticService.success();
      setState(() {
        cell.isMatched = true;
      });

      _pulseControllers[index]!.forward().then((_) {
        _pulseControllers[index]!.reverse();
      });

      // Cek kemenangan
      final targets = _cells.where((c) => c.requiredShape != null);
      if (targets.every((c) => c.isMatched)) {
        _onLevelComplete();
      }
    } else {
      HapticService.failure();
      // Mental balik diurus otomatis oleh Draggable
    }
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 18,
      title: 'Hore! Kamu Pintar!',
      message: 'Kamu berhasil mengelompokkan semua permen dengan bingkai yang benar!',
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
            
            // Legenda Petunjuk Atas
            _buildLegendCard(),
            
            // Area Bermain: Grid 5x5
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _cells.length,
                  itemBuilder: (context, index) {
                    return _buildGridCell(index);
                  },
                ),
              ),
            ),
            
            // Dermaga Geometri Bawah (Infinite)
            _buildGeometryDock(),
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
              'Level 17',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Tarik bingkai dari bawah untuk membungkus permen yang tepat!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade800,
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
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(ShapeType.triangle, colTriangle, CandyType.purple),
          _buildLegendItem(ShapeType.circle, colCircle, CandyType.red),
          _buildLegendItem(ShapeType.square, colSquare, CandyType.green),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ShapeType shape, Color color, CandyType candy) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(
            painter: _GeometryFramePainter(type: shape, color: color),
          ),
        ),
        SizedBox(
          width: 32,
          height: 32,
          child: CustomPaint(
            painter: _CandyPainter(type: candy),
          ),
        ),
      ],
    );
  }

  Widget _buildGridCell(int index) {
    final cell = _cells[index];

    return DragTarget<ShapeType>(
      onWillAcceptWithDetails: (details) => cell.requiredShape != null && !cell.isMatched,
      onAcceptWithDetails: (details) => _handleDrop(details.data, index),
      builder: (context, candidateData, rejectedData) {
        return ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.2).animate(
            CurvedAnimation(
              parent: _pulseControllers[index]!,
              curve: Curves.elasticOut,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.teal.shade300
                    : (cell.isMatched ? Colors.green.shade100 : Colors.grey.shade100),
                width: cell.isMatched ? 1.0 : (candidateData.isNotEmpty ? 2.0 : 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Layer Bawah: Bingkai Geometri jika sudah benar
                if (cell.isMatched)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: CustomPaint(
                        painter: _GeometryFramePainter(
                          type: cell.requiredShape!,
                          color: cell.requiredShape == ShapeType.triangle
                              ? colTriangle
                              : (cell.requiredShape == ShapeType.circle ? colCircle : colSquare),
                        ),
                      ),
                    ),
                  )
                else if (cell.requiredShape != null)
                  // Kotak pembantu putus-putus tipis untuk permen target yang belum dicocokkan (seperti di buku)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: CustomPaint(
                        painter: _DottedBorderPainter(color: Colors.grey.shade300),
                      ),
                    ),
                  ),

                // Layer Atas: Permen/Pengecoh utama
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomPaint(
                    painter: _CandyPainter(type: cell.type),
                    size: const Size(double.infinity, double.infinity),
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
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stok Bingkai Tak Terbatas',
            style: GoogleFonts.fredoka(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfiniteDraggable(ShapeType.triangle, colTriangle),
              _buildInfiniteDraggable(ShapeType.circle, colCircle),
              _buildInfiniteDraggable(ShapeType.square, colSquare),
            ],
          ),
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
          scale: 1.2,
          child: _buildDockItemContainer(type, color, isShadow: true),
        ),
      ),
      childWhenDragging: _buildDockItemContainer(type, color),
      child: _buildDockItemContainer(type, color),
    );
  }

  Widget _buildDockItemContainer(ShapeType type, Color color, {bool isShadow = false}) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isShadow ? Colors.black26 : Colors.black.withOpacity(0.03),
            blurRadius: isShadow ? 10 : 4,
            offset: Offset(0, isShadow ? 5 : 2),
          )
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomPaint(
            painter: _GeometryFramePainter(type: type, color: color),
            size: const Size(double.infinity, double.infinity),
          ),
        ),
      ),
    );
  }
}

// Custom Painter untuk membingkai geometri (Segitiga, Lingkaran, Kotak)
class _GeometryFramePainter extends CustomPainter {
  final ShapeType type;
  final Color color;

  _GeometryFramePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();

    switch (type) {
      case ShapeType.triangle:
        path.moveTo(size.width / 2, 2);
        path.lineTo(size.width - 2, size.height - 2);
        path.lineTo(2, size.height - 2);
        path.close();
        break;
      case ShapeType.circle:
        canvas.drawCircle(center, size.width / 2 - 2, paint);
        return;
      case ShapeType.square:
        final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
        return;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter untuk Menggambar Permen dan Pengecoh Kustom
class _CandyPainter extends CustomPainter {
  final CandyType type;

  _CandyPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    
    switch (type) {
      case CandyType.purple:
        // Permen Ungu (Segitiga)
        final bodyPaint = Paint()..color = Colors.purple..style = PaintingStyle.fill;
        final wingPaint = Paint()..color = Colors.purple.shade700..style = PaintingStyle.fill;
        
        // Wings (Atas & Bawah)
        final topWing = Path()
          ..moveTo(w / 2, h * 0.25)
          ..lineTo(w * 0.3, h * 0.05)
          ..lineTo(w * 0.7, h * 0.05)
          ..close();
        final bottomWing = Path()
          ..moveTo(w / 2, h * 0.75)
          ..lineTo(w * 0.3, h * 0.95)
          ..lineTo(w * 0.7, h * 0.95)
          ..close();
        canvas.drawPath(topWing, wingPaint);
        canvas.drawPath(bottomWing, wingPaint);

        // Body (Capsule)
        final rect = Rect.fromLTRB(w * 0.35, h * 0.2, w * 0.65, h * 0.8);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.15)), bodyPaint);
        
        // Detail garis putih vertikal
        final linePaint = Paint()..color = Colors.white24..strokeWidth = 2;
        canvas.drawLine(Offset(w * 0.45, h * 0.3), Offset(w * 0.45, h * 0.7), linePaint);
        canvas.drawLine(Offset(w * 0.55, h * 0.3), Offset(w * 0.55, h * 0.7), linePaint);
        break;

      case CandyType.red:
        // Permen Merah Polkadot (Lingkaran)
        final bodyPaint = Paint()..color = const Color(0xFFE53935)..style = PaintingStyle.fill;
        final wingPaint = Paint()..color = const Color(0xFFC62828)..style = PaintingStyle.fill;

        // Wings (Kiri & Kanan agak serong)
        final leftWing = Path()
          ..moveTo(w * 0.35, h / 2)
          ..lineTo(w * 0.08, h * 0.3)
          ..lineTo(w * 0.08, h * 0.7)
          ..close();
        final rightWing = Path()
          ..moveTo(w * 0.65, h / 2)
          ..lineTo(w * 0.92, h * 0.3)
          ..lineTo(w * 0.92, h * 0.7)
          ..close();
        canvas.drawPath(leftWing, wingPaint);
        canvas.drawPath(rightWing, wingPaint);

        // Body (Circle)
        canvas.drawCircle(center, w * 0.26, bodyPaint);

        // Polkadot putih
        final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.42, h * 0.42), w * 0.05, dotPaint);
        canvas.drawCircle(Offset(w * 0.58, h * 0.45), w * 0.04, dotPaint);
        canvas.drawCircle(Offset(w * 0.48, h * 0.58), w * 0.05, dotPaint);
        break;

      case CandyType.green:
        // Permen Hijau Striped / Pita (Square)
        final bodyPaint = Paint()..color = const Color(0xFF8BC34A)..style = PaintingStyle.fill;
        final wingPaint = Paint()..color = const Color(0xFFFFEB3B)..style = PaintingStyle.fill; // Bows Kuning

        // Yellow Bows (Kiri & Kanan)
        final leftBow = Path()
          ..moveTo(w * 0.3, h / 2)
          ..lineTo(w * 0.1, h * 0.25)
          ..lineTo(w * 0.1, h * 0.75)
          ..close();
        final rightBow = Path()
          ..moveTo(w * 0.7, h / 2)
          ..lineTo(w * 0.9, h * 0.25)
          ..lineTo(w * 0.9, h * 0.75)
          ..close();
        canvas.drawPath(leftBow, wingPaint);
        canvas.drawPath(rightBow, wingPaint);

        // Body (Oval Hijau)
        final bodyRect = Rect.fromLTRB(w * 0.25, h * 0.3, w * 0.75, h * 0.7);
        canvas.drawOval(bodyRect, bodyPaint);

        // Yellow stripes
        final stripePaint = Paint()
          ..color = const Color(0xFFFFEB3B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawLine(Offset(w * 0.4, h * 0.32), Offset(w * 0.4, h * 0.68), stripePaint);
        canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.7), stripePaint);
        canvas.drawLine(Offset(w * 0.6, h * 0.32), Offset(w * 0.6, h * 0.68), stripePaint);
        break;

      case CandyType.cupcake:
        // Cupcake
        final cupPaint = Paint()..color = const Color(0xFF8D6E63)..style = PaintingStyle.fill; // Liner cokelat
        final creamPaint = Paint()..color = const Color(0xFFF8BBD0)..style = PaintingStyle.fill; // Frosting pink
        
        // Liner
        final cupPath = Path()
          ..moveTo(w * 0.3, h * 0.5)
          ..lineTo(w * 0.7, h * 0.5)
          ..lineTo(w * 0.65, h * 0.85)
          ..lineTo(w * 0.35, h * 0.85)
          ..close();
        canvas.drawPath(cupPath, cupPaint);

        // Frosting
        canvas.drawCircle(Offset(w * 0.4, h * 0.42), w * 0.16, creamPaint);
        canvas.drawCircle(Offset(w * 0.6, h * 0.42), w * 0.16, creamPaint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.34), w * 0.16, creamPaint);

        // Cherry merah
        final cherryPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.5, h * 0.22), w * 0.06, cherryPaint);
        break;

      case CandyType.iceCreamCone:
        // Es Krim Cone Pink
        final conePaint = Paint()..color = const Color(0xFFFFCC80)..style = PaintingStyle.fill;
        final creamPaint = Paint()..color = const Color(0xFFF48FB1)..style = PaintingStyle.fill;

        // Cone
        final conePath = Path()
          ..moveTo(w * 0.32, h * 0.45)
          ..lineTo(w * 0.68, h * 0.45)
          ..lineTo(w * 0.5, h * 0.9)
          ..close();
        canvas.drawPath(conePath, conePaint);

        // Scoop
        canvas.drawCircle(Offset(w * 0.5, h * 0.38), w * 0.22, creamPaint);
        break;

      case CandyType.iceCreamStick:
        // Es Cokelat Stick (Bite taken out)
        final stickPaint = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill; // Stick kayu
        final barPaint = Paint()..color = const Color(0xFF4E342E)..style = PaintingStyle.fill; // Cokelat bar

        // Stick
        final stickRect = Rect.fromLTWH(w * 0.45, h * 0.65, w * 0.1, h * 0.25);
        canvas.drawRRect(RRect.fromRectAndRadius(stickRect, Radius.circular(w * 0.03)), stickPaint);

        // Chocolate bar with bite
        final barPath = Path()
          ..moveTo(w * 0.3, h * 0.7)
          ..lineTo(w * 0.3, h * 0.22)
          ..quadraticBezierTo(w * 0.3, h * 0.12, w * 0.45, h * 0.12)
          // Bite effect top right
          ..lineTo(w * 0.62, h * 0.12)
          ..arcToPoint(Offset(w * 0.7, h * 0.25), radius: Radius.circular(w * 0.08), clockwise: false)
          ..lineTo(w * 0.7, h * 0.7)
          ..close();
        canvas.drawPath(barPath, barPaint);
        break;

      case CandyType.lollipop:
        // Lollipop Swirl
        final stickPaint = Paint()..color = Colors.grey.shade400..strokeWidth = 3;
        final swirlPaint1 = Paint()..color = const Color(0xFFFF8A80)..style = PaintingStyle.fill;
        final swirlPaint2 = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3;

        // Stick
        canvas.drawLine(Offset(w / 2, h / 2), Offset(w / 2, h * 0.9), stickPaint);

        // Outer Head
        canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.22, swirlPaint1);
        
        // Swirl line
        final path = Path()
          ..moveTo(w / 2, h * 0.35)
          ..relativeQuadraticBezierTo(w * 0.05, -h * 0.05, w * 0.1, 0)
          ..relativeQuadraticBezierTo(w * 0.05, h * 0.08, -w * 0.05, h * 0.12)
          ..relativeQuadraticBezierTo(-w * 0.15, h * 0.02, -w * 0.15, -h * 0.1)
          ..relativeQuadraticBezierTo(0, -h * 0.15, w * 0.2, -h * 0.12);
        canvas.drawPath(path, swirlPaint2);
        break;

      case CandyType.cakeSlice:
        // Slice of Cake
        final platePaint = Paint()..color = Colors.blueGrey.shade100..strokeWidth = 2..style = PaintingStyle.stroke;
        final cakePaint = Paint()..color = const Color(0xFFD7CCC8)..style = PaintingStyle.fill;
        final cherryPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;

        // Plate line
        canvas.drawLine(Offset(w * 0.15, h * 0.78), Offset(w * 0.85, h * 0.78), platePaint);

        // Cake triangle
        final cakePath = Path()
          ..moveTo(w * 0.2, h * 0.75)
          ..lineTo(w * 0.8, h * 0.75)
          ..lineTo(w * 0.5, h * 0.35)
          ..close();
        canvas.drawPath(cakePath, cakePaint);

        // Layers lines
        final layerPaint = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 3;
        canvas.drawLine(Offset(w * 0.3, h * 0.62), Offset(w * 0.7, h * 0.62), layerPaint);
        canvas.drawLine(Offset(w * 0.4, h * 0.48), Offset(w * 0.6, h * 0.48), layerPaint);

        // Cherry on top
        canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.06, cherryPaint);
        break;

      case CandyType.pinkCake:
        // Pink Double Layer Cake
        final layer1 = Paint()..color = const Color(0xFFF48FB1)..style = PaintingStyle.fill;
        final layer2 = Paint()..color = const Color(0xFFF06292)..style = PaintingStyle.fill;
        final cream = Paint()..color = Colors.white..style = PaintingStyle.fill;

        // Bottom layer
        final bottomRect = Rect.fromLTWH(w * 0.2, h * 0.52, w * 0.6, h * 0.28);
        canvas.drawRRect(RRect.fromRectAndRadius(bottomRect, Radius.circular(w * 0.04)), layer1);

        // Top layer
        final topRect = Rect.fromLTWH(w * 0.3, h * 0.32, w * 0.4, h * 0.22);
        canvas.drawRRect(RRect.fromRectAndRadius(topRect, Radius.circular(w * 0.04)), layer2);

        // Decorative cream dots
        canvas.drawCircle(Offset(w * 0.38, h * 0.42), 3, cream);
        canvas.drawCircle(Offset(w * 0.5, h * 0.42), 3, cream);
        canvas.drawCircle(Offset(w * 0.62, h * 0.42), 3, cream);
        break;

      case CandyType.chocolateCake:
        // Chocolate slice
        final cakePaint = Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.fill;
        final cherryPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;

        final path = Path()
          ..moveTo(w * 0.15, h * 0.7)
          ..lineTo(w * 0.85, h * 0.7)
          ..lineTo(w * 0.6, h * 0.35)
          ..lineTo(w * 0.3, h * 0.35)
          ..close();
        canvas.drawPath(path, cakePaint);

        // Cherry
        canvas.drawCircle(Offset(w * 0.45, h * 0.24), w * 0.06, cherryPaint);
        break;

      case CandyType.rollCake:
        // Roll Cake
        final rollPaint1 = Paint()..color = const Color(0xFFFFE082)..style = PaintingStyle.fill;
        final rollPaint2 = Paint()..color = const Color(0xFFBCAAA4)..style = PaintingStyle.stroke..strokeWidth = 3;

        final rect = Rect.fromLTWH(w * 0.2, h * 0.3, w * 0.6, h * 0.4);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.08)), rollPaint1);

        // Swirl detail inside
        final swirl = Path()
          ..moveTo(w * 0.4, h * 0.5)
          ..arcToPoint(Offset(w * 0.6, h * 0.5), radius: Radius.circular(w * 0.1))
          ..arcToPoint(Offset(w * 0.3, h * 0.5), radius: Radius.circular(w * 0.15), clockwise: false);
        canvas.drawPath(swirl, rollPaint2);
        break;

      case CandyType.domeCookie:
        // Chocolate Dome Cookie
        final cookiePaint = Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.fill;
        final sprinklePaint = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill;

        final rect = Rect.fromLTWH(w * 0.22, h * 0.42, w * 0.56, h * 0.38);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.15)), cookiePaint);

        // Sprinkles dots
        canvas.drawCircle(Offset(w * 0.35, h * 0.55), 2.5, sprinklePaint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.52), 2.5, sprinklePaint);
        canvas.drawCircle(Offset(w * 0.65, h * 0.58), 2.5, sprinklePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter Khusus untuk Dotted Border tipis (Kotak target)
class _DottedBorderPainter extends CustomPainter {
  final Color color;

  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)));
    final dashedPath = Path();

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double distance = 0.0;

    for (var pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
