import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/confetti_effect.dart';

class LineTracingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const LineTracingScreen({super.key, this.levelId = 1});

  @override
  ConsumerState<LineTracingScreen> createState() => _LineTracingScreenState();
}

class _LineTracingScreenState extends ConsumerState<LineTracingScreen> {
  final List<Offset> dotPositions = [
    const Offset(0.25, 0.25),
    const Offset(0.75, 0.25),
    const Offset(0.25, 0.75),
    const Offset(0.75, 0.75),
  ];

  late _LevelData currentLevel;
  int currentLevelIndex = 0;
  bool isGameWon = false;

  final List<_LevelData> levels = [
    // Level 1 Patterns
    _LevelData(
      stage: 'Level 1',
      color: Colors.yellow,
      targetLines: [const _Line(0, 2)],
      instruction: 'Tiru garis tegak ini!',
    ),
    _LevelData(
      stage: 'Level 1',
      color: Colors.red,
      targetLines: [const _Line(1, 3)],
      instruction: 'Tiru garis tegak di kanan!',
    ),
    _LevelData(
      stage: 'Level 1',
      color: Colors.blue,
      targetLines: [const _Line(2, 1)],
      instruction: 'Tiru garis miring ini!',
    ),
    _LevelData(
      stage: 'Level 1',
      color: Colors.green,
      targetLines: [const _Line(0, 1), const _Line(2, 3)],
      instruction: 'Tiru dua garis datar ini!',
    ),
    // Level 2 Patterns
    _LevelData(
      stage: 'Level 2',
      color: Colors.yellow,
      targetLines: [const _Line(0, 1), const _Line(1, 2)],
      instruction: 'Ayo buat pola garis kuning!',
    ),
    _LevelData(
      stage: 'Level 2',
      color: Colors.red,
      targetLines: [const _Line(0, 1), const _Line(0, 2), const _Line(2, 3)],
      instruction: 'Tiru pola garis merah ini!',
    ),
    _LevelData(
      stage: 'Level 2',
      color: Colors.blue,
      targetLines: [const _Line(2, 1), const _Line(1, 3)],
      instruction: 'Bisa buat pola biru ini?',
    ),
    _LevelData(
      stage: 'Level 2',
      color: Colors.green,
      targetLines: [const _Line(0, 3), const _Line(1, 2)],
      instruction: 'Hebat! Sekarang pola silang!',
    ),
  ];

  List<_Line> userLines = [];
  int? activeStartIndex;
  Offset? currentTouchPos;

  @override
  void initState() {
    super.initState();
    currentLevel = levels[currentLevelIndex];
  }

  void _resetLevel() {
    setState(() {
      userLines = [];
      activeStartIndex = null;
      currentTouchPos = null;
    });
  }

  void _nextLevel() {
    if (currentLevelIndex < levels.length - 1) {
      String oldStage = levels[currentLevelIndex].stage;
      String newStage = levels[currentLevelIndex + 1].stage;

      if (oldStage != newStage) {
        _showStageCompleteDialog(oldStage, newStage);
      } else {
        setState(() {
          currentLevelIndex++;
          currentLevel = levels[currentLevelIndex];
          _resetLevel();
        });
      }
    } else {
      _completeGame();
    }
  }

  void _completeGame() {
    setState(() {
      isGameWon = true;
    });
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    HapticService.success();
    _showWinDialog();
  }

