import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

class DecompositionMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const DecompositionMatchingScreen({super.key, this.levelId = 14});

  @override
  ConsumerState<DecompositionMatchingScreen> createState() => _DecompositionMatchingScreenState();
}

enum ShapeType { circle, square, hexagon, triangle, parallelogram }

class _ShapeData {
  final int id;
  final ShapeType type;
  final Color color;
  final bool isCorrect;
  _ShapeData({required this.id, required this.type, required this.color, required this.isCorrect});
}

class _DecompositionMatchingScreenState extends ConsumerState<DecompositionMatchingScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  late List<_ShapeData> gridItems;
  Map<int, bool> selectedItems = {};
  Map<int, AnimationController> errorAnimators = {};

  final int _targetCorrectCount = 3;

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    // 3 Bentuk Benar
    List<_ShapeData> items = [
      _ShapeData(id: 1, type: ShapeType.triangle, color: Colors.green, isCorrect: true),
      _ShapeData(id: 2, type: ShapeType.circle, color: Colors.yellow.shade700, isCorrect: true),
      _ShapeData(id: 3, type: ShapeType.square, color: Colors.blue, isCorrect: true),
      
      // 6 Pengecoh
      _ShapeData(id: 4, type: ShapeType.circle, color: Colors.red, isCorrect: false),
      _ShapeData(id: 5, type: ShapeType.square, color: Colors.yellow.shade700, isCorrect: false),
      _ShapeData(id: 6, type: ShapeType.triangle, color: Colors.blue, isCorrect: false),
      _ShapeData(id: 7, type: ShapeType.parallelogram, color: Colors.purple, isCorrect: false),
      _ShapeData(id: 8, type: ShapeType.parallelogram, color: Colors.orange, isCorrect: false),
      _ShapeData(id: 9, type: ShapeType.hexagon, color: Colors.pink, isCorrect: false),
    ];

    items.shuffle();
    gridItems = items;
    selectedItems = {for (var item in items) item.id: false};

    for (var item in items) {
      errorAnimators[item.id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    for (var controller in errorAnimators.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _playSound(String name) async {
    // Placeholder untuk suara 'Pluk!'
    // await _audioPlayer.play(AssetSource('sounds/$name.mp3'));
  }

  void _onLevelComplete() {
    HapticService.success();
    _playSound('level_win');
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    // Ini otomatis memanggil Confetti selama 2 detik lalu menampilkan overlay
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 15,
      title: 'Luar Biasa!',
      message: 'Kamu berhasil menemukan semua bentuk penyusunnya!',
    );
  }

  void _onShapeTapped(_ShapeData item) {
    if (selectedItems[item.id] == true) return; // Sudah dipilih

    HapticService.light();
    _playSound('pluk');

    if (item.isCorrect) {
      setState(() {
        selectedItems[item.id] = true;
      });

      // Cek kemenangan
      int correctSelected = gridItems.where((e) => e.isCorrect && selectedItems[e.id] == true).length;
      if (correctSelected == _targetCorrectCount) {
        _onLevelComplete();
      }
    } else {
      // Salah pilih: animasi merah lalu menghilang
      HapticService.failure();
      _playSound('error');
      
      final controller = errorAnimators[item.id]!;
      controller.forward().then((_) {
        controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Latar bersih untuk kontras
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            Expanded(
              child: Row(
                children: [
                  // Sisi Kiri (Target)
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blueGrey.shade100, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Persegi Biru
                            Positioned(
                              bottom: 40,
                              right: 40,
                              child: _ShapePainterWidget(type: ShapeType.square, color: Colors.blue, size: 120),
                            ),
                            // Lingkaran Kuning
                            Positioned(
                              top: 50,
                              right: 60,
                              child: _ShapePainterWidget(type: ShapeType.circle, color: Colors.yellow.shade700, size: 130),
                            ),
                            // Segitiga Hijau
                            Positioned(
                              top: 60,
                              left: 30,
                              child: Transform.rotate(
                                angle: math.pi / 6,
                                child: _ShapePainterWidget(type: ShapeType.triangle, color: Colors.green, size: 140),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Pemisah
                  Container(
                    width: 4,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 40),
                  ),

                  // Sisi Kanan (Opsi Grid)
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
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
                              // Animasi warna merah jika salah
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
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                                    ),
                                    child: Center(
                                      child: Transform.scale(
                                        scale: isSelected ? 1.1 : 1.0,
                                        child: _ShapePainterWidget(
                                          type: item.type,
                                          color: item.color,
                                          size: 60,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.extension_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Sentuh bentuk-bentuk yang menyusun gambar ini!',
              style: GoogleFonts.fredoka(
                fontSize: 18,
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
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(-10, -10, size.width + 20, size.height + 20);

    if (!isDashed) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)), paint);
      return;
    }

    // Menggambar putus-putus dengan PathMetrics
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(25)));
    final dashedPath = Path();

    const dashWidth = 10.0;
    const dashSpace = 8.0;
    double distance = 0.0;

    for (var pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0; // Reset for next metric
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
