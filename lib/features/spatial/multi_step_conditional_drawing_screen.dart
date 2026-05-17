import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'dart:math' as math;
class MultiStepConditionalDrawingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const MultiStepConditionalDrawingScreen({super.key, this.levelId = 7});

  @override
  ConsumerState<MultiStepConditionalDrawingScreen> createState() => _MultiStepConditionalDrawingScreenState();
}

class _MultiStepConditionalDrawingScreenState extends ConsumerState<MultiStepConditionalDrawingScreen> {
  final List<List<String>> grid = [
    ['R', 'B', 'Y'],
    ['R', 'B', 'Y'],
    ['Y', 'R', 'B'],
    ['B', 'Y', 'R'],
    ['Y', 'R', 'B'],
  ];

  Map<String, Map<String, bool>> completionState = {};

  @override
  void initState() {
    super.initState();
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        completionState['$r-$c'] = {'h': false, 'v': false};
      }
    }
  }

  bool _isItemComplete(int r, int c) {
    String type = grid[r][c];
    var state = completionState['$r-$c']!;
    if (type == 'R') return state['h']!;
    if (type == 'B') return state['v']!;
    if (type == 'Y') return state['h']! && state['v']!;
    return false;
  }

  void _onStepSuccess(int r, int c, String step) {
    setState(() {
      completionState['$r-$c']![step] = true;
    });
    
    if (_isItemComplete(r, c)) {
      HapticService.success();
    } else {
      HapticService.light();
    }
    
    _checkWin();
  }

  void _checkWin() {
    bool allDone = true;
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        if (!_isItemComplete(r, c)) {
          allDone = false;
          break;
        }
      }
    }

    if (allDone) {
      ref.read(progressProvider.notifier).completeLevel(widget.levelId);
      CelebrationUtils.showCelebrationAndLevelUp(
        context: context,
        nextLevelId: 8,
        title: 'HEBAT!',
        message: 'Level 7 Selesai! Kamu menguasai kondisi multi-langkah!',
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
            centerTitle: true,
            title: const Text('Algoritma: Kondisional Lanjut', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 16)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Compact Legend Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem(color: Colors.red, icon: Icons.maximize_rounded, rotate: false, label: 'Datar'),
                    _LegendItem(color: Colors.blue, icon: Icons.maximize_rounded, rotate: true, label: 'Tegak'),
                    _LegendItem(color: Colors.yellow, icon: Icons.add_rounded, rotate: false, label: 'Tambah'),
                  ],
                ),
              ),

              const Text(
                'Perhatikan warnanya dan buat garis yang tepat!', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
              ),

              // Responsive Game Grid Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate available space and circle diameter
                    double maxWidth = constraints.maxWidth;
                    double maxHeight = constraints.maxHeight;
                    
                    // Diameter logic: 5 rows, 3 columns.
                    // We need to fit 5 rows vertically. 
                    // Each row has padding (2) + circle (diameter) + margin (4*2 = 8).
                    // Total per row = diameter + 10.
                    double diameter = math.min(
                      (maxWidth - 40) / 3, 
                      (maxHeight - 60) / 5
                    ).clamp(10.0, 100.0); // Remove 40.0 min, use 10.0

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(grid.length, (r) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(grid[r].length, (c) {
                              return _MultiStepCircle(
                                size: diameter,
                                type: grid[r][c],
                                state: completionState['$r-$c']!,
                                onStepSuccess: (step) => _onStepSuccess(r, c, step),
                              );
                            }),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
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
            Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('=', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Transform.rotate(
              angle: rotate ? math.pi / 2 : 0,
              child: Icon(icon, size: 20, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black38)),
      ],
    );
  }
}

class _MultiStepCircle extends StatefulWidget {
  final double size;
  final String type;
  final Map<String, bool> state;
  final Function(String) onStepSuccess;

  const _MultiStepCircle({required this.size, required this.type, required this.state, required this.onStepSuccess});

  @override
  State<_MultiStepCircle> createState() => _MultiStepCircleState();
}

class _MultiStepCircleState extends State<_MultiStepCircle> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _sparkleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _handleSwipe(Offset velocity) {
    bool isVertical = velocity.dy.abs() > velocity.dx.abs();
    bool isHorizontal = velocity.dx.abs() > velocity.dy.abs();

    if (widget.type == 'R') {
      if (widget.state['h']!) return;
      if (isHorizontal) {
        widget.onStepSuccess('h');
      } else {
        _onFail();
      }
    } else if (widget.type == 'B') {
      if (widget.state['v']!) return;
      if (isVertical) {
        widget.onStepSuccess('v');
      } else {
        _onFail();
      }
    } else if (widget.type == 'Y') {
      bool alreadyDone = widget.state['h']! && widget.state['v']!;
      if (alreadyDone) return;

      if (isVertical && !widget.state['v']!) {
        widget.onStepSuccess('v');
        if (widget.state['h']!) _onFullSuccess();
      } else if (isHorizontal && !widget.state['h']!) {
        widget.onStepSuccess('h');
        if (widget.state['v']!) _onFullSuccess();
      } else {
        _onFail();
      }
    }
  }

  void _onFail() {
    HapticService.failure();
    _shakeController.forward(from: 0);
  }

  void _onFullSuccess() {
    _sparkleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    Color circleColor = widget.type == 'R' ? Colors.red : (widget.type == 'B' ? Colors.blue : Colors.yellow);

    return GestureDetector(
      onPanEnd: (details) => _handleSwipe(details.velocity.pixelsPerSecond),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final double offset = math.sin(_shakeController.value * math.pi * 4) * 6 * (1 - _shakeController.value);
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.state['h']!)
                    Container(width: widget.size * 0.7, height: 4, color: Colors.black87),
                  if (widget.state['v']!)
                    Container(width: 4, height: widget.size * 0.7, color: Colors.black87),
                ],
              ),
            ),
          ),
          
          if (_sparkleController.isAnimating)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 1 - _sparkleController.value,
                    child: Transform.scale(
                      scale: 1 + (_sparkleController.value * 1.5),
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: widget.size * 0.8),
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

