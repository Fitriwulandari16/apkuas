import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

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

  final Map<Color, GlobalKey> startKeys = {};
  final Map<Color, GlobalKey> endKeys = {};

  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    targetColors = List.from(flowerColors)..shuffle();
    for (var color in flowerColors) {
      startKeys[color] = GlobalKey();
      endKeys[color] = GlobalKey();
    }
    matched = {for (var c in flowerColors) c: false};
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
          MaterialPageRoute(builder: (context) => const LevelTransitionScreen(nextLevelId: 9)),
        );
      }
    });
  }

  void _handleDragStart(Color color, Offset pos) {
    if (matched[color]!) return;
    setState(() {
      activeDragColor = color;
      currentDragStart = pos;
      currentDragEnd = pos;
    });
    HapticService.light();
  }

  void _handleDragUpdate(Offset pos) {
    if (activeDragColor == null) return;
    setState(() => currentDragEnd = pos);
  }

  void _handleDragEnd(Offset pos) {
    if (activeDragColor == null) return;

    Color? hitColor;
    for (var entry in endKeys.entries) {
      final RenderBox? box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final boxPos = box.localToGlobal(Offset.zero);
        final size = box.size;
        if (Rect.fromLTWH(boxPos.dx, boxPos.dy, size.width, size.height).contains(pos)) {
          hitColor = entry.key;
          break;
        }
      }
    }

    if (hitColor != null && hitColor == activeDragColor) {
      final RenderBox startBox = startKeys[activeDragColor!]!.currentContext!.findRenderObject() as RenderBox;
      final RenderBox endBox = endKeys[hitColor]!.currentContext!.findRenderObject() as RenderBox;
      
      setState(() {
        matched[activeDragColor!] = true;
        connections.add(_Connection(
          color: activeDragColor!,
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
      activeDragColor = null;
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
            title: const Text('Cocokkan Warna Bunga', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
          ),
          body: Stack(
            children: [
              // Legend/Instruction
              Positioned(
                top: 0, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Hubungkan Bunga ke Penyiram yang warnanya sama!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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
                    activeColor: activeDragColor,
                    context: context,
                  ),
                ),
              ),

              // Objects Layer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flowers
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: flowerColors.map((color) => _buildItem(color, true)).toList(),
                    ),
                    // Watering Cans
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: targetColors.map((color) => _buildItem(color, false)).toList(),
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

  Widget _buildItem(Color color, bool isStart) {
    return GestureDetector(
      onPanStart: isStart ? (d) => _handleDragStart(color, d.globalPosition) : null,
      onPanUpdate: isStart ? (d) => _handleDragUpdate(d.globalPosition) : null,
      onPanEnd: isStart ? (d) => _handleDragEnd(d.globalPosition) : null,
      child: Column(
        children: [
          Container(
            key: isStart ? startKeys[color] : endKeys[color],
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
              border: Border.all(color: matched[color]! ? color : Colors.grey.shade200, width: 3),
            ),
            child: Icon(
              isStart ? Icons.local_florist_rounded : Icons.opacity_rounded,
              color: color, size: 40,
            ),
          ),
          const SizedBox(height: 4),
          if (matched[color]! && isStart) 
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
        ],
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
  final BuildContext context;

  _LinePainter({required this.connections, this.activeStart, this.activeEnd, this.activeColor, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final canvasOffset = renderBox.localToGlobal(Offset.zero);

    for (var conn in connections) {
      paint.color = conn.color.withOpacity(0.8);
      canvas.drawLine(conn.start - canvasOffset, conn.end - canvasOffset, paint);
      // Draw end circles
      canvas.drawCircle(conn.start - canvasOffset, 6, paint..style = PaintingStyle.fill);
      canvas.drawCircle(conn.end - canvasOffset, 6, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }

    if (activeStart != null && activeEnd != null && activeColor != null) {
      paint.color = activeColor!.withOpacity(0.4);
      paint.strokeWidth = 8;
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
