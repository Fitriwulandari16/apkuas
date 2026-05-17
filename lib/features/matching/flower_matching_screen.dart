import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';

class FlowerMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const FlowerMatchingScreen({super.key, this.levelId = 8});

  @override
  ConsumerState<FlowerMatchingScreen> createState() => _FlowerMatchingScreenState();
}

class _FlowerMatchingScreenState extends ConsumerState<FlowerMatchingScreen> {
  final List<Color> flowerColors = [
    Colors.red,
    Colors.yellow.shade700,
    Colors.blue,
    Colors.green,
    Colors.pink,
  ];

  late List<Color> targetColors;
  Map<Color, bool> matched = {};
  List<_Connection> connections = [];
  
  Offset? currentDragStart;
  Offset? currentDragEnd;
  Color? activeDragColor;


  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    targetColors = List.from(flowerColors)..shuffle();
    matched = {for (var c in flowerColors) c: false};
    connections = [];
  }

  void _onLevelComplete() {
    HapticService.success();
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 9,
      title: 'HEBAT!',
      message: 'Level 8 Selesai! Kamu pandai merangkai bunga!',
    );
  }

  Offset _getItemCenter(int index, bool isLeft, Size areaSize) {
    // Exact center points for the anchors
    double x = isLeft ? 100 : areaSize.width - 100; 
    double segmentHeight = areaSize.height / flowerColors.length;
    double y = (index + 0.5) * segmentHeight;
    return Offset(x, y);
  }

  void _handleDragStart(Offset localPos, Size areaSize) {
    for (int i = 0; i < flowerColors.length; i++) {
      final color = flowerColors[i];
      if (matched[color]!) continue;
      
      final center = _getItemCenter(i, true, areaSize);
      if ((localPos - center).distance < 60) {
        setState(() {
          activeDragColor = color;
          currentDragStart = center;
          currentDragEnd = localPos;
        });
        HapticService.light();
        return;
      }
    }
  }

  void _handleDragUpdate(Offset localPos) {
    if (activeDragColor == null) return;
    setState(() => currentDragEnd = localPos);
  }

  void _handleDragEnd(Offset localPos, Size areaSize) {
    if (activeDragColor == null) return;

    int? hitIndex;
    for (int i = 0; i < targetColors.length; i++) {
      final center = _getItemCenter(i, false, areaSize);
      if ((localPos - center).distance < 60) {
        if (targetColors[i] == activeDragColor) {
          hitIndex = i;
        }
        break;
      }
    }

    if (hitIndex != null) {
      setState(() {
        matched[activeDragColor!] = true;
        connections.add(_Connection(
          color: activeDragColor!,
          start: currentDragStart!,
          end: _getItemCenter(hitIndex!, false, areaSize),
        ));
      });
      HapticService.success();
      if (matched.values.every((v) => v)) _onLevelComplete();
    } else {
      HapticService.failure();
    }

    setState(() {
      activeDragColor = null;
      currentDragStart = null;
      currentDragEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = matched.values.where((v) => v).length / flowerColors.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(progress),
            const SizedBox(height: 10),
            _buildInstruction(),
            const SizedBox(height: 10),

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
                        // Background (transparent but takes space for hits)
                        Container(color: Colors.transparent),

                        // Lines Layer
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LinePainter(
                              connections: connections,
                              activeStart: currentDragStart,
                              activeEnd: currentDragEnd,
                              activeColor: activeDragColor,
                            ),
                          ),
                        ),

                        // Left Column (Flowers)
                        ...List.generate(flowerColors.length, (i) {
                          final color = flowerColors[i];
                          final center = _getItemCenter(i, true, areaSize);
                          return Positioned(
                            left: center.dx - 85, // 70 width + 15 anchor offset
                            top: center.dy - 35,
                            child: _buildVisualItem(color, true),
                          );
                        }),

                        // Right Column (Watering Cans)
                        ...List.generate(targetColors.length, (i) {
                          final color = targetColors[i];
                          final center = _getItemCenter(i, false, areaSize);
                          return Positioned(
                            left: center.dx - 15, // Anchor starts here
                            top: center.dy - 35,
                            child: _buildVisualItem(color, false),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Cocokkan Warna Bunga',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.brown.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: const Text('Hubungkan Bunga ke Penyiram yang warnanya sama!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
      ),
    );
  }

  Widget _buildVisualItem(Color color, bool isLeft) {
    final bool isMatched = matched[color]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLeft) _buildVisualAnchor(color),
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isMatched ? 0.4 : 0.1),
                blurRadius: isMatched ? 20 : 10,
                spreadRadius: isMatched ? 5 : 0,
              )
            ],
            border: Border.all(color: isMatched ? color : Colors.grey.shade200, width: 3),
          ),
          child: Icon(
            isLeft ? Icons.local_florist_rounded : Icons.opacity_rounded,
            color: color, size: 36,
          ),
        ),
        if (isLeft) _buildVisualAnchor(color),
      ],
    );
  }

  Widget _buildVisualAnchor(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
      ),
    );
  }
}

class _Connection {
  final Color color; final Offset start; final Offset end;
  _Connection({required this.color, required this.start, required this.end});
}

class _LinePainter extends CustomPainter {
  final List<_Connection> connections;
  final Offset? activeStart; final Offset? activeEnd; final Color? activeColor;

  _LinePainter({required this.connections, this.activeStart, this.activeEnd, this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var conn in connections) {
      paint.color = conn.color;
      canvas.drawLine(conn.start, conn.end, paint);
      
      final dotPaint = Paint()..color = conn.color..style = PaintingStyle.fill;
      canvas.drawCircle(conn.start, 5, dotPaint);
      canvas.drawCircle(conn.end, 5, dotPaint);
    }

    if (activeStart != null && activeEnd != null && activeColor != null) {
      paint.color = activeColor!.withOpacity(0.5);
      paint.strokeWidth = 3.5;
      canvas.drawLine(activeStart!, activeEnd!, paint);
      canvas.drawCircle(activeStart!, 6, Paint()..color = activeColor!..style = PaintingStyle.fill);
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

