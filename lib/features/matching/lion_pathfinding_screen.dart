import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

enum LionArrowDirection { left, right, up, down }

class PathBoxModel {
  final int index;
  final int col;
  final int row;
  final LionArrowDirection targetDirection;
  LionArrowDirection? placedDirection;

  PathBoxModel({
    required this.index,
    required this.col,
    required this.row,
    required this.targetDirection,
    this.placedDirection,
  });

  Color get color {
    if (placedDirection == null) return Colors.white;
    switch (placedDirection!) {
      case LionArrowDirection.left:
        return const Color(0xFF38BDF8); // Blue
      case LionArrowDirection.right:
        return const Color(0xFFF97316); // Orange
      case LionArrowDirection.up:
        return const Color(0xFFF472B6); // Pink
      case LionArrowDirection.down:
        return const Color(0xFFFACC15); // Yellow
    }
  }
}

class LionPathfindingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const LionPathfindingScreen({super.key, this.levelId = 47});

  @override
  ConsumerState<LionPathfindingScreen> createState() => _LionPathfindingScreenState();
}

class _LionPathfindingScreenState extends ConsumerState<LionPathfindingScreen> {
  // Palette colors mapping
  static const Color colLeftBlue = Color(0xFF38BDF8);
  static const Color colRightOrange = Color(0xFFF97316);
  static const Color colUpPink = Color(0xFFF472B6);
  static const Color colDownYellow = Color(0xFFFACC15);

  LionArrowDirection _activeToolDirection = LionArrowDirection.right;
  late List<PathBoxModel> _pathBoxes;

  // Running simulation state
  bool _isRunning = false;
  int _currentPathIndex = 0; // Starts at -1 (Lion home position)

  // Coordinates matching grid layout: 4 columns (0 to 3), 4 rows (0 to 3)
  // Lion starts at (0, 3)
  // Box 0: (1, 3) -> Right (Pre-filled as hint)
  // Box 1: (2, 3) -> Right
  // Box 2: (3, 3) -> Up
  // Box 3: (3, 2) -> Up
  // Box 4: (3, 1) -> Up
  // Box 5: (3, 0) -> Left
  // Box 6: (2, 0) -> Left
  // Meat: (1, 0) (Finish)
  
