import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class DebuggingRowModel {
  final int index;
  final List<Color> initialColors;
  final List<Color> targetColors;
  final int errorIndex;
  bool isIdentified;
  bool isCorrected;

  DebuggingRowModel({
    required this.index,
    required this.initialColors,
    required this.targetColors,
    required this.errorIndex,
    this.isIdentified = false,
    this.isCorrected = false,
  });
}

class PatternDebuggingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const PatternDebuggingScreen({super.key, this.levelId = 44});

  @override
  ConsumerState<PatternDebuggingScreen> createState() => _PatternDebuggingScreenState();
}

class _PatternDebuggingScreenState extends ConsumerState<PatternDebuggingScreen>
    with SingleTickerProviderStateMixin {
  // Master colors
  static const Color colBlue = Color(0xFF38BDF8);   // Biru Muda
  static const Color colYellow = Color(0xFFFACC15); // Kuning
  static const Color colPink = Color(0xFFF472B6);   // Pink

  late List<DebuggingRowModel> _rows;
  int? _shakingArrowIndex; // Encodes row*10 + col index to identify shaking arrow
  bool _isSolved = false;

  // Proper shake animation controller (prevents main-thread blocking)
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize shake animation (short, finite duration)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _shakingArrowIndex = null;
        });
        _shakeController.reset();
      }
    });

    _initLevel();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _initLevel() {
    final List<Color> masterPattern = [colBlue, colBlue, colYellow, colYellow, colPink, colPink];

    _rows = [
      // Row 1: Blue, Blue, Yellow, Yellow, Pink, [Blue - ERROR]
      DebuggingRowModel(
        index: 0,
        initialColors: [colBlue, colBlue, colYellow, colYellow, colPink, colBlue],
        targetColors: List.from(masterPattern),
        errorIndex: 5,
      ),
      // Row 2: Blue, Blue, [Pink - ERROR], Yellow, Pink, Pink
      DebuggingRowModel(
        index: 1,
        initialColors: [colBlue, colBlue, colPink, colYellow, colPink, colPink],
        targetColors: List.from(masterPattern),
        errorIndex: 2,
      ),
      // Row 3: Blue, [Yellow - ERROR], Yellow, Yellow, Pink, Pink
      DebuggingRowModel(
        index: 2,
        initialColors: [colBlue, colYellow, colYellow, colYellow, colPink, colPink],
        targetColors: List.from(masterPattern),
        errorIndex: 1,
      ),
      // Row 4: Blue, Blue, Yellow, [Pink - ERROR], Pink, Pink
      DebuggingRowModel(
        index: 3,
        initialColors: [colBlue, colBlue, colYellow, colPink, colPink, colPink],
        targetColors: List.from(masterPattern),
        errorIndex: 3,
      ),
    ];
  }

  void _handleArrowTap(int rowIndex, int colIndex) {
    if (_isSolved) return;

    // Bounds validation to prevent RangeError
    if (rowIndex < 0 || rowIndex >= _rows.length) return;
    if (colIndex < 0 || colIndex >= 6) return;

    final row = _rows[rowIndex];

    // Tapping is only for identifying the wrong color before correction
    if (row.isCorrected || row.isIdentified) return;

    if (colIndex == row.errorIndex) {
      // Correct identification!
      SoundService.playSuccess();
      HapticService.success();

      if (!mounted) return;
      setState(() {
        row.isIdentified = true;
      });
    } else {
      // Wrong arrow tapped
      _shakeArrow(rowIndex, colIndex);
    }
  }

  void _shakeArrow(int rowIndex, int colIndex) {
    SoundService.playError();
    HapticService.failure();

    if (!mounted) return;
    setState(() {
      _shakingArrowIndex = rowIndex * 10 + colIndex;
    });

    // AnimationController drives the shake; its statusListener
    // (in initState) resets _shakingArrowIndex when complete.
    _shakeController.forward(from: 0.0);
  }

  void _handleColorDrop(DebuggingRowModel row, Color color) {
    if (_isSolved) return;

    // Bounds validation on errorIndex
    if (row.errorIndex < 0 || row.errorIndex >= row.targetColors.length) return;

    final targetColor = row.targetColors[row.errorIndex];

    if (color == targetColor) {
      // Correct repair color!
      SoundService.playSuccess();
      HapticService.success();

      if (!mounted) return;
      setState(() {
        row.isCorrected = true;
      });

      // Check level completion
      if (_rows.every((r) => r.isCorrected)) {
        _onLevelComplete();
      }
    } else {
      // Wrong repair color
      SoundService.playError();
      HapticService.failure();
    }
  }

  void _onLevelComplete() async {
    if (!mounted) return;
    setState(() {
      _isSolved = true;
    });

    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(widget.levelId);
    } catch (e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    }

    if (!mounted) return;

    // 3. Show success victory dialog
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: widget.levelId + 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            _buildMasterPatternHeader(),
            const SizedBox(height: 4),
            // Play Area (Debugging rows)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _rows.length,
                    itemBuilder: (context, rowIndex) {
                      if (rowIndex < 0 || rowIndex >= _rows.length) {
                        return const SizedBox.shrink();
                      }
                      final row = _rows[rowIndex];
                      return _buildChallengeRow(row, rowIndex);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPartsBin(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 44',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 24,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bug_report_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Temukan warna panah yang salah (ketuk silang), lalu perbaiki!',
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

  Widget _buildMasterPatternHeader() {
    final List<Color> masterPattern = [colBlue, colBlue, colYellow, colYellow, colPink, colPink];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'POLA BENAR (PANDUAN MASTER)',
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final double arrowW = min(constraints.maxWidth / 6.5, 48.0);
              final double arrowH = arrowW * 0.6;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: masterPattern.map((color) {
                  return SizedBox(
                    width: arrowW,
                    height: arrowH,
                    child: CustomPaint(
                      painter: MasterArrowPainter(color: color),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeRow(DebuggingRowModel row, int rowIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: row.isCorrected ? Colors.green.withOpacity(0.2) : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Baris ${rowIndex + 1}',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              if (row.isCorrected)
                const Icon(Icons.check_circle, color: Colors.green, size: 18)
              else if (row.isIdentified)
                Text(
                  'Perbaiki eror!',
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final double arrowW = min(constraints.maxWidth / 6.5, 46.0);
              final double arrowH = arrowW * 0.6;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (colIndex) {
                  // Bounds safety check
                  if (colIndex >= row.initialColors.length) {
                    return const SizedBox.shrink();
                  }

                  final isErrorIndex = colIndex == row.errorIndex;
                  final isShaking = _shakingArrowIndex == (rowIndex * 10 + colIndex);

                  Color arrowColor = row.initialColors[colIndex];
                  if (isErrorIndex && row.isCorrected && colIndex < row.targetColors.length) {
                    arrowColor = row.targetColors[colIndex]; // show corrected color
                  }

                  // Build the base arrow widget
                  final baseArrow = SizedBox(
                    width: arrowW,
                    height: arrowH,
                    child: CustomPaint(
                      painter: MasterArrowPainter(
                        color: arrowColor,
                        isXOverlay: isErrorIndex && row.isIdentified && !row.isCorrected,
                        isCorrected: isErrorIndex && row.isCorrected,
                      ),
                    ),
                  );

                  // If identified but not corrected, make the error slot a DragTarget
                  // Note: We use baseArrow as child (not arrowWidget) to avoid
                  // self-referencing variable which causes widget tree corruption
                  Widget finalWidget;
                  if (isErrorIndex && row.isIdentified && !row.isCorrected) {
                    finalWidget = DragTarget<Color>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) => _handleColorDrop(row, details.data),
                      builder: (context, candidateData, rejectedData) {
                        final bool isHovering = candidateData.isNotEmpty;
                        return AnimatedScale(
                          scale: isHovering ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: baseArrow,
                        );
                      },
                    );
                  } else {
                    finalWidget = baseArrow;
                  }

                  // Wrap with gesture detector for tap identification
                  final tappableWidget = GestureDetector(
                    onTap: () => _handleArrowTap(rowIndex, colIndex),
                    child: finalWidget,
                  );

                  // Only wrap with AnimatedBuilder for the shaking arrow
                  if (!isShaking) return tappableWidget;

                  return AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      final double shakeX = _shakeAnimation.value *
                          sin(2 * pi * (_shakeController.value * 4));
                      return Transform.translate(
                        offset: Offset(shakeX, 0),
                        child: child,
                      );
                    },
                    child: tappableWidget,
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartsBin() {
    final List<Color> colors = [colBlue, colYellow, colPink];
    final Map<Color, String> colorNames = {
      colBlue: 'Biru Muda',
      colYellow: 'Kuning',
      colPink: 'Pink',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      height: 126,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PARTS BIN (SERET WARNA BENAR UNTUK MEMPERBAIKI)',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colors.map((color) {
                return Draggable<Color>(
                  data: color,
                  feedback: _buildDraggableArrowFeedback(color),
                  childWhenDragging: Opacity(
                    opacity: 0.35,
                    child: _buildDraggableArrow(color, colorNames[color]!),
                  ),
                  child: _buildDraggableArrow(color, colorNames[color]!),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableArrow(Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 28,
          child: CustomPaint(
            painter: MasterArrowPainter(color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableArrowFeedback(Color color) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 52,
        height: 34,
        child: CustomPaint(
          painter: MasterArrowPainter(color: color, isFloatingFeedback: true),
        ),
      ),
    );
  }
}

class MasterArrowPainter extends CustomPainter {
  final Color color;
  final bool isXOverlay;
  final bool isCorrected;
  final bool isFloatingFeedback;

  MasterArrowPainter({
    required this.color,
    this.isXOverlay = false,
    this.isCorrected = false,
    this.isFloatingFeedback = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw background vector arrow
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double headW = w * 0.44;
    final double tailH = h * 0.44;

    final path = Path()
      ..moveTo(2, (h - tailH) / 2)
      ..lineTo(w - headW, (h - tailH) / 2)
      ..lineTo(w - headW, 2)
      ..lineTo(w - 2, h / 2)
      ..lineTo(w - headW, h - 2)
      ..lineTo(w - headW, (h + tailH) / 2)
      ..lineTo(2, (h + tailH) / 2)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // Subtle gloss overlay
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final glossPath = Path()
      ..moveTo(4, (h - tailH) / 2 + 1.5)
      ..lineTo(w - headW, (h - tailH) / 2 + 1.5)
      ..lineTo(w - headW, 4)
      ..lineTo(w - 6, h / 2)
      ..lineTo(w - headW + 2, h / 2)
      ..lineTo(w - headW + 2, (h - tailH) / 2 + 4)
      ..lineTo(4, (h - tailH) / 2 + 4)
      ..close();
    canvas.drawPath(glossPath, glossPaint);

    // If marked as identified wrong color (red cross overlay)
    if (isXOverlay) {
      final xPaint = Paint()
        ..color = Colors.red.shade600
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      // Draw standard X lines
      canvas.drawLine(const Offset(4, 4), Offset(w - 4, h - 4), xPaint);
      canvas.drawLine(Offset(4, h - 4), Offset(w - 4, 4), xPaint);
    }

    // Success glow outline if corrected
    if (isCorrected) {
      final glowPaint = Paint()
        ..color = Colors.greenAccent
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MasterArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isXOverlay != isXOverlay ||
        oldDelegate.isCorrected != isCorrected ||
        oldDelegate.isFloatingFeedback != isFloatingFeedback;
  }
}
