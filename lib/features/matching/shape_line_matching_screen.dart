import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

class ShapeLineMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ShapeLineMatchingScreen({super.key, this.levelId = 9});

  @override
  ConsumerState<ShapeLineMatchingScreen> createState() => _ShapeLineMatchingScreenState();
}

class _ShapeLineMatchingScreenState extends ConsumerState<ShapeLineMatchingScreen> {
  final List<_ShapeData> shapes = [
    _ShapeData(Icons.square, Colors.red, 'Kotak'),
    _ShapeData(Icons.circle, Colors.yellow.shade700, 'Lingkaran'),
    _ShapeData(Icons.change_history, Colors.blue, 'Segitiga'),
    _ShapeData(Icons.favorite, Colors.pink, 'Hati'),
    _ShapeData(Icons.rectangle, Colors.green, 'Persegi'),
    _ShapeData(Icons.star, Colors.purple, 'Bintang'),
  ];

  late List<_ShapeData> targetOrder;
  Map<int, bool> matched = {};
  List<_Connection> connections = [];
  
  Offset? currentDragStart;
  Offset? currentDragEnd;
  int? activeDragIndex;

  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    targetOrder = List.from(shapes)..shuffle();
    matched = {for (int i = 0; i < shapes.length; i++) i: false};
    connections = [];
    _isComplete = false;
  }

  void _onLevelComplete() {
    setState(() => _isComplete = true);
    HapticService.success();
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LevelTransitionScreen(nextLevelId: 10)),
        );
      }
    });
  }

  Offset _getItemCenter(int index, bool isLeft, Size areaSize) {
    double x = isLeft ? 100 : areaSize.width - 100;
    double segmentHeight = areaSize.height / shapes.length;
    double y = (index + 0.5) * segmentHeight;
    return Offset(x, y);
  }

  void _handleDragStart(Offset localPos, Size areaSize) {
    for (int i = 0; i < shapes.length; i++) {
      if (matched[i]!) continue;
      final center = _getItemCenter(i, true, areaSize);
      if ((localPos - center).distance < 50) {
        setState(() {
          activeDragIndex = i;
          currentDragStart = center;
          currentDragEnd = localPos;
        });
        HapticService.light();
        return;
      }
    }
  }

  void _handleDragUpdate(Offset localPos) {
    if (activeDragIndex == null) return;
    setState(() => currentDragEnd = localPos);
  }

  void _handleDragEnd(Offset localPos, Size areaSize) {
    if (activeDragIndex == null) return;

    int? hitIndex;
    for (int i = 0; i < targetOrder.length; i++) {
      final center = _getItemCenter(i, false, areaSize);
      if ((localPos - center).distance < 50) {
        if (targetOrder[i].icon == shapes[activeDragIndex!].icon) {
          hitIndex = i;
        }
        break;
      }
    }

    if (hitIndex != null) {
      setState(() {
        matched[activeDragIndex!] = true;
        connections.add(_Connection(
          color: shapes[activeDragIndex!].color,
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
      activeDragIndex = null;
      currentDragStart = null;
      currentDragEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = matched.values.where((v) => v).length / shapes.length;

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
                        Container(color: Colors.transparent),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LinePainter(
                              connections: connections,
                              activeStart: currentDragStart,
                              activeEnd: currentDragEnd,
                              activeColor: activeDragIndex != null ? shapes[activeDragIndex!].color : null,
                            ),
                          ),
                        ),

                        // Left Column
                        ...List.generate(shapes.length, (i) {
                          final center = _getItemCenter(i, true, areaSize);
                          return Positioned(
                            left: center.dx - 85,
                            top: center.dy - 32,
                            child: _buildVisualItem(shapes[i], true, matched[i]!),
                          );
                        }),

                        // Right Column
                        ...List.generate(targetOrder.length, (i) {
                          final center = _getItemCenter(i, false, areaSize);
                          final bool isMatched = connections.any((c) => c.color == targetOrder[i].color);
                          return Positioned(
                            left: center.dx - 12,
                            top: center.dy - 32,
                            child: _buildVisualItem(targetOrder[i], false, isMatched),
                          );
                        }),

                        if (_isComplete) const IgnorePointer(child: _ConfettiOverlay()),
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
                  'Cocokkan Bentuk',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
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
              backgroundColor: Colors.blueGrey.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: const Text('Hubungkan dua bentuk yang sama!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
      ),
    );
  }

  Widget _buildVisualItem(_ShapeData data, bool isLeft, bool isMatched) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLeft) _buildVisualAnchor(data.color),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: isMatched ? data.color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isMatched ? data.color : Colors.grey.shade200, width: 3),
            boxShadow: [
              BoxShadow(
                color: isMatched ? data.color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                blurRadius: isMatched ? 15 : 5,
              )
            ],
          ),
          child: Icon(data.icon, color: data.color, size: 32),
        ),
        if (isLeft) _buildVisualAnchor(data.color),
      ],
    );
  }

  Widget _buildVisualAnchor(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 10, height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _ShapeData {
  final IconData icon; final Color color; final String name;
  _ShapeData(this.icon, this.color, this.name);
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
    final paint = Paint()..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    for (var conn in connections) {
      paint.color = conn.color;
      canvas.drawLine(conn.start, conn.end, paint);
      
      final dotPaint = Paint()..color = conn.color..style = PaintingStyle.fill;
      canvas.drawCircle(conn.start, 4, dotPaint);
      canvas.drawCircle(conn.end, 4, dotPaint);
    }

    if (activeStart != null && activeEnd != null && activeColor != null) {
      paint.color = activeColor!.withOpacity(0.4);
      paint.strokeWidth = 3;
      canvas.drawLine(activeStart!, activeEnd!, paint);
      canvas.drawCircle(activeStart!, 5, Paint()..color = activeColor!..style = PaintingStyle.fill);
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();
  @override State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { return AnimatedBuilder(animation: _controller, builder: (context, child) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(progress: _controller.value))); }
}

class _ConfettiPainter extends CustomPainter {
  final double progress; _ConfettiPainter({required this.progress});
  @override void paint(Canvas canvas, Size size) {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.pink, Colors.orange];
    for (int i = 0; i < 60; i++) {
      final paint = Paint()..color = colors[i % colors.length].withOpacity(1.0 - progress);
      canvas.drawRect(Rect.fromLTWH((i * 137.5 % 1.0) * size.width, progress * size.height * (1.0 + (i % 8) / 10.0) - 100, 12, 12), paint);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
