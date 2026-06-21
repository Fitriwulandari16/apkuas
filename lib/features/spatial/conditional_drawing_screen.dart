import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class ConditionalDrawingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ConditionalDrawingScreen({super.key, this.levelId = 6});

  @override
  ConsumerState<ConditionalDrawingScreen> createState() => _ConditionalDrawingScreenState();
}

class _ConditionalDrawingScreenState extends ConsumerState<ConditionalDrawingScreen> {
  // Grid layout (5 rows x 4 columns)
  // Y = Yellow, P = Pink
  final List<List<String>> grid = [
    ['P', 'Y', 'P', 'Y'],
    ['Y', 'P', 'Y', 'P'],
    ['P', 'Y', 'P', 'Y'],
    ['P', 'Y', 'P', 'Y'],
    ['Y', 'P', 'Y', 'P'],
  ];

  Map<String, bool> completionStatus = {};

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    completionStatus = {};
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        completionStatus['$r-$c'] = false;
      }
    }
  }

  void _resetLevel() {
    setState(() {
      _initLevel();
    });
  }

  void _onSuccess(int r, int c) {
    setState(() {
      completionStatus['$r-$c'] = true;
    });
    SoundService.playSuccess();
    HapticService.success();
    _checkWin();
  }

  void _checkWin() {
    if (completionStatus.values.every((v) => v == true)) {
      ref.read(progressProvider.notifier).completeLevel(widget.levelId);
      CelebrationUtils.showCelebrationAndLevelUp(
        context: context,
        nextLevelId: 7,
        title: 'HEBAT! 🌟',
        message: 'Level 6 Selesai! Kamu memahami algoritma kondisional!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FBF9),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              
              // Clean Legend Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blue.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'KUNCI PETUNJUK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.blueGrey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem(const Color(0xFFFFD54F), 'Geser Tegak'),
                        _buildLegendItem(const Color(0xFFEC407A), 'Geser Datar'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Buat garis tepat pada warna sesuai contoh!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 12),

              // Game Grid
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(grid.length, (r) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(grid[r].length, (c) {
                              return _ConditionalCircle(
                                row: r,
                                col: c,
                                type: grid[r][c],
                                isCompleted: completionStatus['$r-$c'] ?? false,
                                onSuccess: () => _onSuccess(r, c),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),

              // Palet Garis (Bottom Line Palette)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDraggableLine('vertical', 'Garis Vertikal (|)'),
                    const SizedBox(width: 32),
                    _buildDraggableLine('horizontal', 'Garis Horizontal (—)'),
                  ],
                ),
              ),

              // Centered Ulangi Button
              Center(
                child: TextButton.icon(
                  onPressed: _resetLevel,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.blueGrey, size: 20),
                  label: const Text(
                    'Ulangi',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
              'Algoritma: Kondisional',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
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

  Widget _buildLegendItem(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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

  Widget _buildDraggableLine(String type, String label) {
    final isVertical = type == 'vertical';
    return Draggable<String>(
      key: ValueKey('draggable_line_$type'),
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: _PaletteLineWidget(isVertical: isVertical),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _PaletteLineWidget(isVertical: isVertical),
      ),
      child: _PaletteLineWidget(isVertical: isVertical),
    );
  }
}

class _PaletteLineWidget extends StatelessWidget {
  final bool isVertical;
  const _PaletteLineWidget({required this.isVertical});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Center(
        child: Container(
          width: isVertical ? 6 : 30,
          height: isVertical ? 30 : 6,
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _ConditionalCircle extends StatefulWidget {
  final int row;
  final int col;
  final String type;
  final bool isCompleted;
  final VoidCallback onSuccess;

  const _ConditionalCircle({
    required this.row,
    required this.col,
    required this.type,
    required this.isCompleted,
    required this.onSuccess,
  });

  @override
  State<_ConditionalCircle> createState() => _ConditionalCircleState();
}

class _ConditionalCircleState extends State<_ConditionalCircle> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isYellow = widget.type == 'Y';

    return DragTarget<String>(
      key: ValueKey('target_circle_${widget.row}_${widget.col}'),
      onWillAccept: (data) => !widget.isCompleted,
      onAccept: (data) {
        bool correct = false;
        if (widget.type == 'Y' && data == 'vertical') {
          correct = true;
        } else if (widget.type == 'P' && data == 'horizontal') {
          correct = true;
        }

        if (correct) {
          widget.onSuccess();
        } else {
          HapticFeedback.lightImpact();
          _shakeController.forward(from: 0);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final double offset = math.sin(_shakeController.value * math.pi * 4) * 8 * (1 - _shakeController.value);
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isYellow
                    ? [
                        const Color(0xFFFFF176),
                        const Color(0xFFFBC02D),
                      ]
                    : [
                        const Color(0xFFF06292),
                        const Color(0xFFC2185B),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Stack(
              children: [
                // Top-left glossy highlight
                Positioned(
                  top: 6,
                  left: 8,
                  child: Container(
                    width: 14,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: const BorderRadius.all(Radius.elliptical(7, 4)),
                    ),
                  ),
                ),
                // Completed thick white line in center
                if (widget.isCompleted)
                  Center(
                    child: Container(
                      width: isYellow ? 8 : 36,
                      height: isYellow ? 36 : 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
