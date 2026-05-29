import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ColorConnectionMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ColorConnectionMatchingScreen({super.key, this.levelId = 27});

  @override
  ConsumerState<ColorConnectionMatchingScreen> createState() => _ColorConnectionMatchingScreenState();
}

class ColorCircle {
  final int id;
  final Color color;
  final Offset position; // Normalized position (0.0 to 1.0)
  bool isMatched;

  ColorCircle({
    required this.id,
    required this.color,
    required this.position,
    this.isMatched = false,
  });
}

class ColorConnection {
  final int startCircleId;
  final int endCircleId;
  final Color color;

  ColorConnection({
    required this.startCircleId,
    required this.endCircleId,
    required this.color,
  });
}

class _ColorConnectionMatchingScreenState extends ConsumerState<ColorConnectionMatchingScreen> {
  late List<ColorCircle> _circles;
  late List<ColorConnection> _connections;

  // Active drawing state
  int? _activeStartCircleId;
  Offset? _currentDragPosition;

  // Track circle scaling feedback on success
  final Set<int> _animatingCircleIds = {};

  // Standard matching colors matching textbook palette
  static const Color colBlue = Color(0xFF3EA5E1);   // Biru
  static const Color colOrange = Color(0xFFFFAA00); // Oranye
  static const Color colPurple = Color(0xFFAB47BC); // Ungu
  static const Color colGreen = Color(0xFF4CAF50);  // Hijau
  static const Color colYellow = Color(0xFFFFD54F); // Kuning
  static const Color colBrown = Color(0xFF8D6E63);  // Cokelat

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    _circles = [
      // Pair 1: Biru (Pre-connected as example)
      ColorCircle(id: 0, color: colBlue, position: const Offset(0.50, 0.15)),
      ColorCircle(id: 1, color: colBlue, position: const Offset(0.47, 0.63)),

      // Pair 2: Oranye
      ColorCircle(id: 2, color: colOrange, position: const Offset(0.30, 0.38)),
      ColorCircle(id: 3, color: colOrange, position: const Offset(0.28, 0.65)),

      // Pair 3: Ungu
      ColorCircle(id: 4, color: colPurple, position: const Offset(0.15, 0.46)),
      ColorCircle(id: 5, color: colPurple, position: const Offset(0.26, 0.77)),

      // Pair 4: Hijau
      ColorCircle(id: 6, color: colGreen, position: const Offset(0.56, 0.53)),
      ColorCircle(id: 7, color: colGreen, position: const Offset(0.83, 0.64)),

      // Pair 5: Kuning
      ColorCircle(id: 8, color: colYellow, position: const Offset(0.12, 0.83)),
      ColorCircle(id: 9, color: colYellow, position: const Offset(0.53, 0.82)),

      // Pair 6: Cokelat
      ColorCircle(id: 10, color: colBrown, position: const Offset(0.68, 0.28)),
      ColorCircle(id: 11, color: colBrown, position: const Offset(0.78, 0.82)),
    ];

    // Pre-connect the blue pair (id: 0 and id: 1)
    _circles[0].isMatched = true;
    _circles[1].isMatched = true;

