import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class ShapeColorMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ShapeColorMatchingScreen({super.key, this.levelId = 15});

  @override
  ConsumerState<ShapeColorMatchingScreen> createState() => _ShapeColorMatchingScreenState();
}

enum ShapeType { trapezoid, triangle, rectangle, rhombus, circle }

class _GameItem {
  final int id;
  final ShapeType shape;
  final Color color;

  _GameItem({required this.id, required this.shape, required this.color});
}

class _ShapeColorMatchingScreenState extends ConsumerState<ShapeColorMatchingScreen> {
  late List<_GameItem> targets;
  late List<_GameItem> choices;
  Set<int> matchedIds = {};

  final List<Color> _availableColors = [
    Colors.lightBlue.shade400,
    Colors.lightGreen.shade400,
    Colors.amber.shade400,
  ];

  final List<ShapeType> _availableShapes = [
    ShapeType.trapezoid,
    ShapeType.triangle,
    ShapeType.rectangle,
    ShapeType.rhombus,
    ShapeType.circle,
  ];

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    try {
      final random = math.Random();
      List<_GameItem> generatedTargets = [];
      
      // Pastikan kita menghasilkan 6 kombinasi unik (atau setidaknya mendekati unik)
      int idCounter = 1;
      while (generatedTargets.length < 6) {
        final color = _availableColors[random.nextInt(_availableColors.length)];
        final shape = _availableShapes[random.nextInt(_availableShapes.length)];
        
        // Mencegah terlalu banyak duplikat yang identik di layar
        bool isDuplicate = generatedTargets.any((t) => t.color == color && t.shape == shape);
        if (!isDuplicate || generatedTargets.length > 10) { 
          generatedTargets.add(_GameItem(id: idCounter++, shape: shape, color: color));
        }
      }

      targets = generatedTargets;
      choices = List.from(targets)..shuffle(random);
      matchedIds.clear();
    } catch (e, stack) {
      print("ERROR: Gagal melakukan inisialisasi Level 15: $e");
      print(stack);
      // Fallback inisialisasi yang aman agar tidak crash
      targets = [
        _GameItem(id: 1, shape: ShapeType.circle, color: Colors.blue),
        _GameItem(id: 2, shape: ShapeType.rectangle, color: Colors.green),
        _GameItem(id: 3, shape: ShapeType.triangle, color: Colors.yellow),
        _GameItem(id: 4, shape: ShapeType.rhombus, color: Colors.blue),
        _GameItem(id: 5, shape: ShapeType.trapezoid, color: Colors.green),
        _GameItem(id: 6, shape: ShapeType.rectangle, color: Colors.yellow),
      ];
      choices = List.from(targets);
      matchedIds.clear();
    }
  }

  // Safety check untuk GlobalKey agar tidak crash di Flutter Web
  Offset? _getSafeCenter(GlobalKey key) {
    try {
      if (key.currentContext != null) {
        final RenderBox? box = key.currentContext!.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          return Offset(position.dx + box.size.width / 2, position.dy + box.size.height / 2);
        }
      }
    } catch (e) {
      print("Warning: Gagal mendapatkan posisi center: $e");
    }
    return null;
  }

  void _onLevelComplete() {
    HapticService.success();
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    // Confetti berjalan otomatis di dalam method ini (selama durasi di CelebrationUtils)
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 16,
      title: 'Hebat Sekali!',
      message: 'Semua bentuk sudah pas pada tempatnya!',
    );
  }

  void _handleDrop(_GameItem choiceItem, _GameItem targetItem) {
    if (choiceItem.id == targetItem.id) {
      // Cocok!
      HapticService.light();
      // TODO: Play Pop Sound
      
      setState(() {
        matchedIds.add(targetItem.id);
      });

      if (matchedIds.length == targets.length) {
        _onLevelComplete();
      }
    } else {
      // Salah
      HapticService.failure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0, // Kotak sempurna
                    crossAxisSpacing: 24, // Jarak lebih renggang
                    mainAxisSpacing: 24, // Jarak lebih renggang
                  ),
                  itemCount: targets.length,
                  itemBuilder: (context, index) {
                    final target = targets[index];
                    final isMatched = matchedIds.contains(target.id);
                    
                    return DragTarget<_GameItem>(
                      onWillAcceptWithDetails: (details) => !isMatched,
                      onAcceptWithDetails: (details) => _handleDrop(details.data, target),
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          decoration: BoxDecoration(
                            color: target.color,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: target.color.withOpacity(0.3),
                                blurRadius: isMatched ? 4 : 10,
                                offset: const Offset(0, 4),
                              ),
                              if (candidateData.isNotEmpty)
                                BoxShadow(color: target.color.withOpacity(0.5), blurRadius: 15, spreadRadius: 3)
                            ],
                          ),
                          child: Center(
                            child: isMatched
                                ? TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.5, end: 1.0),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    builder: (context, val, child) {
                                      return Transform.scale(
                                        scale: val,
                                        child: _ShapePainterWidget(
                                          type: target.shape, 
                                          color: target.color, // Warnanya solid sesuai background agar siluet tertutup sempurna
                                          size: 80,
                                        ),
                                      );
                                    },
                                  )
                                : _ShapePainterWidget(
                                    type: target.shape,
                                    color: Colors.white, // Siluet putih bersih sebagai lubang
                                    size: 80,
                                    isDashed: true, // Garis putus-putus penanda lubang
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            
            // Pembatas
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Area Bawah (Choices)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: choices.map((choice) {
                    if (matchedIds.contains(choice.id)) {
                      return const SizedBox(width: 80, height: 80); // Kosongkan tempat
                    }
                    
                    return Draggable<_GameItem>(
                      data: choice,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.scale(
                          scale: 1.25, // Animasi membesar saat ditarik
                          child: _ShapePainterWidget(
                            type: choice.shape,
                            color: choice.color.withOpacity(0.9),
                            size: 80,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildChoiceItem(choice),
                      ),
                      child: _buildChoiceItem(choice),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceItem(_GameItem choice) {
    return Material(
      color: Colors.transparent,
      child: _ShapePainterWidget(
        type: choice.shape,
        color: choice.color,
        size: 80,
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
              'Level 15',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CilikTheme.tealTua,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balancing
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Tarik dan tempelkan pada bentuk yang tepat!',
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
  final bool isDashed;

  const _ShapePainterWidget({
    required this.type,
    required this.color,
    required this.size,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShapePainterCore(type: type, color: color, isDashed: isDashed),
      ),
    );
  }
}

class _ShapePainterCore extends CustomPainter {
  final ShapeType type;
  final Color color;
  final bool isDashed;

  _ShapePainterCore({required this.type, required this.color, this.isDashed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isDashed ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 3.0;
      
    final path = Path();
    
    switch (type) {
      case ShapeType.circle:
        path.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
        break;
      case ShapeType.rectangle:
        path.addRect(Rect.fromLTWH(0, size.height * 0.15, size.width, size.height * 0.7));
        break;
      case ShapeType.rhombus:
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(size.width / 2, size.height);
        path.lineTo(0, size.height / 2);
        path.close();
        break;
      case ShapeType.triangle:
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        break;
      case ShapeType.trapezoid:
        path.moveTo(size.width * 0.25, 0);
        path.lineTo(size.width * 0.75, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        path.close();
        break;
    }

    if (!isDashed) {
      canvas.drawPath(path, paint);
    } else {
      // 1. Gambar siluet putih transparan di dalam lubang terlebih dahulu
      final fillPaint = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // 2. Gambar garis putus-putus putih bersih
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
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
