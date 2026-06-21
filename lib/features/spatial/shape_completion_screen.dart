import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class ShapeCompletionScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ShapeCompletionScreen({super.key, this.levelId = 11});

  @override
  ConsumerState<ShapeCompletionScreen> createState() => _ShapeCompletionScreenState();
}

class _ShapeCompletionScreenState extends ConsumerState<ShapeCompletionScreen> {
  final List<String> shapeIds = ['square', 'circle', 'pentagon', 'heart'];
  final List<String> draggableShapes = ['square', 'circle', 'pentagon', 'heart'];
  
  Map<String, bool> completed = {
    'square': false,
    'circle': false,
    'pentagon': false,
    'heart': false,
  };

  final Map<String, GlobalKey<_TargetShapeCardState>> cardKeys = {
    'square': GlobalKey<_TargetShapeCardState>(),
    'circle': GlobalKey<_TargetShapeCardState>(),
    'pentagon': GlobalKey<_TargetShapeCardState>(),
    'heart': GlobalKey<_TargetShapeCardState>(),
  };

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    setState(() {
      completed = {
        'square': false,
        'circle': false,
        'pentagon': false,
        'heart': false,
      };
      draggableShapes.shuffle();
    });
  }

  void _onPieceMatched(String id) {
    setState(() {
      completed[id] = true;
    });
    SoundService.playSuccess();
    HapticService.success();
    
    if (completed.values.every((v) => v)) {
      gameWin();
    }
  }

  void gameWin() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    UserService.updateProgress(widget.levelId).catchError((e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    });

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 12,
      title: 'Hebat! ✨',
      message: 'Kamu Detektif Bentuk! Semua potongan sudah terpasang.',
    );
  }

  bool _checkShapeDrop(String targetId, String droppedId) {
    bool correct = targetId == droppedId;

    if (correct) {
      _onPieceMatched(targetId);
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
        backgroundColor: const Color(0xFFF9FBFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Level ${widget.levelId}', 
            style: GoogleFonts.fredoka(color: CilikTheme.tealTua, fontWeight: FontWeight.bold, fontSize: 24)
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: CilikTheme.mintGreen.withOpacity(0.3),
                child: const Icon(Icons.person, color: CilikTheme.tealTua),
              ),
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Geser potongan ke bentuk yang tepat!',
                style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Grid target bentuk
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: shapeIds.map((id) {
                    return _TargetShapeCard(
                      key: cardKeys[id],
                      id: id,
                      isCompleted: completed[id]!,
                      onShapeDropped: (droppedId) => _checkShapeDrop(id, droppedId),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // Bottom Area with Picker & Reset
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggablePiece(String shapeId) {
    return Draggable<String>(
      data: shapeId,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomPaint(
                painter: ShapeSegmentPainter(shapeId: shapeId),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomPaint(
              painter: ShapeSegmentPainter(shapeId: shapeId),
            ),
          ),
        ),
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomPaint(
            painter: ShapeSegmentPainter(shapeId: shapeId),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row of Draggables
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: draggableShapes.map((shapeId) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: _buildDraggablePiece(shapeId),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Symmetric Reset Button centered
          Center(
            child: TextButton.icon(
              onPressed: _resetLevel,
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
}

class _TargetShapeCard extends StatefulWidget {
  final String id;
  final bool isCompleted;
  final Function(String) onShapeDropped;

  const _TargetShapeCard({
    super.key,
    required this.id,
    required this.isCompleted,
    required this.onShapeDropped,
  });

  @override
  State<_TargetShapeCard> createState() => _TargetShapeCardState();
}

class _TargetShapeCardState extends State<_TargetShapeCard> with SingleTickerProviderStateMixin {
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
      onWillAccept: (data) => !widget.isCompleted,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHovering 
                    ? Colors.blue.shade300 
                    : (widget.isCompleted ? Colors.blueGrey.shade100 : Colors.grey.shade200), 
                width: isHovering ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), 
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomPaint(
                painter: ShapeWithCutoutPainter(
                  shapeId: widget.id,
                  isCompleted: widget.isCompleted,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShapeWithCutoutPainter extends CustomPainter {
  final String shapeId;
  final bool isCompleted;

  ShapeWithCutoutPainter({required this.shapeId, required this.isCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _getGradientColors(),
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    
    final cutoutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dashPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Path shapePath = _getShapePath(size);
    
    // Draw shadow/elevation for the shape itself to look 3D
    canvas.drawPath(shapePath, Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0);

    canvas.drawPath(shapePath, paint);

    if (!isCompleted) {
      Rect cutoutRect = _getCutoutRect(size);
      canvas.drawRect(cutoutRect, cutoutPaint);
      
      // Draw dashed outline for cutout
      _drawDashedRect(canvas, cutoutRect, dashPaint);
    }

    // Bubbly top-left glossy highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.1, size.width * 0.25, size.height * 0.12),
      highlightPaint,
    );
  }

  List<Color> _getGradientColors() {
    switch (shapeId) {
      case 'square': return [const Color(0xFF81C784), const Color(0xFF388E3C)];
      case 'circle': return [const Color(0xFFFFF176), const Color(0xFFFBC02D)];
      case 'pentagon': return [const Color(0xFF64B5F6), const Color(0xFF1976D2)];
      case 'heart': return [const Color(0xFFE57373), const Color(0xFFD32F2F)];
      default: return [Colors.grey, Colors.grey];
    }
  }

  Path _getShapePath(Size size) {
    Path path = Path();
    double w = size.width;
    double h = size.height;

    switch (shapeId) {
      case 'square':
        path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(16)));
        break;
      case 'circle':
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;
      case 'pentagon':
        path.moveTo(w / 2, 0);
        path.lineTo(w, h * 0.38);
        path.lineTo(w * 0.82, h);
        path.lineTo(w * 0.18, h);
        path.lineTo(0, h * 0.38);
        path.close();
        break;
      case 'heart':
        path.moveTo(w * 0.5, h);
        path.cubicTo(w * 0.2, h * 0.7, 0, h * 0.5, 0, h * 0.3);
        path.cubicTo(0, h * 0.1, w * 0.25, 0, w * 0.5, h * 0.2);
        path.cubicTo(w * 0.75, 0, w, h * 0.1, w, h * 0.3);
        path.cubicTo(w, h * 0.5, w * 0.8, h * 0.7, w * 0.5, h);
        path.close();
        break;
    }
    return path;
  }

  Rect _getCutoutRect(Size size) {
    double s = size.width * 0.4;
    switch (shapeId) {
      case 'square': return Rect.fromLTWH(size.width - s, size.height - s, s, s);
      case 'circle': return Rect.fromLTWH(0, size.height - s, s, s);
      case 'pentagon': return Rect.fromLTWH(size.width - s, 0, s, s);
      case 'heart': return Rect.fromLTWH(0, 0, s, s);
      default: return Rect.zero;
    }
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const double dashWidth = 5;
    const double dashSpace = 3;
    
    void drawDashedLine(Offset p1, Offset p2) {
      double distance = (p1 - p2).distance;
      for (double i = 0; i < distance; i += dashWidth + dashSpace) {
        canvas.drawLine(
          Offset.lerp(p1, p2, i / distance)!,
          Offset.lerp(p1, p2, math.min(i + dashWidth, distance) / distance)!,
          paint,
        );
      }
    }

    drawDashedLine(rect.topLeft, rect.topRight);
    drawDashedLine(rect.topRight, rect.bottomRight);
    drawDashedLine(rect.bottomRight, rect.bottomLeft);
    drawDashedLine(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ShapeSegmentPainter extends CustomPainter {
  final String shapeId;

  ShapeSegmentPainter({required this.shapeId});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _getGradientColors(),
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    switch (shapeId) {
      case 'square':
        // A solid green square with slightly rounded corners (matching the target cutout portion)
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          paint,
        );
        break;

      case 'circle':
        // A yellow quarter circle (sector)
        // Curves from top-left to bottom-right, with right angle at bottom-left corner of the rect
        final path = Path()
          ..moveTo(rect.left, rect.top)
          ..arcToPoint(
            Offset(rect.right, rect.bottom),
            radius: Radius.circular(rect.width),
            clockwise: false,
          )
          ..lineTo(rect.left, rect.bottom)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case 'pentagon':
        // A blue right triangle representing the cutout portion of the pentagon
        // Vertices at: top-left (rect.left, rect.top), bottom-right (rect.right, rect.bottom), bottom-left (rect.left, rect.bottom)
        final path = Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case 'heart':
        // A red shape representing the top-left curve/lobe of the heart
        canvas.save();
        canvas.clipRect(rect);
        
        // The original heart cutout is at the top-left of a 100x100 virtual canvas: Rect.fromLTWH(0, 0, 40, 40)
        const double virtualSize = 100.0;
        const double s = 40.0; // 0.4 * virtualSize
        
        final double scaleX = rect.width / s;
        final double scaleY = rect.height / s;
        
        canvas.translate(rect.left, rect.top);
        canvas.scale(scaleX, scaleY);
        
        final heartPath = Path();
        const double w = virtualSize;
        const double h = virtualSize;
        heartPath.moveTo(w * 0.5, h);
        heartPath.cubicTo(w * 0.2, h * 0.7, 0, h * 0.5, 0, h * 0.3);
        heartPath.cubicTo(0, h * 0.1, w * 0.25, 0, w * 0.5, h * 0.2);
        heartPath.cubicTo(w * 0.75, 0, w, h * 0.1, w, h * 0.3);
        heartPath.cubicTo(w, h * 0.5, w * 0.8, h * 0.7, w * 0.5, h);
        heartPath.close();
        
        final heartPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE57373), Color(0xFFD32F2F)],
          ).createShader(Rect.fromLTWH(0, 0, virtualSize, virtualSize))
          ..style = PaintingStyle.fill;
        
        canvas.drawPath(heartPath, heartPaint);
        canvas.restore();
        break;
    }
  }

  List<Color> _getGradientColors() {
    switch (shapeId) {
      case 'square': return [const Color(0xFF81C784), const Color(0xFF388E3C)];
      case 'circle': return [const Color(0xFFFFF176), const Color(0xFFFBC02D)];
      case 'pentagon': return [const Color(0xFF64B5F6), const Color(0xFF1976D2)];
      case 'heart': return [const Color(0xFFE57373), const Color(0xFFD32F2F)];
      default: return [Colors.grey, Colors.grey];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
