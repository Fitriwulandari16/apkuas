import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:apkuas/core/providers/profile_provider.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
import 'package:google_fonts/google_fonts.dart';

class AdventureMapScreen extends ConsumerStatefulWidget {
  const AdventureMapScreen({super.key});

  @override
  ConsumerState<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends ConsumerState<AdventureMapScreen> {
  int _userServiceProgress = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prog = await UserService.getProgress();
      if (mounted) {
        setState(() {
          _userServiceProgress = prog;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  MapEntry<int, int> _getRowAndCol(int level) {
    int index = level - 1;
    int r = index ~/ 5;
    int cTemp = index % 5;
    int c = (r % 2 == 0) ? cTemp : (4 - cTemp);
    return MapEntry(r, c);
  }

  Offset _getNodeCenter(int level, double width, double stepY, double padding) {
    final entry = _getRowAndCol(level);
    final r = entry.key;
    final c = entry.value;
    final double stepX = (width - 2 * padding) / 4;
    final double x = padding + c * stepX;
    final double y = padding + r * stepY + 80;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final riverpodProgress = ref.watch(progressProvider);
    final int currentProgress = math.max(riverpodProgress, _userServiceProgress);

    return ResponsiveWrapper(
      backgroundColor: const Color(0xFFE0F7FA),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE0F7FA), // Sky blue
                Color(0xFFFFF9C4), // Sun glow
                Color(0xFFE8F5E9), // Gentle green
              ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      const double padding = 44.0;
                      final double stepX = (width - 2 * padding) / 4;
                      const double stepY = 200.0;
                      final int numRows = (LevelResolver.totalLevels / 5).ceil();
                      final double totalHeight = padding * 2 + numRows * stepY + 200.0;

                      // Define static ornaments list with specific coordinates
                      final List<Map<String, dynamic>> ornaments = [
                        {
                          'r': 0.5,
                          'c': 1.0,
                          'label': '🤖',
                          'bgColor': Colors.blue.shade100,
                          'angle': -0.12,
                        },
                        {
                          'r': 1.5,
                          'c': 3.0,
                          'label': '⚙️',
                          'bgColor': Colors.orange.shade100,
                          'angle': 0.15,
                        },
                        {
                          'r': 2.5,
                          'c': 1.0,
                          'label': '🔍',
                          'bgColor': Colors.teal.shade100,
                          'angle': -0.18,
                        },
                        {
                          'r': 3.5,
                          'c': 3.0,
                          'label': '🚂',
                          'bgColor': Colors.red.shade100,
                          'angle': 0.08,
                        },
                        {
                          'r': 4.5,
                          'c': 1.0,
                          'label': '🧱',
                          'bgColor': Colors.purple.shade100,
                          'angle': -0.1,
                        },
                        {
                          'r': 5.5,
                          'c': 3.0,
                          'label': '🎮',
                          'bgColor': Colors.indigo.shade100,
                          'angle': 0.14,
                        },
                        {
                          'r': 6.5,
                          'c': 1.0,
                          'label': '🎨',
                          'bgColor': Colors.pink.shade100,
                          'angle': -0.15,
                        },
                        {
                          'r': 7.5,
                          'c': 3.0,
                          'label': '🚀',
                          'bgColor': Colors.amber.shade100,
                          'angle': 0.2,
                        },
                        {
                          'r': 8.5,
                          'c': 1.0,
                          'label': '🧸',
                          'bgColor': Colors.brown.shade100,
                          'angle': -0.08,
                        },
                      ];

                      // Filter ornaments dynamically so they fit within our scrolling area
                      final List<Map<String, dynamic>> visibleOrnaments = ornaments.where((orn) {
                        final double r = orn['r'];
                        return r < numRows;
                      }).toList();

                      return Column(
                        children: [
                          // Custom Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: CilikTheme.tealTua),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Text(
                                  'Peta Petualangan',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: CilikTheme.tealTua,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.orange, size: 22),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${profile.totalStars}',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Scrolling Map
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(
                                width: width,
                                height: totalHeight,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // 1. Draw Snake Path
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: SnakePathPainter(
                                          width: width,
                                          stepY: stepY,
                                          padding: padding,
                                          maxReachedLevel: currentProgress,
                                        ),
                                      ),
                                    ),

                                    // 2. Render Ornaments
                                    ...visibleOrnaments.map((orn) {
                                      final double r = orn['r'];
                                      final double c = orn['c'];
                                      final double x = padding + c * stepX;
                                      final double y = padding + r * stepY + 80;
                                      return Positioned(
                                        left: x - 27,
                                        top: y - 27,
                                        child: OrnamentWidget(
                                          label: orn['label'],
                                          bgColor: orn['bgColor'],
                                          angle: orn['angle'],
                                        ),
                                      );
                                    }),

                                    // 3. Start Label near Level 1
                                    Positioned(
                                      left: padding - 20,
                                      top: padding + 25,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 4),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Mulai',
                                              style: GoogleFonts.fredoka(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 12),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // 4. Middle Label "Semangat!"
                                    Positioned(
                                      left: padding + 2 * stepX - 45,
                                      top: padding + ((numRows - 1) / 2) * stepY + 55,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(15),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 4),
                                          ],
                                        ),
                                        child: Text(
                                          'Semangat! 🌟',
                                          style: GoogleFonts.fredoka(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 5. Final Label "Selesai" near Level totalLevels
                                    Positioned(
                                      left: (_getNodeCenter(LevelResolver.totalLevels, width, stepY, padding).dx - 60).clamp(16.0, width - 150.0),
                                      top: _getNodeCenter(LevelResolver.totalLevels, width, stepY, padding).dy + 50,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade500,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Selesai',
                                                  style: GoogleFonts.fredoka(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Berhasil! 🎉',
                                                  style: GoogleFonts.fredoka(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // 6. Level Nodes (Level 1 to totalLevels)
                                    ...List.generate(LevelResolver.totalLevels, (index) {
                                      final int level = index + 1;
                                      final bool isUnlocked = level <= currentProgress;
                                      final bool isCurrent = level == currentProgress;
                                      final offset = _getNodeCenter(level, width, stepY, padding);

                                      return Position(
                                        left: offset.dx - 35,
                                        top: offset.dy - 35,
                                        child: FlowerLevelNode(
                                          level: level,
                                          isUnlocked: isUnlocked,
                                          isCurrent: isCurrent,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LevelResolver.buildLevel(level),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Bottom Play Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, -4),
                                )
                              ],
                            ),
                            child: SafeArea(
                              top: false,
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF81C784),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    onTap: () {
                                      int target = currentProgress;
                                      if (target > LevelResolver.totalLevels) target = LevelResolver.totalLevels;
                                      if (target < 1) target = 1;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LevelResolver.buildLevel(target),
                                        ),
                                      );
                                    },
                                    child: Center(
                                      child: Text(
                                        'Main Level ${math.min(currentProgress, LevelResolver.totalLevels)}',
                                        style: GoogleFonts.fredoka(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

// Position helper alias for Positioned
class Position extends Positioned {
  const Position({
    super.key,
    super.left,
    super.top,
    super.right,
    super.bottom,
    super.width,
    super.height,
    required super.child,
  });
}

// ─── Custom Painter for Curved Path ──────────────────────────────────────────

class SnakePathPainter extends CustomPainter {
  final double width;
  final double stepY;
  final double padding;
  final int maxReachedLevel;

  SnakePathPainter({
    required this.width,
    required this.stepY,
    required this.padding,
    required this.maxReachedLevel,
  });

  MapEntry<int, int> _getRowAndCol(int level) {
    int index = level - 1;
    int r = index ~/ 5;
    int cTemp = index % 5;
    int c = (r % 2 == 0) ? cTemp : (4 - cTemp);
    return MapEntry(r, c);
  }

  Offset _getNodeCenter(int level) {
    final entry = _getRowAndCol(level);
    final r = entry.key;
    final c = entry.value;
    final double stepX = (width - 2 * padding) / 4;
    final double x = padding + c * stepX;
    final double y = padding + r * stepY + 80;
    return Offset(x, y);
  }

  Path _buildSnakeCurvePath(int limit) {
    final path = Path();
    if (limit < 1) return path;

    bool first = true;
    for (int i = 1; i <= limit; i++) {
      final offset = _getNodeCenter(i);
      if (first) {
        path.moveTo(offset.dx, offset.dy);
        first = false;
      } else {
        final prevOffset = _getNodeCenter(i - 1);
        final prevEntry = _getRowAndCol(i - 1);
        final currEntry = _getRowAndCol(i);
        
        if (prevEntry.key == currEntry.key) {
          path.lineTo(offset.dx, offset.dy);
        } else {
          final double stepX = (width - 2 * padding) / 4;
          if (prevEntry.value == 4 && currEntry.value == 4) {
            final cp1 = Offset(prevOffset.dx + stepX * 1.1, prevOffset.dy);
            final cp2 = Offset(offset.dx + stepX * 1.1, offset.dy);
            path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, offset.dx, offset.dy);
          } else {
            final cp1 = Offset(prevOffset.dx - stepX * 1.1, prevOffset.dy);
            final cp2 = Offset(offset.dx - stepX * 1.1, offset.dy);
            path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, offset.dx, offset.dy);
          }
        }
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0) return;

    final fullPath = _buildSnakeCurvePath(LevelResolver.totalLevels);

    final borderPaint = Paint()
      ..color = const Color(0xFF8D6E63).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, borderPaint);

    final bgTrackPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, bgTrackPaint);

    final fgTrackPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    int limit = maxReachedLevel;
    if (limit > LevelResolver.totalLevels) limit = LevelResolver.totalLevels;
    if (limit > 1) {
      final unlockedPath = _buildSnakeCurvePath(limit);
      canvas.drawPath(unlockedPath, fgTrackPaint);
    }

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, fullPath, dashPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 6.0;
    const double dashSpace = 6.0;
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        double nextDistance = distance + dashWidth;
        if (nextDistance > measurePath.length) {
          nextDistance = measurePath.length;
        }
        canvas.drawPath(
          measurePath.extractPath(distance, nextDistance),
          paint,
        );
        distance = nextDistance + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant SnakePathPainter oldDelegate) {
    return oldDelegate.width != width ||
        oldDelegate.stepY != stepY ||
        oldDelegate.padding != padding ||
        oldDelegate.maxReachedLevel != maxReachedLevel;
  }
}

// ─── Flower Level Node ───────────────────────────────────────────────────────────

class FlowerLevelNode extends StatefulWidget {
  final int level;
  final bool isUnlocked;
  final bool isCurrent;
  final VoidCallback? onTap;

  const FlowerLevelNode({
    super.key,
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    this.onTap,
  });

  @override
  State<FlowerLevelNode> createState() => _FlowerLevelNodeState();
}

class _FlowerLevelNodeState extends State<FlowerLevelNode> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant FlowerLevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(reverse: true);
    } else if (!widget.isCurrent && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> unlockedPetalColors = [
      const Color(0xFFFFADAD), // Pastel Red
      const Color(0xFFFFD6A5), // Pastel Orange
      const Color(0xFFFDFFB6), // Pastel Yellow
      const Color(0xFFCAFFBF), // Pastel Green
      const Color(0xFF9BF6FF), // Pastel Blue
    ];
    final List<Color> unlockedTextColors = [
      const Color(0xFFC62828),
      const Color(0xFFEF6C00),
      const Color(0xFFE65100),
      const Color(0xFF2E7D32),
      const Color(0xFF1565C0),
    ];

    final int colorIdx = widget.level % 5;
    final Color petalColor = widget.isUnlocked
        ? unlockedPetalColors[colorIdx]
        : Colors.grey.shade400.withOpacity(0.5);

    final Color centerColor = widget.isUnlocked
        ? Colors.white
        : Colors.grey.shade300.withOpacity(0.5);

    final Color textColor = widget.isUnlocked
        ? unlockedTextColors[colorIdx]
        : Colors.grey.shade600;

    const double size = 70.0;
    const double centerCircleSize = 46.0;
    const double petalSize = 26.0;
    const double radius = 17.0;

    Widget flower = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 5; i++)
            Builder(
              builder: (context) {
                final double angle = i * 2 * math.pi / 5 - math.pi / 2;
                final double dx = radius * math.cos(angle);
                final double dy = radius * math.sin(angle);
                return Positioned(
                  left: (size - petalSize) / 2 + dx,
                  top: (size - petalSize) / 2 + dy,
                  child: Container(
                    width: petalSize,
                    height: petalSize,
                    decoration: BoxDecoration(
                      color: petalColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          Container(
            width: centerCircleSize,
            height: centerCircleSize,
            decoration: BoxDecoration(
              color: centerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isUnlocked 
                    ? (widget.isCurrent ? const Color(0xFFFFD54F) : Colors.white) 
                    : Colors.grey.shade400.withOpacity(0.6),
                width: widget.isCurrent ? 3.5 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Text(
                '${widget.level}',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ),
          if (!widget.isUnlocked)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 11,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.isCurrent && _controller != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller!,
          builder: (context, child) {
            final double scale = 1.0 + (_controller!.value * 0.08);
            return Transform.scale(
              scale: scale,
              child: flower,
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: widget.isUnlocked ? widget.onTap : null,
      child: flower,
    );
  }
}

// ─── Ornament Widget ───────────────────────────────────────────────────────────

class OrnamentWidget extends StatelessWidget {
  final String label;
  final Color bgColor;
  final double angle;

  const OrnamentWidget({
    super.key,
    required this.label,
    required this.bgColor,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }
}
