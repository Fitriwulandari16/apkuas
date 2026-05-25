import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class DiceDebuggingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const DiceDebuggingScreen({super.key, this.levelId = 23});

  @override
  ConsumerState<DiceDebuggingScreen> createState() => _DiceDebuggingScreenState();
}

class _DiceData {
  final int id;
  final Color diceColor;   // The dice body color
  final int actualDots;    // The number of dots actually displayed
  final int expectedDots;  // The number of dots that SHOULD be displayed for this color
  final bool isBug;        // true = this dice has a bug (wrong dot count)
  bool isCrossedOut;       // true = player marked this as a bug

  _DiceData({
    required this.id,
    required this.diceColor,
    required this.actualDots,
    required this.expectedDots,
    required this.isBug,
  }) : isCrossedOut = false;
}

class _DiceDebuggingScreenState extends ConsumerState<DiceDebuggingScreen> with TickerProviderStateMixin {
  late List<_DiceData> _diceGrid;
  late Map<int, AnimationController> _shakeControllers;
  late Map<int, AnimationController> _crossControllers;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _bugsFound = 0;

  // Dice color reference:
  // Merah = 1 titik, Biru = 2 titik, Kuning = 3 titik
  static const Color colRed    = Color(0xFFE76F51); // Merah
  static const Color colBlue   = Color(0xFF3EA5E1); // Biru
  static const Color colYellow = Color(0xFFFBC02D); // Kuning

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 12 dice arranged in a 3x4 grid.
    // 10 correct + 2 bugs.
    // Bug 1: Blue dice showing 3 dots (should be 2)
    // Bug 2: Yellow dice showing 1 dot (should be 3)
    _diceGrid = [
      // Row 1
      _DiceData(id: 0,  diceColor: colRed,    actualDots: 1, expectedDots: 1, isBug: false),
      _DiceData(id: 1,  diceColor: colBlue,   actualDots: 2, expectedDots: 2, isBug: false),
      _DiceData(id: 2,  diceColor: colYellow,  actualDots: 3, expectedDots: 3, isBug: false),
      // Row 2
      _DiceData(id: 3,  diceColor: colYellow,  actualDots: 3, expectedDots: 3, isBug: false),
      _DiceData(id: 4,  diceColor: colBlue,   actualDots: 3, expectedDots: 2, isBug: true),  // BUG: Blue showing 3 dots
      _DiceData(id: 5,  diceColor: colRed,    actualDots: 1, expectedDots: 1, isBug: false),
      // Row 3
      _DiceData(id: 6,  diceColor: colRed,    actualDots: 1, expectedDots: 1, isBug: false),
      _DiceData(id: 7,  diceColor: colYellow,  actualDots: 3, expectedDots: 3, isBug: false),
      _DiceData(id: 8,  diceColor: colBlue,   actualDots: 2, expectedDots: 2, isBug: false),
      // Row 4
      _DiceData(id: 9,  diceColor: colBlue,   actualDots: 2, expectedDots: 2, isBug: false),
      _DiceData(id: 10, diceColor: colYellow,  actualDots: 1, expectedDots: 3, isBug: true),  // BUG: Yellow showing 1 dot
      _DiceData(id: 11, diceColor: colRed,    actualDots: 1, expectedDots: 1, isBug: false),
    ];

