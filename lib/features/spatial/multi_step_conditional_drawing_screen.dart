import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
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

  // State: 'r-c' -> { 'h': bool, 'v': bool }
  Map<String, Map<String, bool>> completionState = {};
  bool _showCelebration = false;

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
      setState(() => _showCelebration = true);
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LevelTransitionScreen(nextLevelId: 8)),
          );
        }
      });
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
            title: const Text('Algoritma: Kondisional Lanjut', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Legend Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text('KUNCI PETUNJUK', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.orange, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _LegendItem(color: Colors.red, icon: Icons.maximize_rounded, rotate: false, label: 'Datar'),
                          _LegendItem(color: Colors.blue, icon: Icons.maximize_rounded, rotate: true, label: 'Tegak'),
                          _LegendItem(color: Colors.yellow, icon: Icons.add_rounded, rotate: false, label: 'Tambah'),
                        ],
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text('Perhatikan warnanya dan buat garis yang tepat!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                ),
                const SizedBox(height: 20),

                // Game Grid
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(grid.length, (r) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(grid[r].length, (c) {
                          return _MultiStepCircle(
                            type: grid[r][c],
                            state: completionState['$r-$c']!,
                            onStepSuccess: (step) => _onStepSuccess(r, c, step),
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
        if (_showCelebration) const IgnorePointer(child: _ConfettiOverlay()),
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
            Container(width: 32, height: 32, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black12))),
            const SizedBox(width: 6),
            const Text('=', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Transform.rotate(
              angle: rotate ? math.pi / 2 : 0,
              child: Icon(icon, size: 24, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black38)),
      ],
    );
  }
}

class _MultiStepCircle extends StatefulWidget {
  final String type;
  final Map<String, bool> state;
  final Function(String) onStepSuccess;

  const _MultiStepCircle({required this.type, required this.state, required this.onStepSuccess});

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
    bool isFullComplete = widget.type == 'Y' ? (widget.state['h']! && widget.state['v']!) : (widget.type == 'R' ? widget.state['h']! : widget.state['v']!);

    return GestureDetector(
      onPanEnd: (details) => _handleSwipe(details.velocity.pixelsPerSecond),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final double offset = math.sin(_shakeController.value * math.pi * 4) * 8 * (1 - _shakeController.value);
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: Container(
              width: 80, height: 80,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.state['h']!)
                    Container(width: 50, height: 4, color: Colors.black87),
                  if (widget.state['v']!)
                    Container(width: 4, height: 50, color: Colors.black87),
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
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 60),
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

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();
  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(progress: _controller.value),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.pink, Colors.orange];
    for (int i = 0; i < 60; i++) {
      final paint = Paint()..color = colors[i % colors.length].withOpacity(1.0 - progress);
      canvas.drawRect(Rect.fromLTWH((i * 137.5 % 1.0) * size.width, progress * size.height * (1.0 + (i % 8) / 10.0) - 100, 12, 12), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
