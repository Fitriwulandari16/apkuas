import 'package:flutter/material.dart';
//import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';

class LineTracingScreen extends StatefulWidget {
  const LineTracingScreen({super.key});

  @override
  State<LineTracingScreen> createState() => _LineTracingScreenState();
}

class _LineTracingScreenState extends State<LineTracingScreen> {
  // 4 points in a 2x2 grid:
  // 0  1
  // 2  3
  final List<Offset> dotPositions = [
    const Offset(0.25, 0.25), // Top-left
    const Offset(0.75, 0.25), // Top-right
    const Offset(0.25, 0.75), // Bottom-left
    const Offset(0.75, 0.75), // Bottom-right
  ];

  late _LevelData currentLevel;
  int currentLevelIndex = 0;

  final List<_LevelData> levels = [
    // Level 1 Patterns (Page 3)
    _LevelData(
      color: Colors.yellow,
      targetLines: [const _Line(0, 2)], 
      instruction: 'Tiru garis tegak di sebelah kiri!',
    ),
    _LevelData(
      color: Colors.red,
      targetLines: [const _Line(1, 3)], 
      instruction: 'Tiru garis tegak di sebelah kanan!',
    ),
    _LevelData(
      color: Colors.blue,
      targetLines: [const _Line(2, 1)], 
      instruction: 'Tiru garis miring ini!',
    ),
    _LevelData(
      color: Colors.green,
      targetLines: [const _Line(0, 1), const _Line(2, 3)], 
      instruction: 'Tiru dua garis datar ini!',
    ),
    // Level 2 Patterns (Page 4)
    _LevelData(
      color: Colors.yellow,
      targetLines: [const _Line(0, 1), const _Line(1, 2)], 
      instruction: 'Tiru pola garis kuning ini!',
    ),
    _LevelData(
      color: Colors.red,
      targetLines: [const _Line(0, 1), const _Line(0, 2), const _Line(2, 3)], 
      instruction: 'Tiru pola garis merah ini!',
    ),
    _LevelData(
      color: Colors.blue,
      targetLines: [const _Line(2, 1), const _Line(1, 3)], 
      instruction: 'Tiru pola garis biru ini!',
    ),
    _LevelData(
      color: Colors.green,
      targetLines: [const _Line(0, 3), const _Line(1, 2)], 
      instruction: 'Tiru pola silang ini!',
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
      setState(() {
        currentLevelIndex++;
        currentLevel = levels[currentLevelIndex];
        _resetLevel();
      });
    } else {
      _showWinDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Hebat! 🎉'),
        content: const Text('Kamu sudah menyelesaikan semua pola garis!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to menu
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  void _checkSuccess() {
    // Check if all target lines are present in userLines
    bool allMatched = true;
    for (var target in currentLevel.targetLines) {
      bool found = userLines.any((ul) => ul == target);
      if (!found) allMatched = false;
    }

    if (allMatched && userLines.length == currentLevel.targetLines.length) {
      HapticService.success();
      Future.delayed(const Duration(milliseconds: 500), _nextLevel);
    }
  }

  int? _getDotIndexAt(Offset localPos, Size size) {
    for (int i = 0; i < dotPositions.length; i++) {
      Offset pos = Offset(dotPositions[i].dx * size.width, dotPositions[i].dy * size.height);
      if ((localPos - pos).distance < 40) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiru Garis'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetLevel),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            currentLevel.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              children: [
                // Reference Panel
                Expanded(
                  child: _GridPanel(
                    dotPositions: dotPositions,
                    lines: currentLevel.targetLines,
                    color: currentLevel.color,
                    isInteractive: false,
                    title: 'Contoh',
                  ),
                ),
                Container(width: 2, color: Colors.grey.shade300),
                // Drawing Panel
                Expanded(
                  child: GestureDetector(
                    onPanStart: (details) {
                      RenderBox box = context.findRenderObject() as RenderBox;
                      Offset localPos = box.globalToLocal(details.globalPosition);
                      // Adjust for the Expanded and AppBar
                      // Actually, let's use a LayoutBuilder for the drawing area
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanStart: (details) {
                            int? index = _getDotIndexAt(details.localPosition, Size(constraints.maxWidth, constraints.maxHeight));
                            if (index != null) {
                              setState(() {
                                activeStartIndex = index;
                                currentTouchPos = details.localPosition;
                              });
                            }
                          },
                          onPanUpdate: (details) {
                            if (activeStartIndex != null) {
                              setState(() {
                                currentTouchPos = details.localPosition;
                              });
                            }
                          },
                          onPanEnd: (details) {
                            if (activeStartIndex != null && currentTouchPos != null) {
                              int? endIndex = _getDotIndexAt(currentTouchPos!, Size(constraints.maxWidth, constraints.maxHeight));
                              if (endIndex != null && endIndex != activeStartIndex) {
                                setState(() {
                                  _Line newLine = _Line(activeStartIndex!, endIndex);
                                  if (!userLines.any((l) => l == newLine)) {
                                    userLines.add(newLine);
                                    HapticService.light();
                                    _checkSuccess();
                                  }
                                });
                              }
                            }
                            setState(() {
                              activeStartIndex = null;
                              currentTouchPos = null;
                            });
                          },
                          child: _GridPanel(
                            dotPositions: dotPositions,
                            lines: userLines,
                            activeLine: activeStartIndex != null ? _ActiveLine(activeStartIndex!, currentTouchPos!) : null,
                            color: currentLevel.color,
                            isInteractive: true,
                            title: 'Gambar Disini',
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
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
  final Color color;
  final List<_Line> targetLines;
  final String instruction;
  const _LevelData({required this.color, required this.targetLines, required this.instruction});
}

class _GridPanel extends StatelessWidget {
  final List<Offset> dotPositions;
  final List<_Line> lines;
  final _ActiveLine? activeLine;
  final Color color;
  final bool isInteractive;
  final String title;

  const _GridPanel({
    required this.dotPositions,
    required this.lines,
    this.activeLine,
    required this.color,
    required this.isInteractive,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: CustomPaint(
                painter: _GridPainter(
                  dotPositions: dotPositions,
                  lines: lines,
                  activeLine: activeLine,
                  color: color,
                ),
              ),
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

  _GridPainter({
    required this.dotPositions,
    required this.lines,
    this.activeLine,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final activeLinePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Draw existing lines
    for (var line in lines) {
      Offset p1 = Offset(dotPositions[line.start].dx * size.width, dotPositions[line.start].dy * size.height);
      Offset p2 = Offset(dotPositions[line.end].dx * size.width, dotPositions[line.end].dy * size.height);
      canvas.drawLine(p1, p2, linePaint);
    }

    // Draw active line
    if (activeLine != null) {
      Offset p1 = Offset(dotPositions[activeLine!.startIndex].dx * size.width, dotPositions[activeLine!.startIndex].dy * size.height);
      canvas.drawLine(p1, activeLine!.endPos, activeLinePaint);
    }

    // Draw dots
    for (var pos in dotPositions) {
      canvas.drawCircle(Offset(pos.dx * size.width, pos.dy * size.height), 20, dotPaint);
      // Shine on dots
      canvas.drawCircle(Offset(pos.dx * size.width - 6, pos.dy * size.height - 6), 6, Paint()..color = Colors.white.withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