    _shakeControllers = {};
    _crossControllers = {};
    for (var dice in _diceGrid) {
      _shakeControllers[dice.id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _crossControllers[dice.id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  @override
  void dispose() {
    for (var c in _shakeControllers.values) {
      c.dispose();
    }
    for (var c in _crossControllers.values) {
      c.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playTingSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/ting.mp3'));
    } catch (_) {
      try {
        await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2568/2568-84.wav'));
      } catch (e) {
        debugPrint('Could not play ting sound: $e');
      }
    }
  }

  void _handleTap(_DiceData dice) {
    if (dice.isCrossedOut) return;

    if (dice.isBug) {
      // Correct! The player found a bug
      HapticService.success();
      _playTingSound();

      setState(() {
        dice.isCrossedOut = true;
        _bugsFound++;
      });

      // Animate the cross appearing
      _crossControllers[dice.id]!.forward();

      // Check completion
      if (_bugsFound >= 2) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _onLevelComplete();
        });
      }
    } else {
      // Wrong! This dice is actually correct
      HapticService.failure();

      // Shake animation to indicate wrong choice
      _shakeControllers[dice.id]!.forward().then((_) {
        _shakeControllers[dice.id]!.reverse();
      });
    }
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 24,
      title: 'Kamu Programmer Hebat!',
      message: 'Semua bug berhasil ditemukan dan diperbaiki!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildInstruction(),
              _buildLegendCard(),
              _buildProgressIndicator(),
              _buildGrid(),
              const SizedBox(height: 40),
            ],
          ),
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
              'Level 23',
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bug_report_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Temukan dadu yang salah dan silang!',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(
            'Aturan Pola',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendDice(colRed, 1, 'Merah = 1'),
              _buildLegendDice(colBlue, 2, 'Biru = 2'),
              _buildLegendDice(colYellow, 3, 'Kuning = 3'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDice(Color color, int dots, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: CustomPaint(
            painter: DiceDotsPainter(dotCount: dots),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _bugsFound / 2,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _bugsFound >= 2 ? Colors.teal : Colors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$_bugsFound / 2 Bug',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _bugsFound >= 2 ? Colors.teal : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.0,
        ),
        itemCount: _diceGrid.length,
        itemBuilder: (context, index) {
          return _buildDiceTile(_diceGrid[index]);
        },
      ),
    );
  }

  Widget _buildDiceTile(_DiceData dice) {
    return AnimatedBuilder(
      animation: _shakeControllers[dice.id]!,
      builder: (context, child) {
        final double shakeOffset = sin(_shakeControllers[dice.id]!.value * 3 * pi) * 6;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _handleTap(dice),
        child: Stack(
          children: [
            // Dice body
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: dice.diceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dice.isCrossedOut ? Colors.red.shade400 : Colors.transparent,
                  width: dice.isCrossedOut ? 3.0 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: dice.isCrossedOut
                        ? Colors.red.withOpacity(0.2)
                        : dice.diceColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: CustomPaint(
                painter: DiceDotsPainter(dotCount: dice.actualDots),
                child: const SizedBox.expand(),
              ),
            ),

            // Cross-out overlay animation
            if (dice.isCrossedOut)
              Positioned.fill(
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _crossControllers[dice.id]!,
                    curve: Curves.easeOut,
                  ),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _crossControllers[dice.id]!,
                      curve: Curves.elasticOut,
                    ),
                    child: CustomPaint(
                      painter: CrossMarkPainter(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paints dice dots (1, 2, or 3) in classic dice layout positions
class DiceDotsPainter extends CustomPainter {
  final int dotCount;

  DiceDotsPainter({required this.dotCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double dotRadius = size.width * 0.1;
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double offset = size.width * 0.25;

    switch (dotCount) {
      case 1:
        // Center dot
        canvas.drawCircle(Offset(cx, cy), dotRadius, paint);
        break;
      case 2:
        // Top-right and bottom-left
        canvas.drawCircle(Offset(cx + offset, cy - offset), dotRadius, paint);
        canvas.drawCircle(Offset(cx - offset, cy + offset), dotRadius, paint);
        break;
      case 3:
        // Top-right, center, bottom-left (diagonal)
        canvas.drawCircle(Offset(cx + offset, cy - offset), dotRadius, paint);
        canvas.drawCircle(Offset(cx, cy), dotRadius, paint);
        canvas.drawCircle(Offset(cx - offset, cy + offset), dotRadius, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DiceDotsPainter oldDelegate) => oldDelegate.dotCount != dotCount;
}

/// Paints a large red "X" cross mark over a dice
class CrossMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double inset = size.width * 0.18;

    // Draw X
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CrossMarkPainter oldDelegate) => false;
}
