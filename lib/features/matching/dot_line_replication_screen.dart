import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data ────────────────────────────────────────────────────────────────────

/// A single edge between two dot indices.
class DotEdge {
  final int from;
  final int to;
  const DotEdge(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      other is DotEdge &&
      ((from == other.from && to == other.to) ||
       (from == other.to && to == other.from));

  @override
  int get hashCode {
    final a = min(from, to);
    final b = max(from, to);
    return a * 1000 + b;
  }
}

/// One challenge panel (Bird / Butterfly / Frog).
class DotPatternPanel {
  final String label;
  final String emoji;
  final Color themeColor;
  final int cols;
  final int rows;
  final List<DotEdge> targetEdges; // reference pattern
  List<DotEdge> drawnEdges;        // child's attempts
  bool isSolved;

  DotPatternPanel({
    required this.label,
    required this.emoji,
    required this.themeColor,
    required this.cols,
    required this.rows,
    required this.targetEdges,
    List<DotEdge>? drawnEdges,
    this.isSolved = false,
  }) : drawnEdges = drawnEdges ?? [];
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class DotLineReplicationScreen extends ConsumerStatefulWidget {
  final int levelId;
  const DotLineReplicationScreen({super.key, this.levelId = 49});

  @override
  ConsumerState<DotLineReplicationScreen> createState() =>
      _DotLineReplicationScreenState();
}

class _DotLineReplicationScreenState
    extends ConsumerState<DotLineReplicationScreen> {

  late List<DotPatternPanel> _panels;
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    _initPanels();
  }

  /// Grid index helper: col + row * cols
  int _idx(int col, int row, int cols) => col + row * cols;

  void _initPanels() {
    // ── Panel 1: Bird (blue) — 5 cols × 4 rows ──
    // Pattern: a zigzag shape resembling the workbook image
    const int bCols = 5, bRows = 4;
    final birdEdges = <DotEdge>[
      DotEdge(_idx(0, 0, bCols), _idx(1, 0, bCols)),
      DotEdge(_idx(1, 0, bCols), _idx(2, 0, bCols)),
      DotEdge(_idx(2, 0, bCols), _idx(3, 1, bCols)),
      DotEdge(_idx(3, 1, bCols), _idx(2, 1, bCols)),
      DotEdge(_idx(2, 1, bCols), _idx(1, 2, bCols)),
      DotEdge(_idx(1, 2, bCols), _idx(0, 2, bCols)),
      DotEdge(_idx(0, 2, bCols), _idx(0, 3, bCols)),
      DotEdge(_idx(0, 3, bCols), _idx(1, 3, bCols)),
    ];

    // ── Panel 2: Butterfly (pink) — 5 cols × 4 rows ──
    // Pattern: a diamond/triangle shape
    const int kCols = 5, kRows = 4;
    final butterflyEdges = <DotEdge>[
      DotEdge(_idx(2, 0, kCols), _idx(0, 1, kCols)),
      DotEdge(_idx(0, 1, kCols), _idx(2, 2, kCols)),
      DotEdge(_idx(2, 2, kCols), _idx(4, 1, kCols)),
      DotEdge(_idx(4, 1, kCols), _idx(2, 0, kCols)),
      DotEdge(_idx(2, 0, kCols), _idx(2, 2, kCols)),
      DotEdge(_idx(0, 2, kCols), _idx(2, 3, kCols)),
      DotEdge(_idx(2, 3, kCols), _idx(4, 2, kCols)),
    ];

    // ── Panel 3: Frog (green) — 5 cols × 5 rows ──
    // Pattern: a house/complex shape
    const int fCols = 5, fRows = 5;
    final frogEdges = <DotEdge>[
      DotEdge(_idx(1, 0, fCols), _idx(0, 1, fCols)),
      DotEdge(_idx(0, 1, fCols), _idx(0, 3, fCols)),
      DotEdge(_idx(0, 3, fCols), _idx(1, 4, fCols)),
      DotEdge(_idx(1, 4, fCols), _idx(3, 4, fCols)),
      DotEdge(_idx(3, 4, fCols), _idx(4, 3, fCols)),
      DotEdge(_idx(4, 3, fCols), _idx(4, 1, fCols)),
      DotEdge(_idx(4, 1, fCols), _idx(3, 0, fCols)),
      DotEdge(_idx(3, 0, fCols), _idx(1, 0, fCols)),
      DotEdge(_idx(1, 0, fCols), _idx(2, 1, fCols)),
      DotEdge(_idx(2, 1, fCols), _idx(3, 0, fCols)),
    ];

    _panels = [
      DotPatternPanel(
        label: 'Burung',
        emoji: '🐦',
        themeColor: const Color(0xFF60A5FA),
        cols: bCols,
        rows: bRows,
        targetEdges: birdEdges,
      ),
      DotPatternPanel(
        label: 'Kupu-kupu',
        emoji: '🦋',
        themeColor: const Color(0xFFF472B6),
        cols: kCols,
        rows: kRows,
        targetEdges: butterflyEdges,
      ),
      DotPatternPanel(
        label: 'Katak',
        emoji: '🐸',
        themeColor: const Color(0xFF4ADE80),
        cols: fCols,
        rows: fRows,
        targetEdges: frogEdges,
      ),
    ];
  }

