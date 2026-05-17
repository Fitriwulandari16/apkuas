import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

class ShapeCompletionScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ShapeCompletionScreen({super.key, this.levelId = 11});

  @override
  ConsumerState<ShapeCompletionScreen> createState() => _ShapeCompletionScreenState();
}

class _ShapeCompletionScreenState extends ConsumerState<ShapeCompletionScreen> {
  late ConfettiController _confettiController;
  final List<String> shapeIds = ['square', 'circle', 'pentagon', 'heart'];
  late List<String> shuffledPieceIds;
  Map<String, bool> completed = {
    'square': false,
    'circle': false,
    'pentagon': false,
    'heart': false,
  };

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    shuffledPieceIds = List.from(shapeIds)..shuffle();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onPieceMatched(String id) {
    setState(() {
      completed[id] = true;
    });
    HapticService.light();
    
    if (completed.values.every((v) => v)) {
      _showWinDialog();
    }
  }

  void _showWinDialog() async {
    HapticService.success();
    
    // Tahap 1: Perayaan Visual
    _confettiController.play();

    // Tahap 2: Delay & Sound
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Tahap 3: Apresiasi & Level Up
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text('Hebat! ✨', 
          textAlign: TextAlign.center, 
          style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.bold, color: CilikTheme.tealTua)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text('Kamu Detektif Bentuk! Semua potongan sudah terpasang.', 
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 18),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(progressProvider.notifier).updateHighestLevel(12);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LevelTransitionScreen(nextLevelId: 12)),
                );
              },
              child: const Text('Lanjut ke Level 12'),
            ),
          ),
        ],
      ),
    );
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
          title: Text('Level ${widget.levelId}', 
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
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Geser potongan ke bentuk yang tepat!',
                    style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      children: shapeIds.map((id) => _buildTargetShape(id)).toList(),
                    ),
                  ),
                ),
                
                _buildBottomArea(),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2, // Straight down
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.2,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetShape(String id) {
    return DragTarget<String>(
      onWillAccept: (data) => data == id && !completed[id]!,
      onAccept: (data) => _onPieceMatched(id),
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CustomPaint(
              painter: ShapeWithCutoutPainter(
                shapeId: id,
                isCompleted: completed[id]!,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: shuffledPieceIds
            .where((id) => !completed[id]!)
            .map((id) => _buildDraggablePiece(id))
            .toList(),
      ),
    );
  }

  Widget _buildDraggablePiece(String id) {
    final size = 80.0;
    return Draggable<String>(
      data: id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: PiecePainter(shapeId: id)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: PiecePainter(shapeId: id)),
        ),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: PiecePainter(shapeId: id)),
      ),
    );
  }
}

class ShapeWithCutoutPainter extends CustomPainter {
  final String shapeId;
  final bool isCompleted;

  ShapeWithCutoutPainter({required this.shapeId, required this.isCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getColor()
      ..style = PaintingStyle.fill;
    
    final cutoutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dashPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    Path shapePath = _getShapePath(size);
    canvas.drawPath(shapePath, paint);

    if (!isCompleted) {
      Rect cutoutRect = _getCutoutRect(size);
      canvas.drawRect(cutoutRect, cutoutPaint);
      
      // Draw dashed outline for cutout
      _drawDashedRect(canvas, cutoutRect, dashPaint);
    }
  }

  Color _getColor() {
    switch (shapeId) {
      case 'square': return Colors.green;
      case 'circle': return Colors.yellow.shade700;
      case 'pentagon': return Colors.blue;
      case 'heart': return Colors.red;
      default: return Colors.grey;
    }
  }

  Path _getShapePath(Size size) {
    Path path = Path();
    double w = size.width;
    double h = size.height;

    switch (shapeId) {
      case 'square':
        path.addRect(Rect.fromLTWH(0, 0, w, h));
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

class PiecePainter extends CustomPainter {
  final String shapeId;

  PiecePainter({required this.shapeId});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getColor()
      ..style = PaintingStyle.fill;
    
    // Draw background and border for the piece box
    final bgPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    canvas.clipRRect(rrect);
    
    // The piece represents a 0.4 segment of the full shape.
    // So the full shape size should be piece_size / 0.4
    double fullWidth = size.width / 0.4;
    double fullHeight = size.height / 0.4;
    
    // Offset based on which part we are showing
    switch (shapeId) {
      case 'square': canvas.translate(-(fullWidth - size.width), -(fullHeight - size.height)); break;
      case 'circle': canvas.translate(0, -(fullHeight - size.height)); break;
      case 'pentagon': canvas.translate(-(fullWidth - size.width), 0); break;
      case 'heart': canvas.translate(0, 0); break;
    }

    Path path = _getShapePath(Size(fullWidth, fullHeight));
    canvas.drawPath(path, paint);
  }

  Color _getColor() {
    switch (shapeId) {
      case 'square': return Colors.green;
      case 'circle': return Colors.yellow.shade700;
      case 'pentagon': return Colors.blue;
      case 'heart': return Colors.red;
      default: return Colors.grey;
    }
  }

  Path _getShapePath(Size size) {
    Path path = Path();
    double w = size.width;
    double h = size.height;

    switch (shapeId) {
      case 'square':
        path.addRect(Rect.fromLTWH(0, 0, w, h));
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
