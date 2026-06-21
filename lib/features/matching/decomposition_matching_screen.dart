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
  Color? selectedColor;

  final List<Color> paletteColors = [
    Colors.green,
    Colors.yellow.shade700,
    Colors.blue,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    setState(() {
      selectedColor = null;
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
        if (errorAnimators[item.id] == null) {
          errorAnimators[item.id] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 400),
          );
        }
      }
    });
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
    if (selectedColor == null) return; // Belum pilih warna
    if (selectedItems[item.id] == true) return; // Sudah dipilih

    HapticService.light();

    // Validasi: warna harus sama dengan warna item dan item haruslah correct shape
    bool isColorMatch = false;
    if (item.color == Colors.green && selectedColor == Colors.green) isColorMatch = true;
    if (item.color == Colors.yellow.shade700 && selectedColor == Colors.yellow.shade700) isColorMatch = true;
    if (item.color == Colors.blue && selectedColor == Colors.blue) isColorMatch = true;
    if (item.color == Colors.orange && selectedColor == Colors.orange) isColorMatch = true;
    if (item.color == Colors.purple && selectedColor == Colors.purple) isColorMatch = true;
    
    if (item.isCorrect && isColorMatch) {
      setState(() {
        selectedItems[item.id] = true;
      });
      SoundService.playSuccess();
      HapticService.success();
    } else {
      // Salah pilih: getar HP dan animasi shake
      SoundService.playError();
      HapticFeedback.lightImpact();
      
      final controller = errorAnimators[item.id]!;
      controller.forward(from: 0);
    }
  }

  void gameWin() {
    _onLevelComplete();
  }

  void _onLevelComplete() {
    if (!isAllSolved) return;

    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    UserService.updateProgress(widget.levelId).catchError((e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    });
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 15,
      title: 'Luar Biasa!',
      message: 'Kamu hebat! Berhasil menguraikan semua bentuk penyusun gambar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildInstruction(),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
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
                        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                        child: Divider(thickness: 2, color: Colors.black12),
                      ),

                      // Tantangan B (Bawah)
                      _buildChallengeBlock(
                        title: 'Tantangan B',
                        isSolved: isBottomSolved,
                        gridItems: bottomGridItems,
                        targetWidget: _buildTargetB(),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Control Area
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.black87, width: 3.5)
                          : Border.all(color: Colors.white, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Center Submit / Reset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
              if (isAllSolved)
                ElevatedButton(
                  onPressed: gameWin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CilikTheme.tealTua,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
            ],
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
              'Level 14',
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
          const Icon(Icons.extension_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Pilih warna di bawah, lalu ketuk bentuk penyusun yang tepat!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
              if (isSolved)
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Belum Selesai',
                    style: GoogleFonts.fredoka(
                      fontSize: 10,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Target Gambar Gabungan
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey.shade50, width: 2),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: 0.8,
                    child: targetWidget,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Grid Pilihan Bentuk
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                        // Compute horizontal shake displacement
                        final double shakeOffset = math.sin(animController.value * math.pi * 4) * 8 * (1 - animController.value);
                        final borderColor = ColorTween(
                          begin: isSelected ? Colors.green : Colors.grey.shade200,
                          end: Colors.red,
                        ).evaluate(animController)!;

                        return Transform.translate(
                          offset: Offset(shakeOffset, 0),
                          child: GestureDetector(
                            onTap: () => _onShapeTapped(item),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor,
                                  width: isSelected || animController.value > 0 ? 3.0 : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Transform.scale(
                                  scale: isSelected ? 1.05 : 1.0,
                                  child: _ShapePainterWidget(
                                    type: item.type,
                                    color: item.color,
                                    size: 32,
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
        // Persegi Biru
        Positioned(
          bottom: 15,
          right: 15,
          child: _ShapePainterWidget(type: ShapeType.square, color: Colors.blue, size: 50),
        ),
        // Lingkaran Kuning
        Positioned(
          top: 20,
          right: 25,
          child: _ShapePainterWidget(type: ShapeType.circle, color: Colors.yellow.shade700, size: 50),
        ),
        // Segitiga Hijau
        Positioned(
          top: 20,
          left: 10,
          child: Transform.rotate(
            angle: math.pi / 6,
            child: _ShapePainterWidget(type: ShapeType.triangle, color: Colors.green, size: 55),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetB() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Trapesium Oranye
        Positioned(
          bottom: 15,
          right: 15,
          child: _ShapePainterWidget(type: ShapeType.trapezoid, color: Colors.orange, size: 50),
        ),
        // Segitiga Biru
        Positioned(
          top: 15,
          right: 25,
          child: _ShapePainterWidget(type: ShapeType.triangle, color: Colors.blue, size: 55),
        ),
        // Belah Ketupat Hijau
        Positioned(
          top: 20,
          left: 10,
          child: _ShapePainterWidget(type: ShapeType.rhombus, color: Colors.green, size: 50),
        ),
      ],
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
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Soft gradients for premium child-friendly UI
    List<Color> gradientColors;
    if (color == Colors.green) {
      gradientColors = [const Color(0xFF81C784), const Color(0xFF388E3C)];
    } else if (color == Colors.yellow.shade700) {
      gradientColors = [const Color(0xFFFFF176), const Color(0xFFFBC02D)];
    } else if (color == Colors.blue) {
      gradientColors = [const Color(0xFF64B5F6), const Color(0xFF1976D2)];
    } else if (color == Colors.orange) {
      gradientColors = [const Color(0xFFFFB74D), const Color(0xFFF57C00)];
    } else if (color == Colors.purple) {
      gradientColors = [const Color(0xFFBA68C8), const Color(0xFF7B1FA2)];
    } else if (color == Colors.red) {
      gradientColors = [const Color(0xFFE57373), const Color(0xFFD32F2F)];
    } else if (color == Colors.pink) {
      gradientColors = [const Color(0xFFF48FB1), const Color(0xFFC2185B)];
    } else {
      gradientColors = [color, color.withOpacity(0.8)];
    }

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    switch (type) {
      case ShapeType.circle:
        canvas.drawCircle(center, size.width / 2, paint);
        break;
      case ShapeType.square:
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
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

    // Glossy Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.15, size.width * 0.25, size.height * 0.25),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
