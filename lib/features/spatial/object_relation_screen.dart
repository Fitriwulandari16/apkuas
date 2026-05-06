import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

class ObjectRelationScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ObjectRelationScreen({super.key, this.levelId = 4});

  @override
  ConsumerState<ObjectRelationScreen> createState() => _ObjectRelationScreenState();
}

class _ObjectRelationScreenState extends ConsumerState<ObjectRelationScreen> {
  final List<String> flowers = ['🌸', '🌻', '🌷'];
  final List<Color> colors = [Colors.pink, Colors.yellow, Colors.red];
  
  late List<int> itemOrder;
  Map<int, bool> matched = {};
  bool _showCelebration = false;

  @override
  void initState() { super.initState(); itemOrder = [0, 1, 2]..shuffle(); }

  void _checkWin() {
    if (matched.length == flowers.length) {
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
        title: const Text('HEBAT! 🌸', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
        content: const Text('Level 4 Selesai! Kamu sangat peduli dengan bunga!', textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LevelTransitionScreen(nextLevelId: 5)));
              },
              child: const Text('LANJUT KE LEVEL 5', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          backgroundColor: const Color(0xFFE8F5E9),
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Hubungkan Objek', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Tarik Penyiram ke Bunga yang Warnanya Sama!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                const Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(flowers.length, (index) {
                  return DragTarget<int>(
                    builder: (context, candidateData, rejectedData) => Column(children: [
                      AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: matched.containsKey(index) ? colors[index].withOpacity(0.2) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors[index], width: 3)), child: Text(flowers[index], style: const TextStyle(fontSize: 60))),
                      if (matched.containsKey(index)) const Icon(Icons.check_circle, color: Colors.green, size: 30),
                    ]),
                    onWillAccept: (data) => data == index && !matched.containsKey(index),
                    onAccept: (data) { setState(() { matched[index] = true; HapticService.success(); _checkWin(); }); },
                  );
                })),
                const SizedBox(height: 100),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: itemOrder.map((index) {
                  return matched.containsKey(index) ? const SizedBox(width: 80, height: 80) : Draggable<int>(data: index, feedback: _WateringCan(color: colors[index], size: 90), childWhenDragging: _WateringCan(color: colors[index].withOpacity(0.3), size: 80), child: _WateringCan(color: colors[index], size: 80));
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

class _WateringCan extends StatelessWidget {
  final Color color; final double size; const _WateringCan({required this.color, required this.size});
  @override Widget build(BuildContext context) { return Container(width: size, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]), child: const Icon(Icons.opacity, color: Colors.white, size: 40)); }
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
