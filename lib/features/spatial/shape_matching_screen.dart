import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

class ShapeMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ShapeMatchingScreen({super.key, this.levelId = 5});

  @override
  ConsumerState<ShapeMatchingScreen> createState() => _ShapeMatchingScreenState();
}

class _ShapeMatchingScreenState extends ConsumerState<ShapeMatchingScreen> {
  final List<IconData> shapes = [Icons.square, Icons.circle, Icons.change_history];
  final List<String> names = ['Kotak', 'Lingkaran', 'Segitiga'];
  final List<Color> colors = [Colors.blue, Colors.red, Colors.green];

  late List<int> itemOrder;
  Map<int, bool> matched = {};
  bool _showCelebration = false;

  @override
  void initState() { super.initState(); itemOrder = [0, 1, 2]..shuffle(); }

  void _checkWin() {
    if (matched.length == shapes.length) {
      ref.read(progressProvider.notifier).completeLevel(widget.levelId);
      setState(() => _showCelebration = true);
      Future.delayed(const Duration(milliseconds: 1500), () { if (mounted) _showWinDialog(); });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('LUAR BIASA! 🌟', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
        content: const Text('Level 5 Selesai! Kamu sudah menguasai semua bentuk!', textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LevelTransitionScreen(nextLevelId: 6)));
              },
              child: const Text('TANTANGAN BARU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFE3F2FD),
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Cocokkan Bentuk', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Pasangkan Bentuk ke Rumahnya!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                const Spacer(),
                Column(children: List.generate(shapes.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: DragTarget<int>(
                      builder: (context, candidateData, rejectedData) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(width: 120, height: 80, decoration: BoxDecoration(color: matched.containsKey(index) ? colors[index].withOpacity(0.4) : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: colors[index], width: 2, style: matched.containsKey(index) ? BorderStyle.solid : BorderStyle.none)), child: Icon(shapes[index], color: matched.containsKey(index) ? colors[index] : Colors.grey.withOpacity(0.3), size: 50)),
                        const SizedBox(width: 20),
                        Text(names[index], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors[index])),
                      ]),
                      onWillAccept: (data) => data == index && !matched.containsKey(index),
                      onAccept: (data) { setState(() { matched[index] = true; HapticService.success(); _checkWin(); }); },
                    ),
                  );
                })),
                const Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: itemOrder.map((index) {
                  return matched.containsKey(index) ? const SizedBox(width: 80, height: 80) : Draggable<int>(data: index, feedback: Icon(shapes[index], color: colors[index], size: 80), childWhenDragging: Icon(shapes[index], color: colors[index].withOpacity(0.2), size: 70), child: Icon(shapes[index], color: colors[index], size: 70));
                }).toList()),
                const Spacer(),
              ],
            ),
          ),
        ),
        if (_showCelebration) const IgnorePointer(child: _ConfettiOverlay()),
      ],
    );
  }
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
