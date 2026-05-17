import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/widgets/level_up_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

class CompositionMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const CompositionMatchingScreen({super.key, this.levelId = 13});

  @override
  ConsumerState<CompositionMatchingScreen> createState() => _CompositionMatchingScreenState();
}

class _CompositionMatchingScreenState extends ConsumerState<CompositionMatchingScreen> {
  late ConfettiController _confettiController;
  final List<_CompositionData> items = [
    _CompositionData(
      id: 0,
      outerShape: _ShapeType.square,
      outerColor: Colors.blue,
      innerShape: _ShapeType.circle,
      innerColor: Colors.red,
    ),
    _CompositionData(
      id: 1,
      outerShape: _ShapeType.circle,
      outerColor: Colors.green,
      innerShape: _ShapeType.hexagon,
      innerColor: Colors.yellow.shade700,
    ),
    _CompositionData(
      id: 2,
      outerShape: _ShapeType.square,
      outerColor: Colors.purple,
      innerShape: _ShapeType.circle,
      innerColor: Colors.lightGreen,
    ),
    _CompositionData(
      id: 3,
      outerShape: _ShapeType.hexagon,
      outerColor: Colors.yellow.shade700,
      innerShape: _ShapeType.hexagon,
      innerColor: Colors.pink,
    ),
  ];

  late List<_CompositionData> leftItems;
  late List<_CompositionData> rightItems;
  Map<int, bool> matched = {};
  List<_Connection> connections = [];
  
  Offset? currentDragStart;
  Offset? currentDragEnd;
  int? activeDragId;

  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _resetLevel();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _resetLevel() {
    leftItems = List.from(items);
    rightItems = List.from(items)..shuffle();
    matched = {for (var item in items) item.id: false};
    connections = [];
    _isComplete = false;
  }

  void _onLevelComplete() async {
    HapticService.success();
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    // Tahap 1: Perayaan Visual
    _confettiController.play();

    // Tahap 2: Delay & Sound
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Tahap 3: Apresiasi & Level Up
    setState(() => _isComplete = true);
  }

  Offset _getItemCenter(int index, bool isLeft, Size areaSize) {
    double x = isLeft ? 80 : areaSize.width - 80;
    double segmentHeight = areaSize.height / items.length;
    double y = (index + 0.5) * segmentHeight;
    return Offset(x, y);
  }

  void _handleDragStart(Offset localPos, Size areaSize) {
    for (int i = 0; i < leftItems.length; i++) {
      final item = leftItems[i];
      if (matched[item.id]!) continue;
      
      final center = _getItemCenter(i, true, areaSize);
      // Hit area for the blue node
      final nodePos = Offset(center.dx + 45, center.dy);
      if ((localPos - nodePos).distance < 40) {
        setState(() {
          activeDragId = item.id;
          currentDragStart = nodePos;
          currentDragEnd = localPos;
        });
        HapticService.light();
        return;
      }
    }
  }

  void _handleDragUpdate(Offset localPos) {
    if (activeDragId == null) return;
    setState(() => currentDragEnd = localPos);
  }

