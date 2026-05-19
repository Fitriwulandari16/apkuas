import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class DecompositionMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const DecompositionMatchingScreen({super.key, this.levelId = 14});

  @override
  ConsumerState<DecompositionMatchingScreen> createState() => _DecompositionMatchingScreenState();
}

enum ShapeType { circle, square, hexagon, triangle, parallelogram, trapezoid, rhombus }

class _ShapeData {
  final int id;
  final ShapeType type;
  final Color color;
  final bool isCorrect;
  _ShapeData({required this.id, required this.type, required this.color, required this.isCorrect});
}

class _DecompositionMatchingScreenState extends ConsumerState<DecompositionMatchingScreen> with TickerProviderStateMixin {
  late List<_ShapeData> topGridItems;
  late List<_ShapeData> bottomGridItems;
  
  Map<int, bool> selectedItems = {};
  Map<int, AnimationController> errorAnimators = {};

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    // === TANTANGAN A (Atas) ===
    // Benar: Segitiga Hijau, Lingkaran Kuning, Persegi Biru
    List<_ShapeData> topItems = [
      _ShapeData(id: 1, type: ShapeType.triangle, color: Colors.green, isCorrect: true),
      _ShapeData(id: 2, type: ShapeType.circle, color: Colors.yellow.shade700, isCorrect: true),
      _ShapeData(id: 3, type: ShapeType.square, color: Colors.blue, isCorrect: true),
      
      // Pengecoh
      _ShapeData(id: 4, type: ShapeType.circle, color: Colors.red, isCorrect: false),
      _ShapeData(id: 5, type: ShapeType.square, color: Colors.yellow.shade700, isCorrect: false),
      _ShapeData(id: 6, type: ShapeType.parallelogram, color: Colors.purple, isCorrect: false),
    ];
    topItems.shuffle();
    topGridItems = topItems;

    // === TANTANGAN B (Bawah) ===
    // Benar: Trapesium Oranye, Segitiga Biru, Belah Ketupat Hijau
    List<_ShapeData> bottomItems = [
      _ShapeData(id: 7, type: ShapeType.trapezoid, color: Colors.orange, isCorrect: true),
      _ShapeData(id: 8, type: ShapeType.triangle, color: Colors.blue, isCorrect: true),
      _ShapeData(id: 9, type: ShapeType.rhombus, color: Colors.green, isCorrect: true),
      
      // Pengecoh
      _ShapeData(id: 10, type: ShapeType.hexagon, color: Colors.pink, isCorrect: false),
      _ShapeData(id: 11, type: ShapeType.triangle, color: Colors.green, isCorrect: false),
      _ShapeData(id: 12, type: ShapeType.square, color: Colors.blue, isCorrect: false),
    ];
    bottomItems.shuffle();
    bottomGridItems = bottomItems;