  final List<Point<int>> _coordinates = const [
    Point(0, 3), // Lion Start (index 0)
    Point(1, 3), // Box 0 (index 1)
    Point(2, 3), // Box 1 (index 2)
    Point(3, 3), // Box 2 (index 3)
    Point(3, 2), // Box 3 (index 4)
    Point(3, 1), // Box 4 (index 5)
    Point(3, 0), // Box 5 (index 6)
    Point(2, 0), // Box 6 (index 7)
    Point(1, 0), // Meat Finish (index 8)
  ];

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    _pathBoxes = [
      PathBoxModel(index: 0, col: 1, row: 3, targetDirection: LionArrowDirection.right, placedDirection: LionArrowDirection.right), // Hint pre-filled
      PathBoxModel(index: 1, col: 2, row: 3, targetDirection: LionArrowDirection.right),
      PathBoxModel(index: 2, col: 3, row: 3, targetDirection: LionArrowDirection.up),
      PathBoxModel(index: 3, col: 3, row: 2, targetDirection: LionArrowDirection.up),
      PathBoxModel(index: 4, col: 3, row: 1, targetDirection: LionArrowDirection.up),
      PathBoxModel(index: 5, col: 3, row: 0, targetDirection: LionArrowDirection.left),
      PathBoxModel(index: 6, col: 2, row: 0, targetDirection: LionArrowDirection.left),
    ];
  }

  void _handleBoxTap(int boxIndex) {
    if (_isRunning) return;
    if (boxIndex == 0) return; // Hint cannot be modified

    HapticService.light();
    SoundService.playSuccess();

    setState(() {
      _pathBoxes[boxIndex].placedDirection = _activeToolDirection;
    });
  }

  void _handleDrop(int boxIndex, LionArrowDirection direction) {
    if (_isRunning) return;
    if (boxIndex == 0) return; // Hint cannot be modified

    HapticService.light();
    SoundService.playSuccess();

    setState(() {
      _pathBoxes[boxIndex].placedDirection = direction;
    });
  }

  void _runSequence() async {
    if (_isRunning) return;

    HapticService.light();
    setState(() {
      _isRunning = true;
      _currentPathIndex = 0;
    });

    // Animate Lion step-by-step along coordinates
    for (int i = 0; i < _coordinates.length; i++) {
      setState(() {
        _currentPathIndex = i;
      });

      // Soft step sound / haptic tick
      HapticService.light();
      SoundService.playSuccess(); // Walking simulation tick

      await Future.delayed(const Duration(milliseconds: 600));

      // Check arrow validation on each step
      // Step indices matching pathBoxes:
      // index 1: Box 0 (Pre-filled hint, always correct)
      // index 2: Box 1
      // index 3: Box 2
      // index 4: Box 3
      // index 5: Box 4
      // index 6: Box 5
      // index 7: Box 6
      if (i >= 1 && i <= 7) {
        final box = _pathBoxes[i - 1];
        if (box.placedDirection != box.targetDirection) {
          _triggerFailure();
          return;
        }
      }
    }

    // Success! Lion reached the Meat!
    _onLevelComplete();
  }

  void _triggerFailure() async {
    SoundService.playError();
    HapticService.failure();

    // Show error toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Panah arah masih keliru! Yuk bantu Singa memperbaikinya!',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );

    // Return to start with short delay
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _currentPathIndex = 0;
        _isRunning = false;
      });
    }
  }

  void _onLevelComplete() async {
    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(47);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 47: $e');
    }

    if (!mounted) return;

    // 3. Show success victory dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'LionSuccess',
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scaleValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: scaleValue,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.amber, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 110,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NYAM NYAM! KENYANG!',
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hebat! Singa berhasil memakan daging makanan kesukaannya!',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        // Return back to Adventure Map
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close level 47 screen
                      },
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF3C7), // Savanna yellow background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            _buildLegendHeader(),
            const SizedBox(height: 8),
            // Play Area (Grid stack savanna)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD34D), // Sunny yellow container
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFD97706), width: 6.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double gridW = constraints.maxWidth;
                      final double gridH = constraints.maxHeight;

                      // Standard grid size mapping: 4 columns wide (0 to 3), 4 rows high (0 to 3)
                      final double cellW = gridW / 4;
                      final double cellH = gridH / 4;

                      return Stack(
                        children: [
                          // 1. Draw static grid pathway boxes
                          ..._pathBoxes.map((box) {
                            return _buildGridBox(box, cellW, cellH);
                          }),

                          // 2. Draw static start/finish landmarks
                          _buildLionNest(0, 3, cellW, cellH), // Lion Home
                          _buildMeatLair(1, 0, cellW, cellH), // Meat Home

                          // 3. Draw active walking Lion sprite
                          _buildLionCharacter(cellW, cellH),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildControlBar(),
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
              'Level 47',
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
          const Icon(Icons.help_outline_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Bantu Singa mencapai dagingnya dengan menyusun panah arah!',
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

  Widget _buildLegendHeader() {
    final directions = [
      _LegendItem(LionArrowDirection.left, colLeftBlue, 'Kiri'),
      _LegendItem(LionArrowDirection.right, colRightOrange, 'Kanan'),
      _LegendItem(LionArrowDirection.up, colUpPink, 'Atas'),
      _LegendItem(LionArrowDirection.down, colDownYellow, 'Bawah'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: directions.map((dir) {
          final isSelected = _activeToolDirection == dir.direction;

          Widget draggableArrow = Draggable<LionArrowDirection>(
            data: dir.direction,
            feedback: _buildDraggableFeedback(dir.direction, dir.color),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: dir.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent,
                  width: isSelected ? 3.0 : 0.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: dir.color.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CustomPaint(
                  painter: DirectionArrowPainter(direction: dir.direction, arrowColor: Colors.white),
                ),
              ),
            ),
          );

          return GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() {
                _activeToolDirection = dir.direction;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                draggableArrow,
                const SizedBox(height: 4),
                Text(
                  dir.label,
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? dir.color : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDraggableFeedback(LionArrowDirection direction, Color color) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: DirectionArrowPainter(direction: direction, arrowColor: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildGridBox(PathBoxModel box, double w, double h) {
    final isHint = box.index == 0;

    return Positioned(
      left: box.col * w,
      top: box.row * h,
      width: w,
      height: h,
      child: Center(
        child: DragTarget<LionArrowDirection>(
          onWillAccept: (data) => data != null && !_isRunning && !isHint,
          onAccept: (data) => _handleDrop(box.index, data),
          builder: (context, candidateData, rejectedData) {
            final bool isHovering = candidateData.isNotEmpty;

            return GestureDetector(
              onTap: () => _handleBoxTap(box.index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: w * 0.88,
                height: h * 0.88,
                decoration: BoxDecoration(
                  color: isHint ? Colors.grey.shade100.withOpacity(0.8) : box.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHovering 
                        ? Colors.white 
                        : (isHint ? Colors.grey.shade400.withOpacity(0.5) : Colors.white),
                    width: isHint ? 2.0 : (isHovering ? 4.0 : 3.0),
                    style: isHint ? BorderStyle.solid : BorderStyle.solid,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: box.placedDirection != null
                    ? CustomPaint(
                        painter: DirectionArrowPainter(
                          direction: box.placedDirection!,
                          arrowColor: isHint ? Colors.grey.shade600 : Colors.white,
                          isHintDotted: isHint,
                        ),
                      )
                    : (isHovering
                        ? const Icon(Icons.add_rounded, color: Colors.white70, size: 28)
                        : null),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLionNest(int col, int row, double w, double h) {
    return Positioned(
      left: col * w,
      top: row * h,
      width: w,
      height: h,
      child: Center(
        child: Container(
          width: w * 0.9,
          height: h * 0.9,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.pets_rounded, color: Colors.white54, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildMeatLair(int col, int row, double w, double h) {
    return Positioned(
      left: col * w,
      top: row * h,
      width: w,
      height: h,
      child: Center(
        child: Container(
          width: w * 0.94,
          height: h * 0.94,
          decoration: BoxDecoration(
            color: const Color(0xFFF87171), // meat red
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '🥩',
              style: TextStyle(fontSize: w * 0.44),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLionCharacter(double w, double h) {
    final currentPos = _coordinates[_currentPathIndex];
    final double absoluteX = currentPos.x * w + (w * 0.05);
    final double absoluteY = currentPos.y * h + (h * 0.05);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      left: absoluteX,
      top: absoluteY,
      width: w * 0.9,
      height: h * 0.9,
      child: Center(
        child: Container(
          width: w * 0.8,
          height: h * 0.8,
          decoration: BoxDecoration(
            color: Colors.orange.shade700.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '🦁',
              style: TextStyle(fontSize: w * 0.48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRunning ? Colors.grey : const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            onPressed: _isRunning ? null : _runSequence,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text(
              'JALANKAN',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final LionArrowDirection direction;
  final Color color;
  final String label;
  _LegendItem(this.direction, this.color, this.label);
}

class DirectionArrowPainter extends CustomPainter {
  final LionArrowDirection direction;
  final Color arrowColor;
  final bool isHintDotted;

  DirectionArrowPainter({
    required this.direction,
    required this.arrowColor,
    this.isHintDotted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    if (isHintDotted) {
      // Configure dotted/dashed lines config
      paint.strokeWidth = 2.0;
      // Dotted hint will use simple drawing line segments
    }

    // Centered coordinates for drawing
    final double centerX = w / 2;
    final double centerY = h / 2;
    final double arrowSize = min(w, h) * 0.36;

    canvas.save();
    // Rotate canvas based on direction direction
    canvas.translate(centerX, centerY);
    switch (direction) {
      case LionArrowDirection.left:
        canvas.rotate(pi);
        break;
      case LionArrowDirection.right:
        canvas.rotate(0.0);
        break;
      case LionArrowDirection.up:
        canvas.rotate(-pi / 2);
        break;
      case LionArrowDirection.down:
        canvas.rotate(pi / 2);
        break;
    }

    // Draw a single clean arrow pointing Right inside rotated canvas
    // Shaft line
    canvas.drawLine(Offset(-arrowSize, 0), Offset(arrowSize, 0), paint);
    // Tip wings
    canvas.drawLine(Offset(arrowSize, 0), Offset(arrowSize - arrowSize * 0.45, -arrowSize * 0.45), paint);
    canvas.drawLine(Offset(arrowSize, 0), Offset(arrowSize - arrowSize * 0.45, arrowSize * 0.45), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DirectionArrowPainter oldDelegate) {
    return oldDelegate.direction != direction ||
        oldDelegate.arrowColor != arrowColor ||
        oldDelegate.isHintDotted != isHintDotted;
  }
}
