import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';

class ShapeMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ShapeMatchingScreen({super.key, this.levelId = 5});

  @override
  ConsumerState<ShapeMatchingScreen> createState() => _ShapeMatchingScreenState();
}

class _ShapeMatchingScreenState extends ConsumerState<ShapeMatchingScreen> {
  final Map<String, _ShapeData> _shapeData = {
    'square': _ShapeData(
      name: 'Kotak',
      color: const Color(0xFF4FC3F7), // Light Blue
    ),
    'circle': _ShapeData(
      name: 'Lingkaran',
      color: const Color(0xFFFFD54F), // Yellow
    ),
    'triangle': _ShapeData(
      name: 'Segitiga',
      color: const Color(0xFFEC407A), // Pink
    ),
  };

  final List<String> _orderedShapeKeys = ['square', 'circle', 'triangle'];
  late List<int> _randomizedTargetIndices;
  Map<String, bool> _matched = {};

  @override
  void initState() {
    super.initState();
    _randomizedTargetIndices = [0, 1, 2]..shuffle();
    _matched = {
      'square': false,
      'circle': false,
      'triangle': false,
    };
  }

  void _resetLevel() {
    setState(() {
      _matched = {
        'square': false,
        'circle': false,
        'triangle': false,
      };
      _randomizedTargetIndices.shuffle();
    });
  }

  void _checkWin() {
    if (_matched.values.every((val) => val == true)) {
      ref.read(progressProvider.notifier).completeLevel(widget.levelId);
      HapticService.success();
      CelebrationUtils.showCelebrationAndLevelUp(
        context: context,
        nextLevelId: 6,
        title: 'LUAR BIASA! 🌟',
        message: 'Level 5 Selesai! Kamu sudah menguasai semua bentuk!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F8FF), // Pastel Ice Blue background
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildInstruction(),
              const Spacer(),
              // Balanced Two Columns Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Kolom Kiri: Objek Draggable
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDraggableShape('square'),
                          const SizedBox(height: 24),
                          _buildDraggableShape('circle'),
                          const SizedBox(height: 24),
                          _buildDraggableShape('triangle'),
                        ],
                      ),
                    ),
                    
                    // Column separator line
                    Container(
                      width: 2,
                      height: 320,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    
                    // Kolom Kanan: Rumah Bentuk (DragTargets)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _randomizedTargetIndices.map((idx) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: _buildDragTarget(idx),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Centered Ulangi Button
              Center(
                child: TextButton.icon(
                  onPressed: _resetLevel,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent, size: 20),
                  label: const Text(
                    'Ulangi',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blueAccent),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Cocokkan Bentuk',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Pasangkan Bentuk ke Rumahnya!',
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

  Widget _buildDraggableShape(String type) {
    final challenge = _shapeData[type]!;
    final isMatched = _matched[type] ?? false;

    if (isMatched) {
      // Empty container to preserve layout symmetry
      return SizedBox(
        height: 80,
        child: Center(
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 2, style: BorderStyle.solid),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: Center(
        child: Draggable<String>(
          key: ValueKey('draggable_shape_$type'),
          data: type,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.85,
              child: ShapeWidget(shapeType: type, color: challenge.color, size: 75),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: ShapeWidget(shapeType: type, color: challenge.color, size: 65),
          ),
          child: ShapeWidget(shapeType: type, color: challenge.color, size: 65),
        ),
      ),
    );
  }

  Widget _buildDragTarget(int index) {
    final shapeKey = _orderedShapeKeys[index];
    final challenge = _shapeData[shapeKey]!;
    final isMatched = _matched[shapeKey] ?? false;

    return DragTarget<String>(
      key: ValueKey('target_card_$shapeKey'),
      onWillAccept: (data) => !isMatched, // Always listen for drop triggers if not matched
      onAccept: (data) {
        if (data == shapeKey) {
          setState(() {
            _matched[shapeKey] = true;
            HapticService.success();
            _checkWin();
          });
        } else {
          HapticFeedback.lightImpact();
          // Show a floating failure visual hint or simple feedback
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ups! Itu bukan rumah ${challenge.name}!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMatched ? challenge.color : Colors.grey.shade200,
              width: isMatched ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isMatched ? challenge.color.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            children: [
              // Silhouette or matched shape
              ShapeWidget(
                shapeType: shapeKey,
                color: challenge.color,
                isSiluet: !isMatched,
                size: 50,
              ),
              const SizedBox(width: 12),
              // Label
              Expanded(
                child: Text(
                  challenge.name,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isMatched ? challenge.color : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShapeData {
  final String name;
  final Color color;
  const _ShapeData({required this.name, required this.color});
}

class ShapeWidget extends StatelessWidget {
  final String shapeType;
  final Color color;
  final bool isSiluet;
  final double size;

  const ShapeWidget({
    super.key,
    required this.shapeType,
    required this.color,
    this.isSiluet = false,
    this.size = 65,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isSiluet ? Colors.grey.shade300 : color;

    if (shapeType == 'square') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: displayColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSiluet
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
      );
    } else if (shapeType == 'circle') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          boxShadow: isSiluet
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
      );
    } else {
      // Triangle
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _TrianglePainter(
            color: displayColor,
            shadowColor: isSiluet ? null : color.withOpacity(0.35),
          ),
        ),
      );
    }
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color? shadowColor;

  _TrianglePainter({required this.color, this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double w = size.width;
    double h = size.height;

    // Define path with small padding for round stroke
    final path = Path();
    path.moveTo(w / 2, 8);
    path.lineTo(w - 8, h - 8);
    path.lineTo(8, h - 8);
    path.close();

    // Draw shadow if present
    if (shadowColor != null) {
      final shadowPaint = Paint()
        ..color = shadowColor!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      final shadowPath = Path();
      shadowPath.moveTo(w / 2, 12);
      shadowPath.lineTo(w - 8, h - 4);
      shadowPath.lineTo(8, h - 4);
      shadowPath.close();
      
      final shadowStrokePaint = Paint()
        ..color = shadowColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      canvas.drawPath(shadowPath, shadowStrokePaint);
      canvas.drawPath(shadowPath, shadowPaint);
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => true;
}