    _connections = [
      ColorConnection(startCircleId: 0, endCircleId: 1, color: colBlue),
    ];
  }

  Offset _getCirclePixelPos(ColorCircle circle, Size size) {
    // Keep internal padding to avoid circles sticking to layout borders
    double padX = 24.0;
    double padY = 24.0;
    double playableW = size.width - 2 * padX;
    double playableH = size.height - 2 * padY;

    return Offset(
      padX + circle.position.dx * playableW,
      padY + circle.position.dy * playableH,
    );
  }

  int? _findCircleAtPos(Offset localPos, Size size) {
    double hitRadius = 30.0;
    for (var circle in _circles) {
      Offset pos = _getCirclePixelPos(circle, size);
      if ((localPos - pos).distance < hitRadius) {
        return circle.id;
      }
    }
    return null;
  }

  void _handlePanStart(Offset localPos, Size size) {
    final tappedCircleId = _findCircleAtPos(localPos, size);
    if (tappedCircleId != null) {
      final circle = _circles.firstWhere((c) => c.id == tappedCircleId);
      if (!circle.isMatched) {
        HapticService.light();
        setState(() {
          _activeStartCircleId = tappedCircleId;
          _currentDragPosition = localPos;
        });
      }
    }
  }

  void _handlePanUpdate(Offset localPos) {
    if (_activeStartCircleId == null) return;
    setState(() {
      _currentDragPosition = localPos;
    });
  }

  void _handlePanEnd(Size size) {
    if (_activeStartCircleId == null || _currentDragPosition == null) return;

    final targetCircleId = _findCircleAtPos(_currentDragPosition!, size);
    final startCircle = _circles.firstWhere((c) => c.id == _activeStartCircleId);

    if (targetCircleId != null && targetCircleId != _activeStartCircleId) {
      final targetCircle = _circles.firstWhere((c) => c.id == targetCircleId);

      if (!targetCircle.isMatched && startCircle.color == targetCircle.color) {
        // Success match!
        SoundService.playSuccess();
        HapticService.success();

        setState(() {
          startCircle.isMatched = true;
          targetCircle.isMatched = true;
          _connections.add(ColorConnection(
            startCircleId: startCircle.id,
            endCircleId: targetCircle.id,
            color: startCircle.color,
          ));

          // Animate circles scaling up
          _animatingCircleIds.add(startCircle.id);
          _animatingCircleIds.add(targetCircle.id);
        });

        // Decay scale animation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _animatingCircleIds.remove(startCircle.id);
              _animatingCircleIds.remove(targetCircle.id);
            });
          }
        });

        // Check if all 6 pairs (12 circles total) are completed
        if (_connections.length == 6) {
          _onLevelComplete();
        }
      } else {
        HapticService.failure();
      }
    } else {
      HapticService.failure();
    }

    setState(() {
      _activeStartCircleId = null;
      _currentDragPosition = null;
    });
  }

  void _onLevelComplete() async {
    // Save status to local Hive progress provider (simulating Firestore user_history updates locally)
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    try {
      await UserService.updateProgress(27);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 27: $e');
    }

    if (!mounted) return;
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 28, // Next level placeholder
      title: 'Hebat Sekali!',
      message: 'Kamu berhasil menghubungkan semua lingkaran warna!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: const Color(0xFFDCDFE6),
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);

                    return GestureDetector(
                      onPanStart: (details) => _handlePanStart(details.localPosition, size),
                      onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
                      onPanEnd: (details) => _handlePanEnd(size),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Connected lines + Drag line preview
                          Positioned.fill(
                            child: CustomPaint(
                              painter: ConnectionLinesPainter(
                                connections: _connections,
                                circles: _circles,
                                activeStartCircleId: _activeStartCircleId,
                                dragPosition: _currentDragPosition,
                                size: size,
                              ),
                            ),
                          ),

                          // Interactive Circle nodes
                          ..._circles.map((circle) {
                            final pos = _getCirclePixelPos(circle, size);
                            final isAnimating = _animatingCircleIds.contains(circle.id);
                            final double circleRadius = 22.0;

                            return Positioned(
                              left: pos.dx - circleRadius,
                              top: pos.dy - circleRadius,
                              child: AnimatedScale(
                                scale: isAnimating ? 1.35 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.elasticOut,
                                child: Container(
                                  width: circleRadius * 2,
                                  height: circleRadius * 2,
                                  decoration: BoxDecoration(
                                    color: circle.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: circle.color.withOpacity(0.4),
                                        blurRadius: circle.isMatched ? 4 : 8,
                                        spreadRadius: circle.isMatched ? 0 : 2,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: circle.isMatched
                                      ? const Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
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
              'Level 27',
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
          const Icon(Icons.linear_scale_rounded, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Hubungkan warna yang sama dengan garis!',
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
}

class ConnectionLinesPainter extends CustomPainter {
  final List<ColorConnection> connections;
  final List<ColorCircle> circles;
  final int? activeStartCircleId;
  final Offset? dragPosition;
  final Size size;

  ConnectionLinesPainter({
    required this.connections,
    required this.circles,
    required this.activeStartCircleId,
    required this.dragPosition,
    required this.size,
  });

  Offset _getCirclePixelPos(ColorCircle circle, Size size) {
    double padX = 24.0;
    double padY = 24.0;
    double playableW = size.width - 2 * padX;
    double playableH = size.height - 2 * padY;

    return Offset(
      padX + circle.position.dx * playableW,
      padY + circle.position.dy * playableH,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw existing connections
    for (var conn in connections) {
      final startCircle = circles.firstWhere((c) => c.id == conn.startCircleId);
      final endCircle = circles.firstWhere((c) => c.id == conn.endCircleId);

      final startPos = _getCirclePixelPos(startCircle, size);
      final endPos = _getCirclePixelPos(endCircle, size);

      final paint = Paint()
        ..color = conn.color.withOpacity(0.85)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(startPos, endPos, paint);
    }

    // 2. Draw active dragging line preview
    if (activeStartCircleId != null && dragPosition != null) {
      final startCircle = circles.firstWhere((c) => c.id == activeStartCircleId);
      final startPos = _getCirclePixelPos(startCircle, size);

      final dragPaint = Paint()
        ..color = startCircle.color.withOpacity(0.55)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(startPos, dragPosition!, dragPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionLinesPainter oldDelegate) {
    return oldDelegate.connections.length != connections.length ||
        oldDelegate.activeStartCircleId != activeStartCircleId ||
        oldDelegate.dragPosition != dragPosition;
  }
}
