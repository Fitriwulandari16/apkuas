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

class _RowSequence {
  final String title;
  final List<ShapeType?> sequence; // null mewakili slot KOSONG
  final ShapeType correctType;     // Jawaban yang benar untuk slot KOSONG
  int? emptyIndex;
  bool isCorrect;
  ShapeType? userPlacedType;

  _RowSequence({
    required this.title,
    required List<ShapeType?> seq,
    required this.correctType,
  })  : sequence = List.from(seq),
        isCorrect = false {
    emptyIndex = sequence.indexOf(null);
  }
}

class _SequenceCompletionScreenState extends ConsumerState<SequenceCompletionScreen> with TickerProviderStateMixin {
  late List<_RowSequence> _rows;
  late List<ShapeType> _dockItems;
  late Map<int, AnimationController> _pulseControllers;

  // Warna presisi sesuai spesifikasi:
  // 1 = Segitiga (Hijau)
  // 2 = Lingkaran (Biru)
  // 3 = Segi Empat (Merah)
  static const Color colTriangle = Color(0xFF4CAF50); // Hijau
  static const Color colCircle = Color(0xFF2196F3);   // Biru
  static const Color colSquare = Color(0xFFF44336);   // Merah

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    _rows = [
      // Baris 1 (Pola 1-2-1-2): Segitiga - Lingkaran - Segitiga - [KOSONG] - Segitiga (Jawaban: Lingkaran)
      _RowSequence(
        title: 'Pola ABAB (1-2-1-2)',
        seq: [ShapeType.triangle, ShapeType.circle, ShapeType.triangle, null, ShapeType.triangle],
        correctType: ShapeType.circle,
      ),
      // Baris 2 (Pola 1-1-3-3): Segitiga - Segitiga - Segi Empat - [KOSONG] - Segi Empat (Jawaban: Segi Empat)
      _RowSequence(
        title: 'Pola AABB (1-1-3-3)',
        seq: [ShapeType.triangle, ShapeType.triangle, ShapeType.square, null, ShapeType.square],
        correctType: ShapeType.square,
      ),
      // Baris 3 (Pola 1-2-3): Segitiga - Lingkaran - Segi Empat - Segitiga - [KOSONG] - Segi Empat (Jawaban: Lingkaran)
      _RowSequence(
        title: 'Pola Berulang (1-2-3)',
        seq: [ShapeType.triangle, ShapeType.circle, ShapeType.square, ShapeType.triangle, null, ShapeType.square],
        correctType: ShapeType.circle,
      ),
    ];

    // Pilihan jawaban di bawah: tepat 1 Segitiga, 1 Lingkaran, 1 Segi Empat (diacak agar menarik)
    _dockItems = [
      ShapeType.triangle,
      ShapeType.circle,
      ShapeType.square,
    ]..shuffle();

