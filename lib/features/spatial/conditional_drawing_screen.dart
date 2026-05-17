import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
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
    // Initialize completion status
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        completionStatus['$r-$c'] = false;
      }
    }
  }

  void _onSuccess(int r, int c) {
    setState(() {
      completionStatus['$r-$c'] = true;
    });
    HapticService.success();
    _checkWin();
  }

  void _checkWin() {
    if (completionStatus.values.every((v) => v == true)) {
      ref.read(progressProvider.notifier).completeLevel(widget.levelId);
      CelebrationUtils.showCelebrationAndLevelUp(
        context: context,
        nextLevelId: 7,
        title: 'HEBAT!',
        message: 'Level 6 Selesai! Kamu memahami algoritma kondisional!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Algoritma: Kondisional', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Legend Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text('KUNCI PETUNJUK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _LegendItem(color: Colors.yellow, icon: Icons.maximize_rounded, rotate: true, label: 'Geser Tegak'),
                          _LegendItem(color: Colors.pinkAccent, icon: Icons.maximize_rounded, rotate: false, label: 'Geser Datar'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Buat garis tepat pada warna sesuai contoh!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                ),
                const SizedBox(height: 10),

                // Game Grid
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(grid.length, (r) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(grid[r].length, (c) {
                          return _ConditionalCircle(
                            type: grid[r][c],
                            isCompleted: completionStatus['$r-$c'] ?? false,
                            onSuccess: () => _onSuccess(r, c),
                          );
                        }),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool rotate;
  final String label;

  const _LegendItem({required this.color, required this.icon, required this.rotate, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black12))),
            const SizedBox(width: 8),
            const Text('=', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Transform.rotate(
              angle: rotate ? math.pi / 2 : 0,
              child: Icon(icon, size: 30, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38)),
      ],
    );
  }
}

class _ConditionalCircle extends StatefulWidget {
  final String type;
  final bool isCompleted;
  final VoidCallback onSuccess;

  const _ConditionalCircle({required this.type, required this.isCompleted, required this.onSuccess});

  @override
  State<_ConditionalCircle> createState() => _ConditionalCircleState();
}

class _ConditionalCircleState extends State<_ConditionalCircle> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _starController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _handleSwipe(Offset velocity) {
    if (widget.isCompleted) return;

    bool isVertical = velocity.dy.abs() > velocity.dx.abs();
    bool isHorizontal = velocity.dx.abs() > velocity.dy.abs();

    bool correct = false;
    if (widget.type == 'Y' && isVertical) {
      correct = true;
    } else if (widget.type == 'P' && isHorizontal) {
      correct = true;
    }

    if (correct) {
      _starController.forward(from: 0);
      widget.onSuccess();
    } else {
      HapticService.failure();
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) => _handleSwipe(details.velocity.pixelsPerSecond),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shake Animation for wrong swipe
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final double offset = math.sin(_shakeController.value * math.pi * 4) * 8 * (1 - _shakeController.value);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Container(
              width: 65,
              height: 65,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.type == 'Y' ? Colors.yellow : Colors.pinkAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: widget.isCompleted
                  ? Center(
                      child: Container(
                        width: widget.type == 'Y' ? 3 : 40,
                        height: widget.type == 'Y' ? 40 : 3,
                        color: Colors.black87,
                      ),
                    )
                  : null,
            ),
          ),
          
          // Star Burst Animation for success
          if (_starController.isAnimating || _starController.isCompleted)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _starController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 1 - _starController.value,
                    child: Transform.scale(
                      scale: 0.5 + (_starController.value * 1.5),
                      child: const Icon(Icons.star_rounded, color: Colors.amber, size: 80),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

