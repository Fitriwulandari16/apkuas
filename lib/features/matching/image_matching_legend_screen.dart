import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class ImageMatchingLegendScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ImageMatchingLegendScreen({super.key, this.levelId = 19});

  @override
  ConsumerState<ImageMatchingLegendScreen> createState() => _ImageMatchingLegendScreenState();
}

class _BoxData {
  final int id;
  final bool isLarge; // true: Besar (Biru), false: Kecil (Merah)
  bool isColored;
  Color? currentColor;

  _BoxData({required this.id, required this.isLarge}) : isColored = false;
}

class _ImageMatchingLegendScreenState extends ConsumerState<ImageMatchingLegendScreen> with TickerProviderStateMixin {
  late List<_BoxData> _boxes;
  late Map<int, AnimationController> _pulseControllers;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Premium colors corresponding to the textbook illustrations:
  // Besar = Ocean Blue
  // Kecil = Coral Red
  static const Color colLargeTarget = Color(0xFF3EA5E1); // Biru Ocean
  static const Color colSmallTarget = Color(0xFFE76F51); // Merah Coral

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 15 target boxes arranged exactly like the textbook illustration layout:
    // Row 1: Large (Left), Small (Middle), Small (Right)
    // Row 2: Small (Left), Small (Middle), Large (Right)
    // Row 3: Small (Left), Large (Middle), Small (Right)
    // Row 4: Large (Left), Small (Middle), Large (Right)
    // Row 5: Small (Left), Large (Middle), Small (Right)
    _boxes = [
      // Row 1
      _BoxData(id: 1, isLarge: true),
      _BoxData(id: 2, isLarge: false),
      _BoxData(id: 3, isLarge: false),
      // Row 2
      _BoxData(id: 4, isLarge: false),
      _BoxData(id: 5, isLarge: false),
      _BoxData(id: 6, isLarge: true),
      // Row 3
      _BoxData(id: 7, isLarge: false),
      _BoxData(id: 8, isLarge: true),
      _BoxData(id: 9, isLarge: false),
      // Row 4
      _BoxData(id: 10, isLarge: true),
      _BoxData(id: 11, isLarge: false),
      _BoxData(id: 12, isLarge: true),
      // Row 5
      _BoxData(id: 13, isLarge: false),
      _BoxData(id: 14, isLarge: true),
      _BoxData(id: 15, isLarge: false),
    ];

    _pulseControllers = {};
    for (var box in _boxes) {
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
      // Try playing a local sound file first
      await _audioPlayer.play(AssetSource('sounds/ting.mp3'));
    } catch (_) {
      try {
        // Fallback to online short pleasant ting/bell sound
        await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2568/2568-84.wav'));
      } catch (e) {
        debugPrint('Could not play ting sound: $e');
      }
    }
  }

  void _handleDrop(Color draggedColor, _BoxData box) {
    if (box.isColored) return;

    // Validate size and color matching
    final bool isValid = (box.isLarge && draggedColor == colLargeTarget) ||
                         (!box.isLarge && draggedColor == colSmallTarget);

    if (isValid) {
      HapticService.success();
      _playTingSound();

      setState(() {
        box.isColored = true;
        box.currentColor = draggedColor;
      });

      _pulseControllers[box.id]!.forward().then((_) {
        _pulseControllers[box.id]!.reverse();
      });

      // Check if all boxes are colored to win
      if (_boxes.every((b) => b.isColored)) {
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
      nextLevelId: 20,
      title: 'Luar Biasa!',
      message: 'Kamu berhasil mewarnai semua kotak dengan sangat rapi!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable main content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildInstruction(),
                  
                  // Static Legend/Guide Card at the top
                  _buildLegendCard(),
                  
                  // Play Area: Grid of empty rectangles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      children: [
                        _buildGameRow([_boxes[0], _boxes[1], _boxes[2]]),
                        _buildGameRow([_boxes[3], _boxes[4], _boxes[5]]),
                        _buildGameRow([_boxes[6], _boxes[7], _boxes[8]]),
                        _buildGameRow([_boxes[9], _boxes[10], _boxes[11]]),
                        _buildGameRow([_boxes[12], _boxes[13], _boxes[14]]),
                      ],
                    ),
                  ),

                  // Bottom spacer so that the lowest rows aren't covered by the floating footer dock
                  const SizedBox(height: 140),
                ],
              ),
            ),
            
            // Sticky Footer: Color Dock at the bottom
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
              'Level 19',
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
          const Icon(Icons.palette_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Lihat contoh dan warnai kotak sesuai ukurannya!',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pre-colored Large Blue Box
          Column(
            children: [
              Container(
                width: 120,
                height: 70,
                decoration: BoxDecoration(
                  color: colLargeTarget,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: colLargeTarget.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kotak Besar',
                style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              )
            ],
          ),
          
          // Vertical divider
          Container(width: 2, height: 60, color: Colors.grey.shade200),

          // Pre-colored Small Red Box
          Column(
            children: [
              Container(
                width: 70,
                height: 40,
                decoration: BoxDecoration(
                  color: colSmallTarget,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: colSmallTarget.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kotak Kecil',
                style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameRow(List<_BoxData> rowBoxes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: rowBoxes.map((box) => _buildBoxTarget(box)).toList(),
      ),
    );
  }

  Widget _buildBoxTarget(_BoxData box) {
    // Large: 120x70, Small: 70x40
    final double targetWidth = box.isLarge ? 120 : 70;
    final double targetHeight = box.isLarge ? 70 : 40;

    return DragTarget<Color>(
      onWillAcceptWithDetails: (details) {
        if (box.isColored) return false;
        // Accept only the matching color for the corresponding size
        final bool isValid = (box.isLarge && details.data == colLargeTarget) ||
                             (!box.isLarge && details.data == colSmallTarget);
        return isValid;
      },
      onAcceptWithDetails: (details) => _handleDrop(details.data, box),
      builder: (context, candidateData, rejectedData) {
        return ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.15).animate(
            CurvedAnimation(
              parent: _pulseControllers[box.id]!,
              curve: Curves.elasticOut,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: targetWidth,
            height: targetHeight,
            decoration: BoxDecoration(
              color: box.isColored ? box.currentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(box.isLarge ? 16 : 10),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.teal.shade300
                    : (box.isColored ? Colors.transparent : Colors.grey.shade400),
                width: candidateData.isNotEmpty ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: box.isColored
                      ? box.currentColor!.withOpacity(0.3)
                      : Colors.black.withOpacity(0.01),
                  blurRadius: box.isColored ? 8 : 4,
                  offset: const Offset(0, 2),
                )
              ],
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfiniteDraggableColor(colLargeTarget, 'Biru (Besar)'),
          _buildInfiniteDraggableColor(colSmallTarget, 'Merah (Kecil)'),
        ],
      ),
    );
  }

  Widget _buildInfiniteDraggableColor(Color color, String label) {
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