  void _onEdgeDrawn(int panelIndex, DotEdge edge) {
    final panel = _panels[panelIndex];
    if (panel.isSolved) return;

    // Check if this edge exists in the target
    if (panel.targetEdges.contains(edge) &&
        !panel.drawnEdges.contains(edge)) {
      SoundService.playSuccess();
      HapticService.success();
      setState(() {
        panel.drawnEdges.add(edge);
      });

      // Panel complete?
      if (panel.drawnEdges.length == panel.targetEdges.length) {
        setState(() {
          panel.isSolved = true;
        });
        // All panels done?
        if (_panels.every((p) => p.isSolved)) {
          _onLevelComplete();
        }
      }
    } else if (!panel.targetEdges.contains(edge)) {
      // Wrong edge
      SoundService.playError();
      HapticService.failure();
    }
    // If edge is already drawn, silently ignore
  }

  void _onLevelComplete() async {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    try {
      await UserService.updateProgress(49);
    } catch (e) {
      debugPrint('Cloud sync failed for level 49: $e');
    }

    if (!mounted) return;

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 50,
      title: 'Luar Biasa!',
      message: 'Kamu ahli dalam menyusun algoritma jalur!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    for (int i = 0; i < _panels.length; i++) ...[
                      _buildPanel(i),
                      if (i < _panels.length - 1)
                        Divider(color: Colors.grey.shade200, height: 20),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 49',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CilikTheme.tealTua,
              ),
            ),
          ),
          // Hint toggle
          IconButton(
            icon: Icon(
              _showHints ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showHints ? Colors.amber : Colors.grey,
            ),
            tooltip: 'Petunjuk',
            onPressed: () {
              HapticService.light();
              setState(() {
                _showHints = !_showHints;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✏️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Gambarkan garis yang sama di sebelah kanan!',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Panel ──────────────────────────────────────────────────────────────

  Widget _buildPanel(int panelIndex) {
    final panel = _panels[panelIndex];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: panel.isSolved
              ? panel.themeColor.withOpacity(0.6)
              : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Text(panel.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                panel.label,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: panel.themeColor,
                ),
              ),
              const Spacer(),
              if (panel.isSolved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Selesai!',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '${panel.drawnEdges.length}/${panel.targetEdges.length}',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Left = reference, Right = play area
          Row(
            children: [
              // Reference grid (non-interactive)
              Expanded(
                child: AspectRatio(
                  aspectRatio: panel.cols / panel.rows,
                  child: _DotGrid(
                    cols: panel.cols,
                    rows: panel.rows,
                    dotColor: panel.themeColor.withOpacity(0.6),
                    edges: panel.targetEdges,
                    lineColor: panel.themeColor,
                    isInteractive: false,
                    onEdgeDrawn: null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Play area grid (interactive)
              Expanded(
                child: AspectRatio(
                  aspectRatio: panel.cols / panel.rows,
                  child: _DotGrid(
                    cols: panel.cols,
                    rows: panel.rows,
                    dotColor: panel.themeColor.withOpacity(0.5),
                    edges: panel.drawnEdges,
                    lineColor: panel.themeColor,
                    isInteractive: !panel.isSolved,
                    hintEdges: _showHints ? panel.targetEdges : null,
                    onEdgeDrawn: (edge) => _onEdgeDrawn(panelIndex, edge),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Dot Grid Widget ────────────────────────────────────────────────────────

class _DotGrid extends StatefulWidget {
  final int cols;
  final int rows;
  final Color dotColor;
  final List<DotEdge> edges;
  final Color lineColor;
  final bool isInteractive;
  final List<DotEdge>? hintEdges;
  final void Function(DotEdge)? onEdgeDrawn;

  const _DotGrid({
    required this.cols,
    required this.rows,
    required this.dotColor,
    required this.edges,
    required this.lineColor,
    required this.isInteractive,
    this.hintEdges,
    this.onEdgeDrawn,
  });

  @override
  State<_DotGrid> createState() => _DotGridState();
}

class _DotGridState extends State<_DotGrid> {
  int? _dragStartDot;
  Offset? _currentDragPos;

  Offset _dotCenter(int dotIndex, Size size) {
    final col = dotIndex % widget.cols;
    final row = dotIndex ~/ widget.cols;
    final spacingX = size.width / (widget.cols + 1);
    final spacingY = size.height / (widget.rows + 1);
    return Offset(spacingX * (col + 1), spacingY * (row + 1));
  }

  int? _hitTestDot(Offset localPos, Size size) {
    const double hitRadius = 22.0;
    for (int r = 0; r < widget.rows; r++) {
      for (int c = 0; c < widget.cols; c++) {
        final idx = c + r * widget.cols;
        final center = _dotCenter(idx, size);
        if ((localPos - center).distance <= hitRadius) {
          return idx;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: widget.isInteractive
              ? (details) {
                  final dot = _hitTestDot(details.localPosition, size);
                  if (dot != null) {
                    setState(() {
                      _dragStartDot = dot;
                      _currentDragPos = details.localPosition;
                    });
                  }
                }
              : null,
          onPanUpdate: widget.isInteractive
              ? (details) {
                  if (_dragStartDot != null) {
                    setState(() {
                      _currentDragPos = details.localPosition;
                    });
                  }
                }
              : null,
          onPanEnd: widget.isInteractive
              ? (details) {
                  if (_dragStartDot != null && _currentDragPos != null) {
                    final endDot = _hitTestDot(_currentDragPos!, size);
                    if (endDot != null && endDot != _dragStartDot) {
                      widget.onEdgeDrawn?.call(
                        DotEdge(_dragStartDot!, endDot),
                      );
                    }
                  }
                  setState(() {
                    _dragStartDot = null;
                    _currentDragPos = null;
                  });
                }
              : null,
          child: CustomPaint(
            size: size,
            painter: _DotGridPainter(
              cols: widget.cols,
              rows: widget.rows,
              dotColor: widget.dotColor,
              edges: widget.edges,
              lineColor: widget.lineColor,
              hintEdges: widget.hintEdges,
              dragStartDot: _dragStartDot,
              currentDragPos: _currentDragPos,
            ),
          ),
        );
      },
    );
  }
}

// ─── Painter ────────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  final int cols;
  final int rows;
  final Color dotColor;
  final List<DotEdge> edges;
  final Color lineColor;
  final List<DotEdge>? hintEdges;
  final int? dragStartDot;
  final Offset? currentDragPos;

  _DotGridPainter({
    required this.cols,
    required this.rows,
    required this.dotColor,
    required this.edges,
    required this.lineColor,
    this.hintEdges,
    this.dragStartDot,
    this.currentDragPos,
  });

  Offset _dotCenter(int idx, Size size) {
    final col = idx % cols;
    final row = idx ~/ cols;
    final spacingX = size.width / (cols + 1);
    final spacingY = size.height / (rows + 1);
    return Offset(spacingX * (col + 1), spacingY * (row + 1));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = dotColor;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw hint edges (very faint)
    if (hintEdges != null) {
      final hintPaint = Paint()
        ..color = lineColor.withOpacity(0.15)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      for (final edge in hintEdges!) {
        canvas.drawLine(
          _dotCenter(edge.from, size),
          _dotCenter(edge.to, size),
          hintPaint,
        );
      }
    }

    // Draw confirmed edges
    for (final edge in edges) {
      canvas.drawLine(
        _dotCenter(edge.from, size),
        _dotCenter(edge.to, size),
        linePaint,
      );
    }

    // Draw in-progress drag line
    if (dragStartDot != null && currentDragPos != null) {
      final dragPaint = Paint()
        ..color = lineColor.withOpacity(0.5)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        _dotCenter(dragStartDot!, size),
        currentDragPos!,
        dragPaint,
      );
    }

    // Draw dots on top
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final center = _dotCenter(c + r * cols, size);
        // White border
        canvas.drawCircle(center, 7.0, Paint()..color = Colors.white);
        // Colored fill
        canvas.drawCircle(center, 5.5, dotPaint);
      }
    }

    // Highlight the drag-start dot
    if (dragStartDot != null) {
      final highlightCenter = _dotCenter(dragStartDot!, size);
      final glowPaint = Paint()
        ..color = lineColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(highlightCenter, 10, glowPaint);
      canvas.drawCircle(highlightCenter, 6.5, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) => true;
}
