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

class _SequenceCompletionScreenState extends ConsumerState<SequenceCompletionScreen> {
  late List<_GridCell> cells;
  Color? selectedColor;

  static const Color colTriangle = Color(0xFF4CAF50); // Hijau
  static const Color colCircle = Color(0xFF2196F3);   // Biru
  static const Color colSquare = Color(0xFFF44336);   // Merah

  final List<Color> paletteColors = [
    colTriangle,
    colCircle,
    colSquare,
  ];

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    setState(() {
      selectedColor = null;
      final layout = [
        CandyType.green, CandyType.cupcake, CandyType.red, CandyType.iceCreamCone, CandyType.purple,
        CandyType.cakeSlice, CandyType.green, CandyType.purple, CandyType.lollipop, CandyType.red,
        CandyType.red, CandyType.iceCreamStick, CandyType.green, CandyType.purple, CandyType.chocolateCake,
        CandyType.green, CandyType.pinkCake, CandyType.red, CandyType.domeCookie, CandyType.purple,
        CandyType.iceCreamCone, CandyType.purple, CandyType.rollCake, CandyType.red, CandyType.green,
      ];
      cells = layout.map((type) => _GridCell(type: type)).toList();
    });
  }

  bool _handleColorTap(int index, Color? color) {
    if (color == null) return false;
    final cell = cells[index];

    ShapeType? chosenShape;
    if (color == colTriangle) chosenShape = ShapeType.triangle;
    if (color == colCircle) chosenShape = ShapeType.circle;
    if (color == colSquare) chosenShape = ShapeType.square;

    if (cell.requiredShape == chosenShape) {
      setState(() {
        cell.isMatched = true;
      });
      SoundService.playSuccess();
      HapticService.success();

      // Cek kemenangan
      final targets = cells.where((c) => c.requiredShape != null);
      if (targets.every((c) => c.isMatched)) {
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
      nextLevelId: 18,
      title: 'Hore! Kamu Pintar!',
      message: 'Kamu berhasil mengelompokkan semua permen dengan bingkai yang benar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FBF9),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildInstruction(),
              
              // Legenda Petunjuk Atas (Bersih tanpa teks/simbol)
              _buildLegendCard(),
              
              // Area Grid 5x5
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: cells.length,
                        itemBuilder: (context, index) {
                          return _GridCellWidget(
                            index: index,
                            cell: cells[index],
                            selectedColor: selectedColor,
                            onColorSubmitted: _handleColorTap,
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
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
          // Row of Color Pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: paletteColors.map((color) {
              final isSelected = selectedColor == color;
              
              // Map color to corresponding shape to draw inside palette circles
              ShapeType shapeType = ShapeType.triangle;
              if (color == colCircle) shapeType = ShapeType.circle;
              if (color == colSquare) shapeType = ShapeType.square;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                  HapticFeedback.selectionClick();
                },
                child: AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.black87, width: 3.5)
                          : Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: CustomPaint(
                      painter: _GeometryFramePainter(type: shapeType, color: color),
                    ),
                  ),
                ),
              );
            }).toList(),
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
              'Pilih warna di bawah, lalu pasang bingkai permen yang sesuai!',
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
}

class _GridCellWidget extends StatefulWidget {
  final int index;
  final _GridCell cell;
  final Color? selectedColor;
  final bool Function(int, Color?) onColorSubmitted;

  const _GridCellWidget({
    required this.index,
    required this.cell,
    required this.selectedColor,
    required this.onColorSubmitted,
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
        bool correct = widget.onColorSubmitted(widget.index, widget.selectedColor);
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMatched ? Colors.green.shade100 : Colors.grey.shade100,
              width: 1.0,
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
              if (isMatched)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CustomPaint(
                      painter: _GeometryFramePainter(
                        type: cell.requiredShape!,
                        color: cell.requiredShape == ShapeType.triangle
                            ? const Color(0xFF4CAF50)
                            : (cell.requiredShape == ShapeType.circle ? const Color(0xFF2196F3) : const Color(0xFFF44336)),
                      ),
                    ),
                  ),
                )
              else if (cell.requiredShape != null)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CustomPaint(
                      painter: _DottedBorderPainter(color: Colors.grey.shade300),
                    ),
                  ),
                ),

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
      ),
    );
  }
}

class _GeometryFramePainter extends CustomPainter {
  final ShapeType type;
  final Color color;

  _GeometryFramePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
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
        final bodyPaint = Paint()..color = Colors.purple..style = PaintingStyle.fill;
        final wingPaint = Paint()..color = Colors.purple.shade700..style = PaintingStyle.fill;
        
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