    // Gabungkan states
    selectedItems.clear();
    for (var item in [...topGridItems, ...bottomGridItems]) {
      selectedItems[item.id] = false;
      errorAnimators[item.id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in errorAnimators.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get isTopSolved {
    return topGridItems.where((e) => e.isCorrect).every((e) => selectedItems[e.id] == true);
  }

  bool get isBottomSolved {
    return bottomGridItems.where((e) => e.isCorrect).every((e) => selectedItems[e.id] == true);
  }

  bool get isAllSolved => isTopSolved && isBottomSolved;

  void _onShapeTapped(_ShapeData item) {
    if (selectedItems[item.id] == true) return; // Sudah dipilih

    HapticService.light();

    if (item.isCorrect) {
      setState(() {
        selectedItems[item.id] = true;
      });

      // Umpan balik taktil jika berhasil
      HapticService.light();

      // Cek kemenangan otomatis bisa, tapi sekarang kita sediakan tombol Selesai di bawah halaman
      if (isAllSolved) {
        HapticService.success();
      }
    } else {
      // Salah pilih: animasi merah berkedip
      HapticService.failure();
      
      final controller = errorAnimators[item.id]!;
      controller.forward().then((_) {
        controller.reverse();
      });
    }
  }

  void _onLevelComplete() {
    if (!isAllSolved) return;

    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 15,
      title: 'Luar Biasa!',
      message: 'Kamu hebat! Berhasil menguraikan semua bentuk penyusun gambar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // Tantangan A (Atas)
                    _buildChallengeBlock(
                      title: 'Tantangan A',
                      isSolved: isTopSolved,
                      gridItems: topGridItems,
                      targetWidget: _buildTargetA(),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                      child: Divider(thickness: 2, color: Colors.black12),
                    ),

                    // Tantangan B (Bawah)
                    _buildChallengeBlock(
                      title: 'Tantangan B',
                      isSolved: isBottomSolved,
                      gridItems: bottomGridItems,
                      targetWidget: _buildTargetB(),
                    ),
                    
                    const SizedBox(height: 30),

                    // Tombol Selesai Global
                    _buildSubmitButton(),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 14',
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
          const Icon(Icons.extension_rounded, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Sentuh bentuk penyusun dari masing-masing gambar!',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeBlock({
    required String title,
    required bool isSolved,
    required List<_ShapeData> gridItems,
    required Widget targetWidget,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
              if (isSolved)
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Belum Selesai',
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Target Gambar Gabungan
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueGrey.shade50, width: 2),
                ),
                child: targetWidget,
              ),
              const SizedBox(width: 16),
              
              // Grid Pilihan Bentuk
              Expanded(
                child: SizedBox(
                  height: 140,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: gridItems.length,
                    itemBuilder: (context, index) {
                      final item = gridItems[index];
                      final isSelected = selectedItems[item.id] == true;
                      final animController = errorAnimators[item.id]!;

                      return AnimatedBuilder(
                        animation: animController,
                        builder: (context, child) {
                          final borderColor = ColorTween(
                            begin: isSelected ? Colors.green : Colors.transparent,
                            end: Colors.red,
                          ).evaluate(animController)!;

                          return GestureDetector(
                            onTap: () => _onShapeTapped(item),
                            child: CustomPaint(
                              painter: isSelected || animController.value > 0
                                  ? _DashedBorderPainter(color: borderColor, isDashed: isSelected)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Center(
                                  child: Transform.scale(
                                    scale: isSelected ? 1.05 : 1.0,
                                    child: _ShapePainterWidget(
                                      type: item.type,
                                      color: item.color,
                                      size: 36,
                                    ),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  Widget _buildTargetA() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Persegi Biru (Bawah kanan)
        Positioned(
          bottom: 25,
          right: 25,
          child: _ShapePainterWidget(type: ShapeType.square, color: Colors.blue, size: 60),
        ),
        // Lingkaran Kuning (Tengah)
        Positioned(
          top: 30,
          right: 35,
          child: _ShapePainterWidget(type: ShapeType.circle, color: Colors.yellow.shade700, size: 65),
        ),
        // Segitiga Hijau (Atas kiri)
        Positioned(
          top: 30,
          left: 20,
          child: Transform.rotate(
            angle: math.pi / 6,
            child: _ShapePainterWidget(type: ShapeType.triangle, color: Colors.green, size: 70),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetB() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Trapesium Oranye (Bawah kanan)
        Positioned(
          bottom: 25,
          right: 25,
          child: _ShapePainterWidget(type: ShapeType.trapezoid, color: Colors.orange, size: 65),
        ),
        // Segitiga Biru (Tengah)
        Positioned(
          top: 25,
          right: 35,
          child: _ShapePainterWidget(type: ShapeType.triangle, color: Colors.blue, size: 70),
        ),
        // Belah Ketupat Hijau (Atas kiri)
        Positioned(
          top: 30,
          left: 20,
          child: _ShapePainterWidget(type: ShapeType.rhombus, color: Colors.green, size: 60),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AnimatedOpacity(
        opacity: isAllSolved ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          onPressed: isAllSolved ? _onLevelComplete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: CilikTheme.tealTua,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: isAllSolved ? 6 : 0,
            shadowColor: CilikTheme.tealTua.withOpacity(0.4),
          ),
          child: Text(
            'Selesai',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapePainterWidget extends StatelessWidget {
  final ShapeType type;
  final Color color;
  final double size;

  const _ShapePainterWidget({required this.type, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShapePainterCore(type: type, color: color),
      ),
    );
  }
}

class _ShapePainterCore extends CustomPainter {
  final ShapeType type;
  final Color color;

  _ShapePainterCore({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    switch (type) {
      case ShapeType.circle:
        canvas.drawCircle(center, size.width / 2, paint);
        break;
      case ShapeType.square:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case ShapeType.hexagon:
        final path = Path();
        for (int i = 0; i < 6; i++) {
          double angle = (i * 60 - 30) * math.pi / 180;
          double x = center.dx + (size.width / 2) * math.cos(angle);
          double y = center.dy + (size.height / 2) * math.sin(angle);
          if (i == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case ShapeType.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case ShapeType.parallelogram:
        final path = Path()
          ..moveTo(size.width * 0.25, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width * 0.75, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case ShapeType.trapezoid:
        final path = Path()
          ..moveTo(size.width * 0.2, 0)
          ..lineTo(size.width * 0.8, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case ShapeType.rhombus:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter untuk Lingkaran Putus-putus
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _DashedBorderPainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(-6, -6, size.width + 12, size.height + 12);

    if (!isDashed) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(15)), paint);
      return;
    }

    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(15)));
    final dashedPath = Path();

    const dashWidth = 8.0;
    const dashSpace = 6.0;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
