import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class LetterGridColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const LetterGridColoringScreen({super.key, this.levelId = 22});

  @override
  ConsumerState<LetterGridColoringScreen> createState() => _LetterGridColoringScreenState();
}

class _LetterBoxData {
  final int id;
  final String letter;
  final bool isTarget; // true for 'b', false for other lookalikes
  bool isColored;

  _LetterBoxData({
    required this.id,
    required this.letter,
    required this.isTarget,
  }) : isColored = false;
}

class _LetterGridColoringScreenState extends ConsumerState<LetterGridColoringScreen> with TickerProviderStateMixin {
  late List<_LetterBoxData> _letters;
  late Map<int, AnimationController> _pulseControllers;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Premium colors corresponding to the textbook:
  // Target color is Yellow / Orange-yellow
  static const Color colTargetColor = Color(0xFFFBC02D); // Kuning/Orange-yellow dari contoh buku

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 5x5 grid containing 5 target 'b' boxes and 20 lookalikes ('p', 'd', 'q')
    // Placed exactly as the diagonal-like layout in the textbook photo:
    // Row 1: p, d, q, p, b (target)
    // Row 2: b (target), q, p, d, q
    // Row 3: d, p, q, b (target), p
    // Row 4: p, b (target), d, q, d
    // Row 5: q, p, b (target), p, q
    final List<String> lettersLayout = [
      'p', 'd', 'q', 'p', 'b',
      'b', 'q', 'p', 'd', 'q',
      'd', 'p', 'q', 'b', 'p',
      'p', 'b', 'd', 'q', 'd',
      'q', 'p', 'b', 'p', 'q',
    ];

    _letters = List.generate(lettersLayout.length, (index) {
      final letter = lettersLayout[index];
      return _LetterBoxData(
        id: index,
        letter: letter,
        isTarget: letter == 'b',
      );
    });

    _pulseControllers = {};
    for (var box in _letters) {
      _pulseControllers[box.id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _pulseControllers.values) {
      controller.dispose();
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

  void _handleDrop(_LetterBoxData box, Color draggedColor) {
    if (box.isColored) return;

    if (box.isTarget && draggedColor == colTargetColor) {
      HapticService.success();
      _playTingSound();

      setState(() {
        box.isColored = true;
      });

      _pulseControllers[box.id]!.forward().then((_) {
        _pulseControllers[box.id]!.reverse();
      });

      // Check level completion
      final bool isAllCompleted = _letters.where((b) => b.isTarget).every((b) => b.isColored);
      if (isAllCompleted) {
        _onLevelComplete();
      }
    } else {
      HapticService.failure();
    }
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 23,
      title: 'Hebat!',
      message: 'Kamu berhasil menemukan semua huruf b dan mewarnainya!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SafeArea(
        child: Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildInstruction(),
                  
                  // Example card at the top
                  _buildExampleCard(),
                  
                  // Grid of Letters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _letters.length,
                      itemBuilder: (context, index) {
                        return _buildLetterBox(_letters[index]);
                      },
                    ),
                  ),

                  // Padding spacer so grid isn't blocked by the footer
                  const SizedBox(height: 140),
                ],
              ),
            ),

            // Sticky footer with the color bucket
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildColorDock(),
            ),
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
              'Level 22',
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
          const Icon(Icons.search_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Temukan huruf b dan warnai kotaknya seperti contoh!',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: colTargetColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colTargetColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    'b',
                    style: GoogleFonts.fredoka(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Contoh',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLetterBox(_LetterBoxData box) {
    return DragTarget<Color>(
      onWillAcceptWithDetails: (details) {
        if (box.isColored) return false;
        // Accept only the correct target color and match letter b
        final bool isValid = box.isTarget && details.data == colTargetColor;
        return isValid;
      },
      onAcceptWithDetails: (details) => _handleDrop(box, details.data),
      builder: (context, candidateData, rejectedData) {
        final bool isHovered = candidateData.isNotEmpty;

        return ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.15).animate(
            CurvedAnimation(
              parent: _pulseControllers[box.id]!,
              curve: Curves.elasticOut,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: box.isColored ? colTargetColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovered
                    ? Colors.teal.shade300
                    : (box.isColored ? Colors.transparent : Colors.grey.shade300),
                width: isHovered ? 3.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: box.isColored
                      ? colTargetColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.01),
                  blurRadius: box.isColored ? 8 : 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Text(
                box.letter,
                style: GoogleFonts.fredoka(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A5568),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorDock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInfiniteDraggableColor(colTargetColor),
        ],
      ),
    );
  }

  Widget _buildInfiniteDraggableColor(Color color) {
    return Draggable<Color>(
      data: color,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.25,
          child: _buildColorBucket(color, isShadow: true),
        ),
      ),
      childWhenDragging: _buildColorBucket(color),
      onDraggableCanceled: (velocity, offset) {
        HapticService.failure();
      },
      child: _buildColorBucket(color),
    );
  }

  Widget _buildColorBucket(Color color, {bool isShadow = false}) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: isShadow ? Colors.black38 : color.withOpacity(0.3),
            blurRadius: isShadow ? 12 : 6,
            offset: Offset(0, isShadow ? 6 : 2),
          )
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.format_paint_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
