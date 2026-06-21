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

  bool _handleShapeDrop(_GameItem targetItem, ShapeType shapeType) {
    if (targetItem.shape == shapeType) {
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
                            onShapeDropped: (shape) => _handleShapeDrop(target, shape),
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
          // White rounded pill-shape Shape Palette card (horizontal centered)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: _availableShapes.map((shapeType) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Draggable<ShapeType>(
                    data: shapeType,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.8,
                        child: _ShapePainterWidget(
                          type: shapeType,
                          color: CilikTheme.tealTua,
                          size: 50,
                          isDashed: true,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: _ShapePainterWidget(
                        type: shapeType,
                        color: Colors.grey.shade400,
                        size: 40,
                        isDashed: true,
                      ),
                    ),
                    child: _ShapePainterWidget(
                      type: shapeType,
                      color: CilikTheme.tealTua,
                      size: 40,
                      isDashed: true,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Symmetric Reset Button
          TextButton.icon(
            onPressed: _initLevel,
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueGrey, size: 20),
            label: Text(
              'Ulangi',
              style: GoogleFonts.fredoka(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
          const Icon(Icons.gesture_rounded, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Tarik bentuk di bawah ke pasangan yang sesuai!',
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
  final Function(ShapeType) onShapeDropped;

  const _TargetCard({
    required this.target,
    required this.isMatched,
    required this.onShapeDropped,
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
    return DragTarget<ShapeType>(
      onWillAccept: (data) => !widget.isMatched,
      onAccept: (data) {
        bool correct = widget.onShapeDropped(data);
        if (!correct) {
          _shakeController.forward(from: 0);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final double offset = math.sin(_shakeController.value * math.pi * 4) * 8 * (1 - _shakeController.value);
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.target.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHovering ? Colors.white : Colors.transparent,
                width: 3.0,
              ),
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
                            color: Colors.white,
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
        );
      },
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
