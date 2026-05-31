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

class DragPiece {
  final String id;
  final String type; // 'down', 'right', 'down_right_elbow'
  bool isPlaced;
  DragPiece({required this.id, required this.type, this.isPlaced = false});
}

class ChickenPathfindingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ChickenPathfindingScreen({super.key, this.levelId = 45});

  @override
  ConsumerState<ChickenPathfindingScreen> createState() => _ChickenPathfindingScreenState();
}

class _ChickenPathfindingScreenState extends ConsumerState<ChickenPathfindingScreen> {
  // Grid layout representation:
  // We have a grid of 5 rows and 4 columns.
  // Rooster Start: (0, 0)
  // Coop Finish: (4, 3)
  
  // State of placed arrows in the 4 empty slots
  // Slot 0: (3, 0) -> Correct: 'down'
  // Slot 1: (4, 0) -> Correct: 'down_right_elbow'
  // Slot 2: (4, 1) -> Correct: 'right'
  // Slot 3: (4, 2) -> Correct: 'right'
  final Map<int, DragPiece?> _placedSlots = {
    0: null,
    1: null,
    2: null,
    3: null,
  };

  late List<DragPiece> _partsBin;
  
  // Chicken path running animation variables
  int _currentPathIndex = 0;
  bool _isRunning = false;
  