  void _handleDragEnd(Offset localPos, Size areaSize) {
    if (activeDragId == null) return;

    int? hitIndex;
    for (int i = 0; i < rightItems.length; i++) {
      final center = _getItemCenter(i, false, areaSize);
      final nodePos = Offset(center.dx - 45, center.dy);
      if ((localPos - nodePos).distance < 40) {
        if (rightItems[i].id == activeDragId) {
          hitIndex = i;
        }
        break;
      }
    }

    if (hitIndex != null) {
      setState(() {
        matched[activeDragId!] = true;
        final targetCenter = _getItemCenter(hitIndex!, false, areaSize);
        connections.add(_Connection(
          color: Colors.blue.shade700,
          start: currentDragStart!,
          end: Offset(targetCenter.dx - 45, targetCenter.dy),
        ));
      });
      HapticService.success();
      if (matched.values.every((v) => v)) _onLevelComplete();
    } else {
      HapticService.failure();
    }

    setState(() {
      activeDragId = null;
      currentDragStart = null;
      currentDragEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Light blue background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final areaSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onPanStart: (d) => _handleDragStart(d.localPosition, areaSize),
                    onPanUpdate: (d) => _handleDragUpdate(d.localPosition),
                    onPanEnd: (d) => _handleDragEnd(d.localPosition, areaSize),
                    child: Stack(
                      children: [
                        Container(color: Colors.transparent),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LinePainter(
                              connections: connections,
                              activeStart: currentDragStart,
                              activeEnd: currentDragEnd,
                            ),
                          ),
                        ),

                        // Left Column (Composite Shapes)
                        ...List.generate(leftItems.length, (i) {
                          final center = _getItemCenter(i, true, areaSize);
                          return Positioned(
                            left: center.dx - 40,
                            top: center.dy - 40,
                            child: _buildCompositeItem(leftItems[i], true),
                          );
                        }),

                        // Right Column (Separated Components)
                        ...List.generate(rightItems.length, (i) {
                          final center = _getItemCenter(i, false, areaSize);
                          return Positioned(
                            left: center.dx - 60,
                            top: center.dy - 40,
                            child: _buildCompositionItem(rightItems[i], false),
                          );
                        }),

                        if (_isComplete) 
                          LevelUpOverlay(
                            title: 'Luar Biasa!',
                            message: 'Kamu Ahli Komposisi!',
                            nextRoute: '/level_14',
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
                  );
                },
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
              'Level 13',
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Text(
        'Hubungkan gambar dengan komposisi penyusunnya!',
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildCompositeItem(_CompositionData data, bool isLeft) {
    bool isItemMatched = matched[data.id]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            border: Border.all(
              color: isItemMatched ? Colors.green : Colors.transparent,
              width: 3,
            ),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ShapeWidget(type: data.outerShape, color: data.outerColor, size: 60),
                _ShapeWidget(type: data.innerShape, color: data.innerColor, size: 25),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildNode(isItemMatched),
      ],
    );
  }

  Widget _buildCompositionItem(_CompositionData data, bool isLeft) {
    bool isItemMatched = connections.any((c) => rightItems.indexWhere((ri) => ri.id == data.id) != -1 && c.end.dx > 200); // Simple logic to check if this right item is matched
    // Better logic:
    bool isRightMatched = matched[data.id]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNode(isRightMatched),
        const SizedBox(width: 10),
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            border: Border.all(
              color: isRightMatched ? Colors.green : Colors.transparent,
              width: 3,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShapeWidget(type: data.innerShape, color: data.innerColor, size: 30),
              _ShapeWidget(type: data.outerShape, color: data.outerColor, size: 35),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNode(bool isMatched) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: isMatched ? Colors.green : Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
      ),
    );
  }
}

enum _ShapeType { circle, square, hexagon }

class _CompositionData {
  final int id;
  final _ShapeType outerShape;
  final Color outerColor;
  final _ShapeType innerShape;
  final Color innerColor;

  _CompositionData({
    required this.id,
    required this.outerShape,
    required this.outerColor,
    required this.innerShape,
    required this.innerColor,
  });
}

class _ShapeWidget extends StatelessWidget {
  final _ShapeType type;
  final Color color;
  final double size;

  const _ShapeWidget({required this.type, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShapePainter(type: type, color: color),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final _ShapeType type;
  final Color color;

  _ShapePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    switch (type) {
      case _ShapeType.circle:
        canvas.drawCircle(center, size.width / 2, paint);
        break;
      case _ShapeType.square:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case _ShapeType.hexagon:
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
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Connection {
  final Color color;
  final Offset start;
  final Offset end;
  _Connection({required this.color, required this.start, required this.end});
}

class _LinePainter extends CustomPainter {
  final List<_Connection> connections;
  final Offset? activeStart;
  final Offset? activeEnd;

  _LinePainter({required this.connections, this.activeStart, this.activeEnd});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw permanent connections
    for (var conn in connections) {
      paint.color = Colors.green.shade600;
      canvas.drawLine(conn.start, conn.end, paint);
    }

    // Draw active drag line
    if (activeStart != null && activeEnd != null) {
      paint.color = Colors.blue.withOpacity(0.6);
      paint.strokeWidth = 4.0;
      canvas.drawLine(activeStart!, activeEnd!, paint);
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
