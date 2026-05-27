import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/services/sound_service.dart';

class CircleMatchingSizeScreen extends ConsumerStatefulWidget {
  final int levelId;
  const CircleMatchingSizeScreen({super.key, this.levelId = 20});

  @override
  ConsumerState<CircleMatchingSizeScreen> createState() => _CircleMatchingSizeScreenState();
}

enum CircleSize { large, medium, small }

class _CircleData {
  final int id;
  final CircleSize size;
  bool isColored;
  Color? currentColor;

  _CircleData({required this.id, required this.size}) : isColored = false;
}

class _CircleMatchingSizeScreenState extends ConsumerState<CircleMatchingSizeScreen> with TickerProviderStateMixin {
  late List<_CircleData> _circles;
  late Map<int, AnimationController> _pulseControllers;


  // Premium colors corresponding to the textbook illustration:
  // Besar = Oranye / Cokelat Hangat
  // Sedang = Biru Langit
  // Kecil = Kuning Terang
  static const Color colLargeTarget = Color(0xFFE67E22);  // Oranye/Cokelat Hangat
  static const Color colMediumTarget = Color(0xFF3498DB); // Biru Langit
  static const Color colSmallTarget = Color(0xFFF1C40F);  // Kuning Terang

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 19 circles with 3 sizes arranged exactly like the textbook illustration layout:
    // Row 1: Small, Medium, Large, Small
    // Row 2: Large, Medium, Small, Medium
    // Row 3: Medium, Large, Small, Large
    // Row 4: Small, Medium, Large, Medium
    // Row 5: Large, Medium, Large, Small
    _circles = [
      // Row 1
      _CircleData(id: 1, size: CircleSize.small),
      _CircleData(id: 2, size: CircleSize.medium),
      _CircleData(id: 3, size: CircleSize.large),
      _CircleData(id: 4, size: CircleSize.small),
      // Row 2
      _CircleData(id: 5, size: CircleSize.large),
      _CircleData(id: 6, size: CircleSize.medium),
      _CircleData(id: 7, size: CircleSize.small),
      _CircleData(id: 8, size: CircleSize.medium),
      // Row 3
      _CircleData(id: 9, size: CircleSize.medium),
      _CircleData(id: 10, size: CircleSize.large),
      _CircleData(id: 11, size: CircleSize.small),
      _CircleData(id: 12, size: CircleSize.large),
      // Row 4
      _CircleData(id: 13, size: CircleSize.small),
      _CircleData(id: 14, size: CircleSize.medium),
      _CircleData(id: 15, size: CircleSize.large),
      _CircleData(id: 16, size: CircleSize.medium),
      // Row 5
      _CircleData(id: 17, size: CircleSize.large),
      _CircleData(id: 18, size: CircleSize.medium),
      _CircleData(id: 19, size: CircleSize.large),
      _CircleData(id: 20, size: CircleSize.small),
    ];

    _pulseControllers = {};
    for (var circle in _circles) {
      _pulseControllers[circle.id] = AnimationController(
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
    super.dispose();
  }

  void _handleDrop(Color draggedColor, _CircleData circle) {
    if (circle.isColored) return;

    // Validate size and color matching
    final bool isValid = (circle.size == CircleSize.large && draggedColor == colLargeTarget) ||
                         (circle.size == CircleSize.medium && draggedColor == colMediumTarget) ||
                         (circle.size == CircleSize.small && draggedColor == colSmallTarget);

    if (isValid) {
      HapticService.success();
      SoundService.playSuccess();

      setState(() {
        circle.isColored = true;
        circle.currentColor = draggedColor;
      });

      _pulseControllers[circle.id]!.forward().then((_) {
        _pulseControllers[circle.id]!.reverse();
      });

      // Check if all circles are colored to win
      if (_circles.every((c) => c.isColored)) {
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
      nextLevelId: 21,
      title: 'Luar Biasa!',
      message: 'Kamu berhasil mewarnai semua lingkaran dengan sangat rapi!',
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
                  
                  // Play Area: Grid of empty circle outlines
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      children: [
                        _buildGameRow([_circles[0], _circles[1], _circles[2], _circles[3]]),
                        _buildGameRow([_circles[4], _circles[5], _circles[6], _circles[7]]),
                        _buildGameRow([_circles[8], _circles[9], _circles[10], _circles[11]]),
                        _buildGameRow([_circles[12], _circles[13], _circles[14], _circles[15]]),
                        _buildGameRow([_circles[16], _circles[17], _circles[18], _circles[19]]),
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
              'Level 20',
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
          const Icon(Icons.palette_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Lihat contoh dan warnai lingkaran sesuai ukurannya!',
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

  Widget _buildLegendCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Besar (Oranye)
          _buildLegendCircle(90, colLargeTarget, 'Besar'),
          // Sedang (Biru)
          _buildLegendCircle(65, colMediumTarget, 'Sedang'),
          // Kecil (Kuning)
          _buildLegendCircle(40, colSmallTarget, 'Kecil'),
        ],
      ),
    );
  }

  Widget _buildLegendCircle(double size, Color color, String label) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade600,
          ),
        )
      ],
    );
  }

  Widget _buildGameRow(List<_CircleData> rowCircles) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: rowCircles.map((circle) => _buildCircleTarget(circle)).toList(),
      ),
    );
  }

  Widget _buildCircleTarget(_CircleData circle) {
    // Exact sizing for circles: Large (100), Medium (70), Small (45)
    double diameter;
    switch (circle.size) {
      case CircleSize.large:
        diameter = 100;
        break;
      case CircleSize.medium:
        diameter = 70;
        break;
      case CircleSize.small:
        diameter = 45;
        break;
    }

    return DragTarget<Color>(
      onWillAcceptWithDetails: (details) {
        if (circle.isColored) return false;
        // Only accept if dropped color matches size target
        final bool isValid = (circle.size == CircleSize.large && details.data == colLargeTarget) ||
                             (circle.size == CircleSize.medium && details.data == colMediumTarget) ||
                             (circle.size == CircleSize.small && details.data == colSmallTarget);
        return isValid;
      },
      onAcceptWithDetails: (details) => _handleDrop(details.data, circle),
      builder: (context, candidateData, rejectedData) {
        return ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.15).animate(
            CurvedAnimation(
              parent: _pulseControllers[circle.id]!,
              curve: Curves.elasticOut,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              color: circle.isColored ? circle.currentColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.teal.shade300
                    : (circle.isColored ? Colors.transparent : Colors.grey.shade400),
                width: candidateData.isNotEmpty ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: circle.isColored
                      ? circle.currentColor!.withOpacity(0.3)
                      : Colors.black.withOpacity(0.01),
                  blurRadius: circle.isColored ? 8 : 4,
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
          _buildInfiniteDraggableColor(colLargeTarget, 'Oranye'),
          _buildInfiniteDraggableColor(colMediumTarget, 'Biru'),
          _buildInfiniteDraggableColor(colSmallTarget, 'Kuning'),
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
      width: 72,
      height: 72,
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
          size: 30,
        ),
      ),
    );
  }
}
