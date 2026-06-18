import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class Level50Screen extends ConsumerStatefulWidget {
  const Level50Screen({super.key});

  @override
  ConsumerState<Level50Screen> createState() => _Level50ScreenState();
}

class _Level50ScreenState extends ConsumerState<Level50Screen> {
  // Orange loop target pattern path coordinates (index 0 to 15)
  final List<int> targetPattern = [12, 8, 4, 0, 1, 5, 9, 10, 6, 2, 3, 7, 11, 15, 14, 13, 12];

  // User drawn path node indices
  List<int> userPath = [];
  Offset? currentDragOffset;
  bool _showRedFlash = false;

  @override
  void initState() {
    super.initState();
    userPath = [];
    currentDragOffset = null;
    _showRedFlash = false;
  }

  void _resetLevel() {
    setState(() {
      userPath.clear();
      currentDragOffset = null;
      _showRedFlash = false;
    });
  }

  void _triggerFlashRed() {
    setState(() {
      _showRedFlash = true;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _showRedFlash = false;
          userPath.clear();
        });
      }
    });
  }

  bool _isListEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _checkValidation() {
    bool matchesForward = _isListEqual(userPath, targetPattern);
    bool matchesBackward = _isListEqual(userPath, targetPattern.reversed.toList());

    if (matchesForward || matchesBackward) {
      _onLevelComplete();
    } else {
      HapticService.failure();
      _triggerFlashRed();
    }
  }

  void _onLevelComplete() async {
    ref.read(progressProvider.notifier).completeLevel(50);

    try {
      await UserService.updateProgress(50);
    } catch (e) {
      debugPrint('Cloud sync failed for level 50: $e');
    }

    if (!mounted) return;

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 51,
      title: 'TANTANGAN SELESAI! 🎉',
      message: 'Luar biasa! Kamu berhasil menamatkan petualangan Level 50!',
    );
  }

  int? _getNodeFromOffset(Offset offset, double width, double height) {
    double cellWidth = width / 5;
    double cellHeight = height / 5;
    double tolerance = 35.0; // Touch radius snap tolerance

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        double nodeX = cellWidth * (c + 1);
        double nodeY = cellHeight * (r + 1);
        if ((offset.dx - nodeX).abs() < tolerance && (offset.dy - nodeY).abs() < tolerance) {
          return r * 4 + c;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(),
            // Instruction Box
            _buildInstruction(),
            const SizedBox(height: 12),
            // Side-by-side grids layout
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // LEFT COLUMN: EXAMPLE
                    Expanded(
                      child: _buildGridPanel(
                        title: 'CONTOH',
                        lines: targetPattern,
                        color: Colors.orange.shade700,
                        isInteractive: false,
                      ),
                    ),
                    // Vertical divider line
                    Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // RIGHT COLUMN: DRAWING AREA
                    Expanded(
                      child: _buildInteractivePanel(),
                    ),
                  ],
                ),
              ),
            ),
            // Reset Button
            _buildResetButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 50',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: CilikTheme.tealTua,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gesture_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Hubungkan titik-titik di kanan untuk meniru pola contoh di sebelah kiri!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractivePanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            if (_showRedFlash) return;
            RenderBox box = context.findRenderObject() as RenderBox;
            Offset localPos = box.globalToLocal(details.globalPosition);
            int? node = _getNodeFromOffset(localPos, constraints.maxWidth, constraints.maxHeight);
            if (node != null) {
              setState(() {
                userPath = [node];
                currentDragOffset = localPos;
              });
              HapticService.light();
            }
          },
          onPanUpdate: (details) {
            if (_showRedFlash || userPath.isEmpty) return;
            RenderBox box = context.findRenderObject() as RenderBox;
            Offset localPos = box.globalToLocal(details.globalPosition);
            setState(() {
              currentDragOffset = localPos;
            });
            int? node = _getNodeFromOffset(localPos, constraints.maxWidth, constraints.maxHeight);
            if (node != null && node != userPath.last) {
              // Smooth undo dragging
              if (userPath.length >= 2 && node == userPath[userPath.length - 2]) {
                setState(() {
                  userPath.removeLast();
                });
                HapticService.light();
              } else {
                int lastNode = userPath.last;
                int r1 = lastNode ~/ 4, c1 = lastNode % 4;
                int r2 = node ~/ 4, c2 = node % 4;
                if ((r1 - r2).abs() + (c1 - c2).abs() == 1) {
                  bool isCompletingLoop = (node == userPath.first && userPath.length == targetPattern.length - 1);
                  if (!userPath.contains(node) || isCompletingLoop) {
                    setState(() {
                      userPath.add(node);
                    });
                    HapticService.light();
                  }
                }
              }
            }
          },
          onPanEnd: (details) {
            if (_showRedFlash || userPath.isEmpty) return;
            setState(() {
              currentDragOffset = null;
            });
            _checkValidation();
          },
          child: _buildGridPanel(
            title: 'GAMBAR DISINI',
            lines: userPath,
            color: Colors.blue.shade700,
            isInteractive: true,
            liveDragOffset: currentDragOffset,
          ),
        );
      },
    );
  }

  Widget _buildGridPanel({
    required String title,
    required List<int> lines,
    required Color color,
    required bool isInteractive,
    Offset? liveDragOffset,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _showRedFlash && isInteractive
                ? Colors.red.withOpacity(0.1)
                : (isInteractive ? Colors.blue.withOpacity(0.1) : color.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: GoogleFonts.fredoka(
              color: _showRedFlash && isInteractive
                  ? Colors.red.shade800
                  : (isInteractive ? Colors.blue.shade800 : color.withOpacity(0.8)),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.85,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showRedFlash && isInteractive ? const Color(0xFFFFEBEE) : Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: _showRedFlash && isInteractive
                        ? Colors.red.withOpacity(0.15)
                        : (isInteractive ? Colors.blue.withOpacity(0.08) : color.withOpacity(0.08)),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  )
                ],
                border: Border.all(
                  color: _showRedFlash && isInteractive
                      ? Colors.red.withOpacity(0.5)
                      : (isInteractive ? Colors.blue.withOpacity(0.15) : color.withOpacity(0.15)),
                  width: _showRedFlash && isInteractive ? 3.0 : 2.0,
                ),
              ),
              child: CustomPaint(
                painter: GridPainter(
                  lines: lines,
                  liveDragOffset: liveDragOffset,
                  color: _showRedFlash && isInteractive ? Colors.red : color,
                  isInteractive: isInteractive,
                  showRedFlash: _showRedFlash && isInteractive,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return TextButton.icon(
      onPressed: () {
        if (!_showRedFlash) {
          setState(() {
            userPath.clear();
          });
        }
      },
      icon: const Icon(Icons.refresh_rounded, size: 22),
      label: Text(
        'Ulangi',
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.orange.shade800,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final List<int> lines;
  final Offset? liveDragOffset;
  final Color color;
  final bool isInteractive;
  final bool showRedFlash;

  GridPainter({
    required this.lines,
    this.liveDragOffset,
    required this.color,
    required this.isInteractive,
    this.showRedFlash = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double cellWidth = size.width / 5;
    double cellHeight = size.height / 5;

    Offset getOffset(int index) {
      int r = index ~/ 4;
      int c = index % 4;
      return Offset(cellWidth * (c + 1), cellHeight * (r + 1));
    }

    // 1. Draw static segments or user-drawn path lines
    if (lines.isNotEmpty) {
      final linePaint = Paint()
        ..color = showRedFlash
            ? Colors.red
            : (isInteractive ? Colors.blue.shade600 : color)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(getOffset(lines.first).dx, getOffset(lines.first).dy);
      for (int i = 1; i < lines.length; i++) {
        Offset next = getOffset(lines[i]);
        path.lineTo(next.dx, next.dy);
      }
      canvas.drawPath(path, linePaint);

      // Draw transition line to current drag position
      if (isInteractive && liveDragOffset != null) {
        final activePaint = Paint()
          ..color = showRedFlash
              ? Colors.red.withOpacity(0.5)
              : Colors.blue.shade300.withOpacity(0.6)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(getOffset(lines.last), liveDragOffset!, activePaint);
      }
    }

    // 2. Draw Simpul Bulatan Titik Grid (Rendering Nodes)
    final dotOuterPaint = Paint()
      ..color = showRedFlash ? Colors.red : color;
    final dotInnerPaint = Paint()
      ..color = Colors.white.withOpacity(0.35);
    final dotGlossPaint = Paint()
      ..color = Colors.white.withOpacity(0.5);

    for (int i = 0; i < 16; i++) {
      Offset center = getOffset(i);
      // Outer colored circle
      canvas.drawCircle(center, 22, dotOuterPaint);
      // Inner glass/gloss ring
      canvas.drawCircle(center, 18, dotInnerPaint);
      // Small gloss highlight reflection on top-left
      canvas.drawCircle(center.translate(-6, -6), 6, dotGlossPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => true;
}