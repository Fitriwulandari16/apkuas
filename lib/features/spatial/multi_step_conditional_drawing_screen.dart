import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class MultiStepConditionalDrawingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const MultiStepConditionalDrawingScreen({super.key, this.levelId = 7});

  @override
  ConsumerState<MultiStepConditionalDrawingScreen> createState() => _MultiStepConditionalDrawingScreenState();
}

class _MultiStepConditionalDrawingScreenState extends ConsumerState<MultiStepConditionalDrawingScreen> {
  // Grid layout (5 rows x 3 columns)
  // R = Red, B = Blue, Y = Yellow
  final List<List<String>> grid = [
    ['R', 'B', 'Y'],
    ['R', 'B', 'Y'],
    ['Y', 'R', 'B'],
    ['B', 'Y', 'R'],
    ['Y', 'R', 'B'],
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
      gameWin();
    }
  }

  void gameWin() {
    _onLevelComplete();
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    UserService.updateProgress(widget.levelId).catchError((e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    });

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 8,
      title: 'HEBAT! 🌟',
      message: 'Level 7 Selesai! Kamu menguasai kondisi multi-langkah!',
    );
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
                    Text(
                      'KUNCI PETUNJUK',
                      style: GoogleFonts.fredoka(
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
                        _buildLegendItem(const Color(0xFFEF5350), 'Datar'),
                        _buildLegendItem(const Color(0xFF42A5F5), 'Tegak'),
                        _buildLegendItem(const Color(0xFFFFF176), 'Tambah'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Perhatikan warnanya dan buat garis yang tepat!',
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth = constraints.maxWidth;
                          double diameter = ((maxWidth - 60) / 3).clamp(45.0, 75.0);

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(grid.length, (r) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(grid[r].length, (c) {
                                  return _ConditionalCircle(
                                    row: r,
                                    col: c,
                                    type: grid[r][c],
                                    size: diameter,
                                    isCompleted: completionStatus['$r-$c'] ?? false,
                                    onSuccess: () => _onSuccess(r, c),
                                  );
                                }),
                              );
                            }),
                          );
                        }
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
                    _buildDraggableLine('horizontal'),
                    const SizedBox(width: 24),
                    _buildDraggableLine('vertical'),
                    const SizedBox(width: 24),
                    _buildDraggableLine('plus'),
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
              'Algoritma: Kondisional Lanjut',
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

  Widget _buildDraggableLine(String type) {
    return Draggable<String>(
      key: ValueKey('draggable_line_$type'),
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: _PaletteLineWidget(type: type),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _PaletteLineWidget(type: type),
      ),
      child: _PaletteLineWidget(type: type),
    );
  }
}

class _PaletteLineWidget extends StatelessWidget {
  final String type;
  const _PaletteLineWidget({required this.type});

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
        child: _buildSymbol(),
      ),
    );
  }

  Widget _buildSymbol() {
    if (type == 'horizontal') {
      return Container(
        width: 30,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    } else if (type == 'vertical') {
      return Container(
        width: 6,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.blue.shade800,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    } else {
      // 'plus'
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 30,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: 6,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      );
    }
  }
}

class _ConditionalCircle extends StatefulWidget {
  final int row;
  final int col;
  final String type;
  final double size;
  final bool isCompleted;
  final VoidCallback onSuccess;

  const _ConditionalCircle({
    required this.row,
    required this.col,
    required this.type,
    required this.size,
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
    Color startColor;
    Color endColor;

    if (widget.type == 'R') {
      startColor = const Color(0xFFEF5350);
      endColor = const Color(0xFFC62828);
    } else if (widget.type == 'B') {
      startColor = const Color(0xFF42A5F5);
      endColor = const Color(0xFF1565C0);
    } else {
      // 'Y'
      startColor = const Color(0xFFFFF176);
      endColor = const Color(0xFFFBC02D);
    }

    return DragTarget<String>(
      key: ValueKey('target_circle_${widget.row}_${widget.col}'),
      onWillAccept: (data) => !widget.isCompleted,
      onAccept: (data) {
        bool correct = false;
        if (widget.type == 'R' && data == 'horizontal') {
          correct = true;
        } else if (widget.type == 'B' && data == 'vertical') {
          correct = true;
        } else if (widget.type == 'Y' && data == 'plus') {
          correct = true;
        }

        if (correct) {
          widget.onSuccess();
        } else {
          SoundService.playError();
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
            width: widget.size,
            height: widget.size,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [startColor, endColor],
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
                  top: widget.size * 0.1,
                  left: widget.size * 0.13,
                  child: Container(
                    width: widget.size * 0.23,
                    height: widget.size * 0.13,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.all(Radius.elliptical(widget.size * 0.115, widget.size * 0.065)),
                    ),
                  ),
                ),
                // Completed thick white line in center
                if (widget.isCompleted)
                  Center(
                    child: _buildCompletedSymbol(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedSymbol() {
    final double lineLength = widget.size * 0.6;
    const double strokeWidth = 8.0;

    if (widget.type == 'R') {
      return Container(
        width: lineLength,
        height: strokeWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(strokeWidth / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
            )
          ],
        ),
      );
    } else if (widget.type == 'B') {
      return Container(
        width: strokeWidth,
        height: lineLength,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(strokeWidth / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
            )
          ],
        ),
      );
    } else {
      // 'Y'
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: lineLength,
            height: strokeWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(strokeWidth / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                )
              ],
            ),
          ),
          Container(
            width: strokeWidth,
            height: lineLength,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(strokeWidth / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                )
              ],
            ),
          ),
        ],
      );
    }
  }
}
