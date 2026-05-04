import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
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
    _ShapeData(Icons.rectangle, Colors.green, 'Persegi Panjang'),
    _ShapeData(Icons.star, Colors.purple, 'Bintang'),
  ];

  late List<_ShapeData> targetOrder;
  Map<int, bool> matched = {};
  List<_Connection> connections = [];
  
  Offset? currentDragStart;
  Offset? currentDragEnd;
  int? activeDragIndex;

  final Map<int, GlobalKey> startKeys = {};
  final Map<int, GlobalKey> endKeys = {};

  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    targetOrder = List.from(shapes)..shuffle();
    for (int i = 0; i < shapes.length; i++) {
      startKeys[i] = GlobalKey();
      endKeys[i] = GlobalKey();
      matched[i] = false;
    }
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

  void _handleDragStart(int index, Offset pos) {
    if (matched[index]!) return;
    setState(() {
      activeDragIndex = index;
      currentDragStart = pos;
      currentDragEnd = pos;
    });
    HapticService.light();
  }

  void _handleDragUpdate(Offset pos) {
    if (activeDragIndex == null) return;
    setState(() => currentDragEnd = pos);
  }

  void _handleDragEnd(Offset pos) {
    if (activeDragIndex == null) return;

    int? hitIndex;
    for (var entry in endKeys.entries) {
      final RenderBox? box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final boxPos = box.localToGlobal(Offset.zero);
        final size = box.size;
        if (Rect.fromLTWH(boxPos.dx, boxPos.dy, size.width, size.height).contains(pos)) {
          // Check if it's the correct shape (we use targetOrder for mapping)
          if (targetOrder[entry.key].icon == shapes[activeDragIndex!].icon) {
            hitIndex = entry.key;
          }
          break;
        }
      }
    }

    if (hitIndex != null) {
      final RenderBox startBox = startKeys[activeDragIndex!]!.currentContext!.findRenderObject() as RenderBox;
      final RenderBox endBox = endKeys[hitIndex]!.currentContext!.findRenderObject() as RenderBox;
      
      setState(() {
        matched[activeDragIndex!] = true;
        connections.add(_Connection(
          color: shapes[activeDragIndex!].color,
          start: startBox.localToGlobal(Offset(startBox.size.width / 2, startBox.size.height / 2)),
          end: endBox.localToGlobal(Offset(endBox.size.width / 2, endBox.size.height / 2)),
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Cocokkan Bentuk', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          body: Stack(
            children: [
              Positioned(
                top: 0, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Hubungkan dua bentuk yang sama!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                ),
              ),

              // Lines Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: _LinePainter(
                    connections: connections,
                    activeStart: currentDragStart,
                    activeEnd: currentDragEnd,
                    activeColor: activeDragIndex != null ? shapes[activeDragIndex!].color : null,
                    context: context,
                  ),
                ),
              ),

              // Objects Layer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(shapes.length, (i) => _buildItem(i, true)),
                    ),
                    // Right Column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(targetOrder.length, (i) => _buildItem(i, false)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isComplete) const IgnorePointer(child: _ConfettiOverlay()),
      ],
    );
  }

  Widget _buildItem(int index, bool isLeft) {
    final data = isLeft ? shapes[index] : targetOrder[index];
    final key = isLeft ? startKeys[index] : endKeys[index];
    final bool isMatched = isLeft ? matched[index]! : connections.any((c) => c.color == data.color);

    return GestureDetector(
      onPanStart: isLeft ? (d) => _handleDragStart(index, d.globalPosition) : null,
      onPanUpdate: isLeft ? (d) => _handleDragUpdate(d.globalPosition) : null,
      onPanEnd: isLeft ? (d) => _handleDragEnd(d.globalPosition) : null,
      child: Column(
        children: [
          Container(
            key: key,
            width: 65, height: 65,
            decoration: BoxDecoration(
              color: isMatched ? data.color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isMatched ? data.color : Colors.grey.shade200, width: 2),
            ),
            child: Icon(data.icon, color: data.color, size: 35),
          ),
          if (isMatched && isLeft) 
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
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
  final BuildContext context;

  _LinePainter({required this.connections, this.activeStart, this.activeEnd, this.activeColor, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final canvasOffset = renderBox.localToGlobal(Offset.zero);

    for (var conn in connections) {
      paint.color = conn.color.withOpacity(0.6);
      canvas.drawLine(conn.start - canvasOffset, conn.end - canvasOffset, paint);
      canvas.drawCircle(conn.start - canvasOffset, 5, paint..style = PaintingStyle.fill);
      canvas.drawCircle(conn.end - canvasOffset, 5, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }

    if (activeStart != null && activeEnd != null && activeColor != null) {
      paint.color = activeColor!.withOpacity(0.3);
      paint.strokeWidth = 6;
      canvas.drawLine(activeStart! - canvasOffset, activeEnd! - canvasOffset, paint);
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