  void _showStageCompleteDialog(String completedStage, String nextStage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Text('Luar Biasa! 🌟', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Kamu sudah menyelesaikan $completedStage!', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars_rounded, size: 80, color: Colors.orangeAccent),
            SizedBox(height: 16),
            Text('Siap untuk tantangan berikutnya?', textAlign: TextAlign.center),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CilikTheme.primaryPastel,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentLevelIndex++;
                currentLevel = levels[currentLevelIndex];
                _resetLevel();
              });
            },
            child: const Text('LANJUT!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('HORREE! 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 100, color: Colors.amber),
            SizedBox(height: 16),
            Text('Kamu sang Arsitek Hebat! Semua pola sudah selesai.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('KEMBALI KE PETA'),
            ),
          ),
        ],
      ),
    );
  }

  void _checkSuccess() {
    bool allMatched = true;
    for (var target in currentLevel.targetLines) {
      bool found = userLines.any((ul) => ul == target);
      if (!found) allMatched = false;
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
    int totalInStage = levels.where((l) => l.stage == currentLevel.stage).length;
    int indexInStage = levels.sublist(0, currentLevelIndex + 1).where((l) => l.stage == currentLevel.stage).length;

    return Scaffold(
      backgroundColor: CilikTheme.backgroundPastel,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Level ${widget.levelId}', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.black54), onPressed: _resetLevel),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${currentLevel.stage} - $indexInStage/$totalInStage', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                        const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: indexInStage / totalInStage,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(currentLevel.color),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(currentLevel.instruction, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
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
                              if (index != null) {
                                setState(() { activeStartIndex = index; currentTouchPos = details.localPosition; });
                                HapticService.light();
                              }
                            },
                            onPanUpdate: (details) { if (activeStartIndex != null) setState(() { currentTouchPos = details.localPosition; }); },
                            onPanEnd: (details) {
                              if (activeStartIndex != null && currentTouchPos != null) {
                                int? endIndex = _getDotIndexAt(currentTouchPos!, Size(constraints.maxWidth, constraints.maxHeight));
                                if (endIndex != null && endIndex != activeStartIndex) {
                                  setState(() {
                                    _Line newLine = _Line(activeStartIndex!, endIndex);
                                    if (!userLines.any((l) => l == newLine)) { userLines.add(newLine); HapticService.light(); _checkSuccess(); }
                                  });
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
              const SizedBox(height: 40),
            ],
          ),
          
          // Confetti Layer
          if (isGameWon) const ConfettiEffect(isPlaying: true),
        ],
      ),
    );
  }
}

class _Line {
  final int start;
  final int end;
  const _Line(this.start, this.end);
  @override
  bool operator ==(Object other) {
    if (other is! _Line) return false;
    return (start == other.start && end == other.end) || (start == other.end && end == other.start);
  }
  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class _ActiveLine {
  final int startIndex;
  final Offset endPos;
  const _ActiveLine(this.startIndex, this.endPos);
}

class _LevelData {
  final String stage;
  final Color color;
  final List<_Line> targetLines;
  final String instruction;
  const _LevelData({required this.stage, required this.color, required this.targetLines, required this.instruction});
}

class _GridPanel extends StatelessWidget {
  final List<Offset> dotPositions;
  final List<_Line> lines;
  final _ActiveLine? activeLine;
  final Color color;
  final bool isInteractive;
  final String title;

  const _GridPanel({required this.dotPositions, required this.lines, this.activeLine, required this.color, required this.isInteractive, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(title, style: TextStyle(color: color.withOpacity(0.7), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.2))),
        const SizedBox(height: 8),
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.8,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5))], border: Border.all(color: color.withOpacity(0.1), width: 2)),
              child: CustomPaint(painter: _GridPainter(dotPositions: dotPositions, lines: lines, activeLine: activeLine, color: color)),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<_Line> lines;
  final _ActiveLine? activeLine;
  final Color color;
  _GridPainter({required this.dotPositions, required this.lines, this.activeLine, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = color..strokeWidth = 12..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final glowPaint = Paint()..color = color.withOpacity(0.2)..strokeWidth = 18..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (var line in lines) {
      Offset p1 = Offset(dotPositions[line.start].dx * size.width, dotPositions[line.start].dy * size.height);
      Offset p2 = Offset(dotPositions[line.end].dx * size.width, dotPositions[line.end].dy * size.height);
      canvas.drawLine(p1, p2, glowPaint);
      canvas.drawLine(p1, p2, linePaint);
    }
    if (activeLine != null) {
      Offset p1 = Offset(dotPositions[activeLine!.startIndex].dx * size.width, dotPositions[activeLine!.startIndex].dy * size.height);
      canvas.drawLine(p1, activeLine!.endPos, Paint()..color = color.withOpacity(0.3)..strokeWidth = 12..strokeCap = StrokeCap.round);
    }
    for (var pos in dotPositions) {
      Offset center = Offset(pos.dx * size.width, pos.dy * size.height);
      canvas.drawCircle(center, 20, Paint()..color = color.withOpacity(0.8));
      canvas.drawCircle(center, 15, Paint()..color = Colors.white.withOpacity(0.2));
      canvas.drawCircle(center, 12, Paint()..color = color);
      canvas.drawCircle(center.translate(-5, -5), 5, Paint()..color = Colors.white.withOpacity(0.3));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
