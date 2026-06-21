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
  final String colorName;
  final Color cardColor;

  _GameItem({
    required this.id,
    required this.shape,
    required this.colorName,
    required this.cardColor,
  });
}

class _ShapeColorMatchingScreenState extends ConsumerState<ShapeColorMatchingScreen> {
  late List<_GameItem> targets;
  Set<int> matchedIds = {};
  List<String> draggables = [];

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    setState(() {
      matchedIds.clear();
      
      // Fixed targets matching the screenshot:
      // Row 1: Yellow Trapezoid, Yellow Triangle, Green Rhombus
      // Row 2: Blue Circle, Blue Triangle, Green Circle
      targets = [
        _GameItem(id: 1, shape: ShapeType.trapezoid, colorName: 'yellow', cardColor: const Color(0xFFFFB300)),
        _GameItem(id: 2, shape: ShapeType.triangle, colorName: 'yellow', cardColor: const Color(0xFFFFB300)),
        _GameItem(id: 3, shape: ShapeType.rhombus, colorName: 'green', cardColor: const Color(0xFF81C784)),
        _GameItem(id: 4, shape: ShapeType.circle, colorName: 'blue', cardColor: const Color(0xFF29B6F6)),
        _GameItem(id: 5, shape: ShapeType.triangle, colorName: 'blue', cardColor: const Color(0xFF29B6F6)),
        _GameItem(id: 6, shape: ShapeType.circle, colorName: 'green', cardColor: const Color(0xFF81C784)),
      ];

      // Solid draggable shapes matching the targets
      draggables = [
        'rhombus_green',
        'circle_green',
        'trapezoid_yellow',
        'circle_blue',
        'triangle_blue',
        'triangle_yellow',
      ];
      draggables.shuffle(); // Shuffled for engaging play
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

  bool _handleShapeDrop(_GameItem targetItem, String droppedKey) {
    final shapeName = targetItem.shape.toString().split('.').last;
    final expectedKey = "${shapeName}_${targetItem.colorName}";
    if (expectedKey == droppedKey) {
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

  ShapeType _getShapeType(String key) {
    if (key.startsWith('rhombus')) return ShapeType.rhombus;
    if (key.startsWith('circle')) return ShapeType.circle;
    if (key.startsWith('trapezoid')) return ShapeType.trapezoid;
    if (key.startsWith('triangle')) return ShapeType.triangle;
    return ShapeType.circle;
  }

  Color _getColor(String key) {
    if (key.endsWith('green')) return const Color(0xFF81C784);
    if (key.endsWith('yellow')) return const Color(0xFFFFB300);
    if (key.endsWith('blue')) return const Color(0xFF29B6F6);
    return Colors.grey;
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
                            onShapeDropped: (shapeKey) => _handleShapeDrop(target, shapeKey),
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
          // White rounded container holding the solid shape draggables
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 16,
              children: draggables.map((itemKey) {
                final shapeType = _getShapeType(itemKey);
                final color = _getColor(itemKey);
                
                return Draggable<String>(
                  data: itemKey,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      child: _ShapePainterWidget(
                        type: shapeType,
                        color: color,
                        size: 60,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _ShapePainterWidget(
                      type: shapeType,
                      color: color,
                      size: 50,
                    ),
                  ),
                  child: _ShapePainterWidget(
                    type: shapeType,
                    color: color,
                    size: 50,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Symmetric Reset Button explicitly centered
          Center(
            child: TextButton.icon(
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
              'Tarik dan tempelkan pada bentuk yang tepat!',
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
  final Function(String) onShapeDropped;

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
    return DragTarget<String>(
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
              color: widget.target.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHovering ? Colors.white : Colors.transparent,
                width: 3.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.target.cardColor.withOpacity(0.3),
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
