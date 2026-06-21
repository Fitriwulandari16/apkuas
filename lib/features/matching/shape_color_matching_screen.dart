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
  Set<int> matchedIds = {};
  Color? selectedColor;

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
    setState(() {
      selectedColor = null;
      matchedIds.clear();
      final random = math.Random();
      List<_GameItem> generatedTargets = [];
      
      int idCounter = 1;
      while (generatedTargets.length < 6) {
        final color = _availableColors[random.nextInt(_availableColors.length)];
        final shape = _availableShapes[random.nextInt(_availableShapes.length)];
        
        bool isDuplicate = generatedTargets.any((t) => t.color == color && t.shape == shape);
        if (!isDuplicate || generatedTargets.length > 10) { 
          generatedTargets.add(_GameItem(id: idCounter++, shape: shape, color: color));
        }
      }
      targets = generatedTargets;
    });
  }

  void _onLevelComplete() {
    SoundService.playSuccess();
    HapticService.success();
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    UserService.updateProgress(widget.levelId).catchError((e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    });
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 16,
      title: 'Hebat Sekali!',
      message: 'Semua bentuk sudah pas pada tempatnya!',
    );
  }

  bool _handleColorTap(_GameItem targetItem, Color? color) {
    if (color == null) return false;

    // Helper comparison
    bool match = false;
    if (targetItem.color == Colors.lightBlue.shade400 && color == Colors.lightBlue.shade400) match = true;
    if (targetItem.color == Colors.lightGreen.shade400 && color == Colors.lightGreen.shade400) match = true;
    if (targetItem.color == Colors.amber.shade400 && color == Colors.amber.shade400) match = true;
    
    // Check custom standard matching
    if (targetItem.color.value == color.value) match = true;

    if (match) {
      setState(() {
        matchedIds.add(targetItem.id);
      });
      SoundService.playSuccess();
      HapticService.success();
      
      if (matchedIds.length == targets.length) {
        _onLevelComplete();
      }
      return true;
    } else {
      SoundService.playError();
      HapticFeedback.lightImpact();
      return false;
    }
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
              
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: targets.length,
                        itemBuilder: (context, index) {
                          final target = targets[index];
                          final isMatched = matchedIds.contains(target.id);
                          
                          return _TargetCard(
                            target: target,
                            isMatched: isMatched,
                            selectedColor: selectedColor,
                            onColorSubmitted: (color) => _handleColorTap(target, color),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom control area
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
            children: _availableColors.map((color) {
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
                    width: 50,
                    height: 50,
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
          const SizedBox(height: 16),
          // Symmetric Reset Button
          TextButton.icon(
            onPressed: _initLevel,
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
          const Icon(Icons.touch_app_rounded, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Pilih warna di bawah, lalu lengkapi bentuk yang sesuai!',
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
}

class _TargetCard extends StatefulWidget {
  final _GameItem target;
  final bool isMatched;
  final Color? selectedColor;
  final Function(Color?) onColorSubmitted;

  const _TargetCard({
    required this.target,
    required this.isMatched,
    required this.selectedColor,
    required this.onColorSubmitted,
  });

  @override
  State<_TargetCard> createState() => _TargetCardState();
}

class _TargetCardState extends State<_TargetCard> with SingleTickerProviderStateMixin {
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
    return GestureDetector(
      onTap: () {
        if (widget.isMatched) return;
        bool correct = widget.onColorSubmitted(widget.selectedColor);
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
            color: widget.target.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.target.color.withOpacity(0.3),
                blurRadius: widget.isMatched ? 4 : 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: widget.isMatched
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, val, child) {
                      return Transform.scale(
                        scale: val,
                        child: _ShapePainterWidget(
                          type: widget.target.shape, 
                          color: widget.target.color,
                          size: 50,
                        ),
                      );
                    },
                  )
                : _ShapePainterWidget(
                    type: widget.target.shape,
                    color: Colors.white,
                    size: 50,
                    isDashed: true,
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
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
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
        path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * 0.15, size.width, size.height * 0.7), const Radius.circular(8)));
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
      
      // Bubbly Top-left highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromLTWH(size.width * 0.15, size.height * 0.15, size.width * 0.25, size.height * 0.25),
        highlightPaint,
      );
    } else {
      // 1. White transparent fill inside target hole
      final fillPaint = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // 2. Dashed path
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
