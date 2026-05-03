import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

class MatchingBalloonScreen extends ConsumerStatefulWidget {
  final int levelId;
  const MatchingBalloonScreen({super.key, this.levelId = 3});

  @override
  ConsumerState<MatchingBalloonScreen> createState() => _MatchingBalloonScreenState();
}

class _MatchingBalloonScreenState extends ConsumerState<MatchingBalloonScreen> {
  late List<Color> startGroup;
  late List<Color> endGroup;
  Map<Color, bool> matchedColors = {};
  
  Offset? currentDragStart;
  Offset? currentDragEnd;
  Color? activeDragColor;
  List<_Connection> connections = [];

  final Map<Color, GlobalKey> startKeys = {};
  final Map<Color, GlobalKey> endKeys = {};

  bool isLevelComplete = false;

  @override
  void initState() { super.initState(); _resetGame(); }

  void _resetGame() {
    List<Color> colors = [const Color(0xFFFFD700), const Color(0xFFFF69B4), const Color(0xFF32CD32), const Color(0xFF1E90FF), const Color(0xFFFF4500)];
    startKeys.clear(); endKeys.clear();
    for (var color in colors) { startKeys[color] = GlobalKey(); endKeys[color] = GlobalKey(); }
    setState(() {
      startGroup = List.from(colors); endGroup = List.from(colors)..shuffle();
      matchedColors = {for (var color in colors) color: false};
      connections = []; currentDragStart = null; currentDragEnd = null; activeDragColor = null; isLevelComplete = false;
    });
  }

  void _onLevelComplete() {
    setState(() => isLevelComplete = true);
    HapticService.success();
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) _showWinDialog(); });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('HEBAT! 🎈', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
        content: const Text('Level 3 Selesai! Kamu sangat pintar mencocokkan warna!', textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LevelTransitionScreen(nextLevelId: 4)));
              },
              child: const Text('LANJUT KE LEVEL 4', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDragStart(Color color, Offset globalPos) {
    if (matchedColors[color]!) return;
    setState(() { activeDragColor = color; currentDragStart = globalPos; currentDragEnd = globalPos; });
    HapticService.light();
  }

  void _handleDragUpdate(Offset globalPos) { if (activeDragColor == null) return; setState(() => currentDragEnd = globalPos); }

  void _handleDragEnd(Offset globalPos) {
    if (activeDragColor == null) return;
    Color? hitColor;
    for (var entry in endKeys.entries) {
      final RenderBox? box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero); final size = box.size;
        if (Rect.fromLTWH(position.dx, position.dy, size.width, size.height).contains(globalPos)) { hitColor = entry.key; break; }
      }
    }
    if (hitColor != null && hitColor == activeDragColor) {
      final RenderBox startBox = startKeys[activeDragColor!]!.currentContext!.findRenderObject() as RenderBox;
      final RenderBox endBox = endKeys[hitColor]!.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        matchedColors[activeDragColor!] = true;
        connections.add(_Connection(color: activeDragColor!, start: startBox.localToGlobal(Offset(startBox.size.width/2, startBox.size.height/2)), end: endBox.localToGlobal(Offset(endBox.size.width/2, endBox.size.height/2))));
      });
      HapticService.success();
      if (matchedColors.values.every((v) => v == true)) _onLevelComplete();
    }
    setState(() { activeDragColor = null; currentDragStart = null; currentDragEnd = null; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Cocokkan Balon', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), centerTitle: true),
      body: Stack(
        children: [
          Positioned(top: 10, left: 24, child: Row(children: [const Icon(Icons.star, color: Colors.orangeAccent, size: 20), const SizedBox(width: 8), Text('Hubungkan warna yang sama', style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.w600))])),
          Positioned.fill(child: LayoutBuilder(builder: (context, constraints) => CustomPaint(painter: _ConnectionPainter(activeStart: currentDragStart, activeEnd: currentDragEnd, activeColor: activeDragColor, connections: connections, context: context)))),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 60),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: startGroup.map((color) => _buildItem(color, true)).toList()),
              const Spacer(),
              Padding(padding: const EdgeInsets.only(bottom: 80), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: endGroup.map((color) => _buildItem(color, false)).toList())),
            ],
          ),
          if (isLevelComplete) const IgnorePointer(child: _ConfettiOverlay()),
        ],
      ),
    );
  }

  Widget _buildItem(Color color, bool isStart) {
    final key = isStart ? startKeys[color]! : endKeys[color]!;
    return GestureDetector(
      key: key,
      onPanStart: isStart ? (details) => _handleDragStart(color, details.globalPosition) : null,
      onPanUpdate: isStart ? (details) => _handleDragUpdate(details.globalPosition) : null,
      onPanEnd: isStart ? (details) => _handleDragEnd(details.globalPosition) : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (!isStart) Container(width: 2, height: 15, color: Colors.black12),
        Container(width: 60, height: 75, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.all(Radius.elliptical(30, 37)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 4))])),
        if (isStart) Container(width: 2, height: 15, color: Colors.black12),
      ]),
    );
  }
}

class _Connection { final Color color; final Offset start; final Offset end; _Connection({required this.color, required this.start, required this.end}); }
class _ConnectionPainter extends CustomPainter {
  final Offset? activeStart; final Offset? activeEnd; final Color? activeColor; final List<_Connection> connections; final BuildContext context;
  _ConnectionPainter({this.activeStart, this.activeEnd, this.activeColor, required this.connections, required this.context});
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final RenderBox renderBox = context.findRenderObject() as RenderBox; final canvasOffset = renderBox.localToGlobal(Offset.zero);
    for (var conn in connections) { paint.color = Colors.black54; canvas.drawLine(conn.start - canvasOffset, conn.end - canvasOffset, paint); }
    if (activeStart != null && activeEnd != null && activeColor != null) { paint.color = activeColor!.withOpacity(0.5); paint.strokeWidth = 5; canvas.drawLine(activeStart! - canvasOffset, activeEnd! - canvasOffset, paint); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ConfettiOverlay extends StatefulWidget { const _ConfettiOverlay(); @override State<_ConfettiOverlay> createState() => _ConfettiOverlayState(); }
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