        final rect = Rect.fromLTRB(w * 0.35, h * 0.2, w * 0.65, h * 0.8);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.15)), bodyPaint);
        
        final linePaint = Paint()..color = Colors.white24..strokeWidth = 2;
        canvas.drawLine(Offset(w * 0.45, h * 0.3), Offset(w * 0.45, h * 0.7), linePaint);
        canvas.drawLine(Offset(w * 0.55, h * 0.3), Offset(w * 0.55, h * 0.7), linePaint);
        break;

      case CandyType.red:
        final bodyPaint = Paint()..color = const Color(0xFFE53935)..style = PaintingStyle.fill;
        final wingPaint = Paint()..color = const Color(0xFFC62828)..style = PaintingStyle.fill;

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

        canvas.drawCircle(center, w * 0.26, bodyPaint);

        final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.42, h * 0.42), w * 0.05, dotPaint);
        canvas.drawCircle(Offset(w * 0.58, h * 0.45), w * 0.04, dotPaint);
        canvas.drawCircle(Offset(w * 0.48, h * 0.58), w * 0.05, dotPaint);
        break;

      case CandyType.green:
        final bodyPaint = Paint()..color = const Color(0xFF8BC34A)..style = PaintingStyle.fill;
        final wingPaint = Paint()..color = const Color(0xFFFFEB3B)..style = PaintingStyle.fill;

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

        final bodyRect = Rect.fromLTRB(w * 0.25, h * 0.3, w * 0.75, h * 0.7);
        canvas.drawOval(bodyRect, bodyPaint);

        final stripePaint = Paint()
          ..color = const Color(0xFFFFEB3B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawLine(Offset(w * 0.4, h * 0.32), Offset(w * 0.4, h * 0.68), stripePaint);
        canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.7), stripePaint);
        canvas.drawLine(Offset(w * 0.6, h * 0.32), Offset(w * 0.6, h * 0.68), stripePaint);
        break;

      case CandyType.cupcake:
        final cupPaint = Paint()..color = const Color(0xFF8D6E63)..style = PaintingStyle.fill;
        final creamPaint = Paint()..color = const Color(0xFFF8BBD0)..style = PaintingStyle.fill;
        
        final cupPath = Path()
          ..moveTo(w * 0.3, h * 0.5)
          ..lineTo(w * 0.7, h * 0.5)
          ..lineTo(w * 0.65, h * 0.85)
          ..lineTo(w * 0.35, h * 0.85)
          ..close();
        canvas.drawPath(cupPath, cupPaint);

        canvas.drawCircle(Offset(w * 0.4, h * 0.42), w * 0.16, creamPaint);
        canvas.drawCircle(Offset(w * 0.6, h * 0.42), w * 0.16, creamPaint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.34), w * 0.16, creamPaint);

        final cherryPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.5, h * 0.22), w * 0.06, cherryPaint);
        break;

      case CandyType.iceCreamCone:
        final conePaint = Paint()..color = const Color(0xFFFFCC80)..style = PaintingStyle.fill;
        final creamPaint = Paint()..color = const Color(0xFFF48FB1)..style = PaintingStyle.fill;

        final conePath = Path()
          ..moveTo(w * 0.32, h * 0.45)
          ..lineTo(w * 0.68, h * 0.45)
          ..lineTo(w * 0.5, h * 0.9)
          ..close();
        canvas.drawPath(conePath, conePaint);

        canvas.drawCircle(Offset(w * 0.5, h * 0.38), w * 0.22, creamPaint);
        break;

      case CandyType.iceCreamStick:
        final stickPaint = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill;
        final barPaint = Paint()..color = const Color(0xFF4E342E)..style = PaintingStyle.fill;

        final stickRect = Rect.fromLTWH(w * 0.45, h * 0.65, w * 0.1, h * 0.25);
        canvas.drawRRect(RRect.fromRectAndRadius(stickRect, Radius.circular(w * 0.03)), stickPaint);

        final barPath = Path()
          ..moveTo(w * 0.3, h * 0.7)
          ..lineTo(w * 0.3, h * 0.22)
          ..quadraticBezierTo(w * 0.3, h * 0.12, w * 0.45, h * 0.12)
          ..lineTo(w * 0.62, h * 0.12)
          ..arcToPoint(Offset(w * 0.7, h * 0.25), radius: Radius.circular(w * 0.08), clockwise: false)
          ..lineTo(w * 0.7, h * 0.7)
          ..close();
        canvas.drawPath(barPath, barPaint);
        break;

      case CandyType.lollipop:
        final stickPaint = Paint()..color = Colors.grey.shade400..strokeWidth = 3;
        final swirlPaint1 = Paint()..color = const Color(0xFFFF8A80)..style = PaintingStyle.fill;
        final swirlPaint2 = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3;

        canvas.drawLine(Offset(w / 2, h / 2), Offset(w / 2, h * 0.9), stickPaint);
        canvas.drawCircle(Offset(w / 2, h * 0.35), w * 0.22, swirlPaint1);
        
        final path = Path()
          ..moveTo(w / 2, h * 0.35)
          ..relativeQuadraticBezierTo(w * 0.05, -h * 0.05, w * 0.1, 0)
          ..relativeQuadraticBezierTo(w * 0.05, h * 0.08, -w * 0.05, h * 0.12)
          ..relativeQuadraticBezierTo(-w * 0.15, h * 0.02, -w * 0.15, -h * 0.1)
          ..relativeQuadraticBezierTo(0, -h * 0.15, w * 0.2, -h * 0.12);
        canvas.drawPath(path, swirlPaint2);
        break;

      case CandyType.cakeSlice:
        final platePaint = Paint()..color = Colors.blueGrey.shade100..strokeWidth = 2..style = PaintingStyle.stroke;
        final cakePaint = Paint()..color = const Color(0xFFD7CCC8)..style = PaintingStyle.fill;
        final cherryPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;

        canvas.drawLine(Offset(w * 0.15, h * 0.78), Offset(w * 0.85, h * 0.78), platePaint);

        final cakePath = Path()
          ..moveTo(w * 0.2, h * 0.75)
          ..lineTo(w * 0.8, h * 0.75)
          ..lineTo(w * 0.5, h * 0.35)
          ..close();
        canvas.drawPath(cakePath, cakePaint);

        final layerPaint = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 3;
        canvas.drawLine(Offset(w * 0.3, h * 0.62), Offset(w * 0.7, h * 0.62), layerPaint);
        canvas.drawLine(Offset(w * 0.4, h * 0.48), Offset(w * 0.6, h * 0.48), layerPaint);

        canvas.drawCircle(Offset(w * 0.5, h * 0.26), w * 0.06, cherryPaint);
        break;

      case CandyType.pinkCake:
        final layer1 = Paint()..color = const Color(0xFFF48FB1)..style = PaintingStyle.fill;
        final layer2 = Paint()..color = const Color(0xFFF06292)..style = PaintingStyle.fill;
        final cream = Paint()..color = Colors.white..style = PaintingStyle.fill;

        final bottomRect = Rect.fromLTWH(w * 0.2, h * 0.52, w * 0.6, h * 0.28);
        canvas.drawRRect(RRect.fromRectAndRadius(bottomRect, Radius.circular(w * 0.04)), layer1);

        final topRect = Rect.fromLTWH(w * 0.3, h * 0.32, w * 0.4, h * 0.22);
        canvas.drawRRect(RRect.fromRectAndRadius(topRect, Radius.circular(w * 0.04)), layer2);

        canvas.drawCircle(Offset(w * 0.38, h * 0.42), 3, cream);
        canvas.drawCircle(Offset(w * 0.5, h * 0.42), 3, cream);
        canvas.drawCircle(Offset(w * 0.62, h * 0.42), 3, cream);
        break;

      case CandyType.chocolateCake:
        final cakePaint = Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.fill;
        final cherryPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;

        final path = Path()
          ..moveTo(w * 0.15, h * 0.7)
          ..lineTo(w * 0.85, h * 0.7)
          ..lineTo(w * 0.6, h * 0.35)
          ..lineTo(w * 0.3, h * 0.35)
          ..close();
        canvas.drawPath(path, cakePaint);

        canvas.drawCircle(Offset(w * 0.45, h * 0.24), w * 0.06, cherryPaint);
        break;

      case CandyType.rollCake:
        final rollPaint1 = Paint()..color = const Color(0xFFFFE082)..style = PaintingStyle.fill;
        final rollPaint2 = Paint()..color = const Color(0xFFBCAAA4)..style = PaintingStyle.stroke..strokeWidth = 3;

        final rect = Rect.fromLTWH(w * 0.2, h * 0.3, w * 0.6, h * 0.4);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.08)), rollPaint1);

        final swirl = Path()
          ..moveTo(w * 0.4, h * 0.5)
          ..arcToPoint(Offset(w * 0.6, h * 0.5), radius: Radius.circular(w * 0.1))
          ..arcToPoint(Offset(w * 0.3, h * 0.5), radius: Radius.circular(w * 0.15), clockwise: false);
        canvas.drawPath(swirl, rollPaint2);
        break;

      case CandyType.domeCookie:
        final cookiePaint = Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.fill;
        final sprinklePaint = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.fill;

        final rect = Rect.fromLTWH(w * 0.22, h * 0.42, w * 0.56, h * 0.38);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w * 0.15)), cookiePaint);

        canvas.drawCircle(Offset(w * 0.35, h * 0.55), 2.5, sprinklePaint);
        canvas.drawCircle(Offset(w * 0.5, h * 0.52), 2.5, sprinklePaint);
        canvas.drawCircle(Offset(w * 0.65, h * 0.58), 2.5, sprinklePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
