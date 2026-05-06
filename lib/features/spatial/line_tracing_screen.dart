import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

class LineTracingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const LineTracingScreen({super.key, this.levelId = 1});

  @override
  ConsumerState<LineTracingScreen> createState() => _LineTracingScreenState();
}

class _LineTracingScreenState extends ConsumerState<LineTracingScreen> {
  final List<Offset> dotPositions = [
    const Offset(0.25, 0.25), // Top-left
    const Offset(0.75, 0.25), // Top-right
    const Offset(0.25, 0.75), // Bottom-left
    const Offset(0.75, 0.75), // Bottom-right
  ];

  late _LevelData currentLevel;
  int currentLevelIndex = 0;

  final List<_LevelData> levels = [
    _LevelData(stage: 'Tantangan 1', color: Colors.yellow, targetLines: [const _Line(0, 2)], instruction: 'Tiru garis tegak ini!'),
    _LevelData(stage: 'Tantangan 2', color: Colors.red, targetLines: [const _Line(1, 3)], instruction: 'Tiru garis tegak di kanan!'),
    _LevelData(stage: 'Tantangan 3', color: Colors.blue, targetLines: [const _Line(2, 1)], instruction: 'Tiru garis miring ini!'),
    _LevelData(stage: 'Tantangan 4', color: Colors.green, targetLines: [const _Line(0, 1), const _Line(2, 3)], instruction: 'Tiru dua garis datar ini!'),
  ];

  List<_Line> userLines = [];
  int? activeStartIndex;
  Offset? currentTouchPos;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    currentLevel = levels[currentLevelIndex];
  }

  void _resetLevel() {
    setState(() { userLines = []; activeStartIndex = null; currentTouchPos = null; });
  }

  void _nextLevel() {
    if (currentLevelIndex < levels.length - 1) {
      setState(() { currentLevelIndex++; currentLevel = levels[currentLevelIndex]; _resetLevel(); });
    } else {
      _completeGame();
    }
  }

  void _completeGame() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    setState(() => _showCelebration = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _showWinDialog();
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: const Text('HEBAT! 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
        content: const Text('Level 1 Selesai! Kamu siap untuk tantangan berikutnya?', textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LevelTransitionScreen(nextLevelId: 2)));
              },
              child: const Text('LANJUT KE LEVEL 2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _checkSuccess() {
    bool allMatched = true;
    for (var target in currentLevel.targetLines) {
      if (!userLines.any((ul) => ul == target)) allMatched = false;
    }
    if (allMatched && userLines.length == currentLevel.targetLines.length) {
      HapticService.success();
      Future.delayed(const Duration(milliseconds: 600), _nextLevel);
    }
  }

  int? _getDotIndexAt(Offset localPos, Size size) {
    for (int i = 0; i < dotPositions.length; i++) {
      Offset pos = Offset(dotPositions[i].dx * size.width, dotPositions[i].dy * size.height);
      if ((localPos - pos).distance < 50) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double progress = (currentLevelIndex + 1) / levels.length;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: CilikTheme.backgroundPastel,
          body: SafeArea(
            child: Column(
              children: [
                // Custom Header with Progress Bar
                Padding(
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
                              'Tiru Garis Dasar',
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
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(currentLevel.color),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                Text(currentLevel.instruction, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _GridPanel(dotPositions: dotPositions, lines: currentLevel.targetLines, color: currentLevel.color, isInteractive: false, title: 'CONTOH')),
                      Container(width: 4, margin: const EdgeInsets.symmetric(vertical: 40), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onPanStart: (details) {
                                int? index = _getDotIndexAt(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight));
                                if (index != null) { setState(() { activeStartIndex = index; currentTouchPos = details.localPosition; }); HapticService.light(); }
                              },
                              onPanUpdate: (details) { if (activeStartIndex != null) setState(() => currentTouchPos = details.localPosition); },
                              onPanEnd: (details) {
                                if (activeStartIndex != null && currentTouchPos != null) {
                                  int? endIndex = _getDotIndexAt(currentTouchPos!, Size(constraints.maxWidth, constraints.maxHeight));
                                  if (endIndex != null && endIndex != activeStartIndex) {
                                    setState(() { _Line newLine = _Line(activeStartIndex!, endIndex); if (!userLines.any((l) => l == newLine)) { userLines.add(newLine); HapticService.light(); _checkSuccess(); } });
                                  }
                                }
                                setState(() { activeStartIndex = null; currentTouchPos = null; });
                              },
                              child: _GridPanel(dotPositions: dotPositions, lines: userLines, activeLine: activeStartIndex != null ? _ActiveLine(activeStartIndex!, currentTouchPos!) : null, color: currentLevel.color, isInteractive: true, title: 'GAMBAR DISINI'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (_showCelebration) const IgnorePointer(child: _ConfettiOverlay()),
      ],
    );
  }
}

class _Line {
  final int start; final int end;
  const _Line(this.start, this.end);
  @override
  bool operator ==(Object other) => other is _Line && ((start == other.start && end == other.end) || (start == other.end && end == other.start));
  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class _ActiveLine { final int startIndex; final Offset endPos; const _ActiveLine(this.startIndex, this.endPos); }

class _LevelData { final String stage; final Color color; final List<_Line> targetLines; final String instruction; const _LevelData({required this.stage, required this.color, required this.targetLines, required this.instruction}); }

class _GridPanel extends StatelessWidget {
  final List<Offset> dotPositions; final List<_Line> lines; final _ActiveLine? activeLine; final Color color; final bool isInteractive; final String title;
  const _GridPanel({required this.dotPositions, required this.lines, this.activeLine, required this.color, required this.isInteractive, required this.title});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(title, style: TextStyle(color: color.withOpacity(0.7), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2))),
        const SizedBox(height: 12),
        Expanded(child: AspectRatio(aspectRatio: 0.85, child: Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 10))], border: Border.all(color: color.withOpacity(0.1), width: 2)), child: CustomPaint(painter: _GridPainter(dotPositions: dotPositions, lines: lines, activeLine: activeLine, color: color))))),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final List<Offset> dotPositions; final List<_Line> lines; final _ActiveLine? activeLine; final Color color;
  _GridPainter({required this.dotPositions, required this.lines, this.activeLine, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = color..strokeWidth = 14..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final activeLinePaint = Paint()..color = color.withOpacity(0.4)..strokeWidth = 14..strokeCap = StrokeCap.round;
    for (var line in lines) { canvas.drawLine(Offset(dotPositions[line.start].dx * size.width, dotPositions[line.start].dy * size.height), Offset(dotPositions[line.end].dx * size.width, dotPositions[line.end].dy * size.height), linePaint); }
    if (activeLine != null) { canvas.drawLine(Offset(dotPositions[activeLine!.startIndex].dx * size.width, dotPositions[activeLine!.startIndex].dy * size.height), activeLine!.endPos, activeLinePaint); }
    for (var pos in dotPositions) {
      Offset center = Offset(pos.dx * size.width, pos.dy * size.height);
      canvas.drawCircle(center, 22, Paint()..color = color);
      canvas.drawCircle(center, 18, Paint()..color = Colors.white.withOpacity(0.3));
      canvas.drawCircle(center.translate(-6, -6), 6, Paint()..color = Colors.white.withOpacity(0.4));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