    _pulseControllers = {};
    for (int i = 0; i < _rows.length; i++) {
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

  void _handleDrop(ShapeType draggedType, int rowIndex) {
    final row = _rows[rowIndex];
    if (row.isCorrect) return;

    if (draggedType == row.correctType) {
      HapticService.success();
      // Play pop/ting sound
      
      setState(() {
        row.isCorrect = true;
        row.userPlacedType = draggedType;
      });

      _pulseControllers[rowIndex]!.forward().then((_) {
        _pulseControllers[rowIndex]!.reverse();
      });

      // Cek kemenangan total
      if (_rows.every((r) => r.isCorrect)) {
        _onLevelComplete();
      }
    } else {
      HapticService.failure();
      // Menarik ke tempat salah otomatis mengembalikan ke dock (dikelola oleh Flutter Draggable)
    }
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 18,
      title: 'Hebat Pola Terpecahkan!',
      message: 'Wah, kamu hebat mengenali pola!',
    );
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
            
            // Baris Tantangan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_rows.length, (index) {
                    return _buildChallengeRow(index);
                  }),
                ),
              ),
            ),
            
            // Dermaga Jawaban (Dock)
            _buildAnswerDock(),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.extension_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Perhatikan urutannya, lalu tarik gambar yang hilang ke kotaknya!',
              style: GoogleFonts.fredoka(
                fontSize: 16,
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

  Widget _buildChallengeRow(int rowIndex) {
    final row = _rows[rowIndex];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(row.sequence.length, (colIndex) {
          final item = row.sequence[colIndex];
          
          if (item == null) {
            // Slot Kosong (Target)
            return DragTarget<ShapeType>(
              onWillAcceptWithDetails: (details) => !row.isCorrect,
              onAcceptWithDetails: (details) => _handleDrop(details.data, rowIndex),
              builder: (context, candidateData, rejectedData) {
                return ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.2).animate(
                    CurvedAnimation(
                      parent: _pulseControllers[rowIndex]!,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _DottedBorderPainter(
                      color: row.isCorrect 
                          ? Colors.green.shade400 
                          : (candidateData.isNotEmpty ? Colors.blue.shade500 : Colors.blueGrey.shade200),
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: row.isCorrect ? Colors.green.shade50.withOpacity(0.5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: row.isCorrect
                            ? _buildShapeWidget(row.userPlacedType!)
                            : Icon(
                                Icons.question_mark_rounded,
                                color: Colors.blueGrey.shade100,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          
          // Slot Terisi Normal
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _buildShapeWidget(item),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnswerDock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tarik bentuk ke kotak garis putus-putus',
            style: GoogleFonts.fredoka(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _dockItems.map((type) {
              // Jawaban yang sudah benar tetap dipertahankan (bisa ditarik lagi atau disembunyikan? 
              // Karena pilihan di bawah hanya ada 1x Segitiga, 1x Lingkaran, 1x Segi Empat,
              // dan baris 1 dan baris 3 sama-sama membutuhkan Lingkaran (2), kita tidak menyembunyikannya dari dock
              // agar anak bisa menggunakannya berkali-kali jika dibutuhkan).
              
              return Draggable<ShapeType>(
                data: type,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.2,
                    child: _buildShapeItemContainer(type, isShadow: true),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildShapeItemContainer(type),
                ),
                child: _buildShapeItemContainer(type),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeItemContainer(ShapeType type, {bool isShadow = false}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isShadow ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: isShadow ? 10 : 4,
            offset: Offset(0, isShadow ? 5 : 2),
          )
        ],
      ),
      child: Center(
        child: _buildShapeWidget(type),
      ),
    );
  }

  Widget _buildShapeWidget(ShapeType type) {
    switch (type) {
      case ShapeType.triangle:
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(
            painter: _GeometricShapePainter(type: ShapeType.triangle, color: colTriangle, number: '1'),
          ),
        );
      case ShapeType.circle:
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(
            painter: _GeometricShapePainter(type: ShapeType.circle, color: colCircle, number: '2'),
          ),
        );
      case ShapeType.square:
        return SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(
            painter: _GeometricShapePainter(type: ShapeType.square, color: colSquare, number: '3'),
          ),
        );
    }
  }
}

// Custom Painter Premium untuk Bentuk Geometri + Angka di dalamnya
class _GeometricShapePainter extends CustomPainter {
  final ShapeType type;
  final Color color;
  final String number;

  _GeometricShapePainter({required this.type, required this.color, required this.number});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();

    switch (type) {
      case ShapeType.triangle:
        // Segitiga sama sisi presisi
        path.moveTo(size.width / 2, 4);
        path.lineTo(size.width - 4, size.height - 4);
        path.lineTo(4, size.height - 4);
        path.close();
        canvas.drawPath(path, paint);
        break;
        
      case ShapeType.circle:
        // Lingkaran presisi
        canvas.drawCircle(center, size.width / 2 - 4, paint);
        break;
        
      case ShapeType.square:
        // Segi empat (Rounded Rect agar ramah anak)
        final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
        break;
    }

    // Menggambar Angka tebal putih di tengah bentuk
    final textPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    // Khusus segitiga, posisinya sedikit lebih ke bawah agar pas secara optik
    final verticalOffset = (type == ShapeType.triangle) ? 4.0 : 0.0;
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + verticalOffset,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter Khusus untuk Dotted / Dashed Border Slot Target
class _DottedBorderPainter extends CustomPainter {
  final Color color;

  _DottedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
    final dashedPath = Path();

    const dashWidth = 6.0;
    const dashSpace = 4.0;
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