  // Path list of coordinates (col, row) matching the puzzle pathway
  final List<Point<int>> _path = const [
    Point(0, 0), // Rooster Start
    Point(1, 0), // ->
    Point(2, 0), // Right-then-Down elbow
    Point(2, 1), // v
    Point(2, 2), // Down-then-Left elbow
    Point(1, 2), // <-
    Point(0, 2), // Left-then-Down elbow
    Point(0, 3), // Slot 0: Empty (Down arrow)
    Point(0, 4), // Slot 1: Empty (Down-then-Right elbow)
    Point(1, 4), // Slot 2: Empty (Right arrow)
    Point(2, 4), // Slot 3: Empty (Right arrow)
    Point(3, 4), // Coop Finish
  ];

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 4 cut-out pieces: 1 Down, 2 Right, 1 Down-then-Right elbow
    _partsBin = [
      DragPiece(id: 'p_down_1', type: 'down'),
      DragPiece(id: 'p_right_1', type: 'right'),
      DragPiece(id: 'p_elbow_1', type: 'down_right_elbow'),
      DragPiece(id: 'p_right_2', type: 'right'),
    ];
  }

  void _handleDrop(int slotIndex, DragPiece piece) {
    HapticService.light();
    SoundService.playSuccess();

    setState(() {
      // If slot was already filled, put the old piece back to parts bin
      final oldPiece = _placedSlots[slotIndex];
      if (oldPiece != null) {
        oldPiece.isPlaced = false;
      }

      // Mark new piece as placed
      piece.isPlaced = true;
      _placedSlots[slotIndex] = piece;
    });
  }

  void _clearSlot(int slotIndex) {
    if (_isRunning) return;
    final piece = _placedSlots[slotIndex];
    if (piece == null) return;

    HapticService.light();
    setState(() {
      piece.isPlaced = false;
      _placedSlots[slotIndex] = null;
    });
  }

  void _runSequence() async {
    if (_isRunning) return;
    
    HapticService.light();
    setState(() {
      _isRunning = true;
      _currentPathIndex = 0;
    });

    // Animate chicken step-by-step
    for (int i = 0; i < _path.length; i++) {
      setState(() {
        _currentPathIndex = i;
      });

      // Play walking sound / haptic tick
      HapticService.light();
      SoundService.playSuccess(); // soft walking sound equivalent

      await Future.delayed(const Duration(milliseconds: 550));

      // Validate placed path if we are at slot positions
      if (i == 7) {
        // Slot 0: Needs 'down'
        if (_placedSlots[0]?.type != 'down') {
          _triggerFailure();
          return;
        }
      } else if (i == 8) {
        // Slot 1: Needs 'down_right_elbow'
        if (_placedSlots[1]?.type != 'down_right_elbow') {
          _triggerFailure();
          return;
        }
      } else if (i == 9) {
        // Slot 2: Needs 'right'
        if (_placedSlots[2]?.type != 'right') {
          _triggerFailure();
          return;
        }
      } else if (i == 10) {
        // Slot 3: Needs 'right'
        if (_placedSlots[3]?.type != 'right') {
          _triggerFailure();
          return;
        }
      }
    }

    // Success! Chicken reached the coop!
    _onLevelComplete();
  }

  void _triggerFailure() async {
    SoundService.playError();
    HapticService.failure();

    // Show error toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ayam Jago tersesat! Yuk perbaiki jalannya!',
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
      await UserService.updateProgress(45);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 45: $e');
    }

    if (!mounted) return;

    // 3. Show success victory dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'ChickenSuccess',
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
                      'PETOK-PETOK! BERHASIL!',
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hebat! Ayam Jago berhasil bertemu Ayam Betina dengan jalur yang benar!',
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
                        Navigator.pop(context); // close level 45 screen
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
      backgroundColor: const Color(0xFFE2F0D9), // Light pasture green background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 4),
            // Play Area (Grid Pathway & Characters)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA2D27A), // Grass pasture green container
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFF7CA658), width: 6.0),
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

                      // Standard grid size mapping: 4 columns wide, 5 rows high
                      final double cellW = gridW / 4;
                      final double cellH = gridH / 5;

                      return Stack(
                        children: [
                          // 1. Draw static grid pathway cells
                          _buildStaticCell(0, 1, 'right', cellW, cellH),
                          _buildStaticCell(0, 2, 'right_down_elbow', cellW, cellH),
                          _buildStaticCell(1, 2, 'down', cellW, cellH),
                          _buildStaticCell(2, 2, 'down_left_elbow', cellW, cellH),
                          _buildStaticCell(2, 1, 'left', cellW, cellH),
                          _buildStaticCell(2, 0, 'left_down_elbow', cellW, cellH),

                          // 2. Draw drag targets/placed cells for the 4 slots
                          _buildDropSlot(0, 3, 0, cellW, cellH, 'down'),
                          _buildDropSlot(1, 4, 0, cellW, cellH, 'down_right_elbow'),
                          _buildDropSlot(2, 4, 1, cellW, cellH, 'right'),
                          _buildDropSlot(3, 4, 2, cellW, cellH, 'right'),

                          // 3. Draw static start/finish points
                          _buildStaticStart(0, 0, cellW, cellH), // Rooster Nest
                          _buildStaticFinish(4, 3, cellW, cellH), // Coop with Hen

                          // 4. Draw walking Rooster character overlay
                          _buildRoosterCharacter(cellW, cellH),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildControlBar(),
            const SizedBox(height: 8),
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
              'Level 45',
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
          const Icon(Icons.navigation_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Lengkapi jalan Ayam Jago agar bisa sampai ke kandang Ayam Betina!',
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

  Widget _buildStaticStart(int col, int row, double w, double h) {
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
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.egg_rounded, color: Colors.white70, size: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticFinish(int col, int row, double w, double h) {
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
            color: const Color(0xFFC0392B), // Coop red body
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7F8C8D), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Hen face peek inside
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '🐔',
                    style: TextStyle(fontSize: w * 0.38),
                  ),
                ),
              ),
              // Nest base
              Positioned(
                bottom: 2,
                left: 4,
                right: 4,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticCell(int row, int col, String type, double w, double h) {
    return Positioned(
      left: col * w,
      top: row * h,
      width: w,
      height: h,
      child: Center(
        child: Container(
          width: w * 0.88,
          height: h * 0.88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: ChickenArrowPainter(type: type),
          ),
        ),
      ),
    );
  }

  Widget _buildDropSlot(int slotIndex, int row, int col, double w, double h, String targetType) {
    final placedPiece = _placedSlots[slotIndex];

    return Positioned(
      left: col * w,
      top: row * h,
      width: w,
      height: h,
      child: Center(
        child: DragTarget<DragPiece>(
          onWillAccept: (data) => data != null && !_isRunning,
          onAccept: (data) => _handleDrop(slotIndex, data),
          builder: (context, candidateData, rejectedData) {
            final bool isHovering = candidateData.isNotEmpty;

            return GestureDetector(
              onTap: () => _clearSlot(slotIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: w * 0.88,
                height: h * 0.88,
                decoration: BoxDecoration(
                  color: placedPiece != null 
                      ? Colors.white 
                      : (isHovering ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHovering 
                        ? Colors.white 
                        : (placedPiece != null ? Colors.white : Colors.white.withOpacity(0.5)),
                    width: isHovering ? 4.0 : 2.0,
                    style: placedPiece != null ? BorderStyle.none : BorderStyle.solid,
                  ),
                  boxShadow: [
                    if (isHovering)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                  ],
                ),
                child: placedPiece != null
                    ? CustomPaint(
                        painter: ChickenArrowPainter(type: placedPiece.type),
                      )
                    : (isHovering
                        ? const Icon(Icons.add_rounded, color: Colors.white, size: 28)
                        : null),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoosterCharacter(double w, double h) {
    final currentPos = _path[_currentPathIndex];
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
          width: w * 0.76,
          height: h * 0.76,
          decoration: BoxDecoration(
            color: Colors.amber.shade700.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '🐓',
              style: TextStyle(fontSize: w * 0.44),
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

  Widget _buildPartsBin() {
    final activeBinPieces = _partsBin.where((p) => !p.isPlaced).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      height: 120,
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
            'PARTS BIN (SERET PANAH NAIK JALUR)',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: activeBinPieces.isEmpty
                ? Center(
                    child: Text(
                      'Semua potongan sudah ditempel!',
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeBinPieces.length,
                    itemBuilder: (context, idx) {
                      final piece = activeBinPieces[idx];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Draggable<DragPiece>(
                          data: piece,
                          feedback: _buildDraggableFeedback(piece.type),
                          childWhenDragging: Opacity(
                            opacity: 0.35,
                            child: _buildDraggableBase(piece.type),
                          ),
                          child: _buildDraggableBase(piece.type),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableBase(String type) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2.0),
      ),
      child: CustomPaint(
        painter: ChickenArrowPainter(type: type),
      ),
    );
  }

  Widget _buildDraggableFeedback(String type) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: ChickenArrowPainter(type: type),
        ),
      ),
    );
  }
}

class ChickenArrowPainter extends CustomPainter {
  final String type;
  static const Color arrowColor = Color(0xFF22C55E); // Green arrows

  ChickenArrowPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double headW = w * 0.40;
    final double tailH = h * 0.40;

    switch (type) {
      case 'right':
        // Straight arrow pointing Right
        final path = Path()
          ..moveTo(w * 0.1, (h - tailH) / 2)
          ..lineTo(w - headW, (h - tailH) / 2)
          ..lineTo(w - headW, h * 0.15)
          ..lineTo(w - w * 0.1, h / 2)
          ..lineTo(w - headW, h - h * 0.15)
          ..lineTo(w - headW, (h + tailH) / 2)
          ..lineTo(w * 0.1, (h + tailH) / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;

      case 'down':
        // Straight arrow pointing Down
        final path = Path()
          ..moveTo((w - tailH) / 2, h * 0.1)
          ..lineTo((w - tailH) / 2, h - headW)
          ..lineTo(w * 0.15, h - headW)
          ..lineTo(w / 2, h - h * 0.1)
          ..lineTo(w - w * 0.15, h - headW)
          ..lineTo((w + tailH) / 2, h - headW)
          ..lineTo((w + tailH) / 2, h * 0.1)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;

      case 'left':
        // Straight arrow pointing Left
        final path = Path()
          ..moveTo(w - w * 0.1, (h - tailH) / 2)
          ..lineTo(headW, (h - tailH) / 2)
          ..lineTo(headW, h * 0.15)
          ..lineTo(w * 0.1, h / 2)
          ..lineTo(headW, h - h * 0.15)
          ..lineTo(headW, (h + tailH) / 2)
          ..lineTo(w - w * 0.1, (h + tailH) / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;

      case 'right_down_elbow':
        // Elbow starting right, turning down
        final path = Path()
          ..moveTo(w * 0.15, (h - tailH) / 2)
          ..lineTo((w + tailH) / 2, (h - tailH) / 2)
          ..lineTo((w + tailH) / 2, h - headW)
          ..lineTo(w - w * 0.15, h - headW)
          ..lineTo(w / 2, h - h * 0.1)
          ..lineTo(w * 0.15, h - headW)
          ..lineTo((w - tailH) / 2, h - headW)
          ..lineTo((w - tailH) / 2, (h + tailH) / 2)
          ..lineTo(w * 0.15, (h + tailH) / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;

      case 'down_left_elbow':
        // Elbow starting down, turning left
        final path = Path()
          ..moveTo((w - tailH) / 2, h * 0.15)
          ..lineTo((w + tailH) / 2, h * 0.15)
          ..lineTo((w + tailH) / 2, (h + tailH) / 2)
          ..lineTo(headW, (h + tailH) / 2)
          ..lineTo(headW, h - h * 0.15)
          ..lineTo(w * 0.1, h / 2)
          ..lineTo(headW, h * 0.15)
          ..lineTo(headW, (h - tailH) / 2)
          ..lineTo((w - tailH) / 2, (h - tailH) / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;

      case 'left_down_elbow':
        // Elbow starting left, turning down
        final path = Path()
          ..moveTo(w - w * 0.15, (h - tailH) / 2)
          ..lineTo((w - tailH) / 2, (h - tailH) / 2)
          ..lineTo((w - tailH) / 2, h - headW)
          ..lineTo(w * 0.15, h - headW)
          ..lineTo(w / 2, h - h * 0.1)
          ..lineTo(w - w * 0.15, h - headW)
          ..lineTo((w + tailH) / 2, h - headW)
          ..lineTo((w + tailH) / 2, (h + tailH) / 2)
          ..lineTo(w - w * 0.15, (h + tailH) / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;

      case 'down_right_elbow':
      default:
        // Elbow starting down, turning right (L-shape)
        final path = Path()
          ..moveTo((w - tailH) / 2, h * 0.15)
          ..lineTo((w + tailH) / 2, h * 0.15)
          ..lineTo((w + tailH) / 2, (h - tailH) / 2)
          ..lineTo(w - headW, (h - tailH) / 2)
          ..lineTo(w - headW, h * 0.15)
          ..lineTo(w - w * 0.1, h / 2)
          ..lineTo(w - headW, h - h * 0.15)
          ..lineTo(w - headW, (h + tailH) / 2)
          ..lineTo((w - tailH) / 2, (h + tailH) / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, borderPaint);
        break;
    }

    // Subtle 3D gloss overlay highlights
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.35, h * 0.35), min(w, h) * 0.12, glossPaint);
  }

  @override
  bool shouldRepaint(covariant ChickenArrowPainter oldDelegate) {
    return oldDelegate.type != type;
  }
}
