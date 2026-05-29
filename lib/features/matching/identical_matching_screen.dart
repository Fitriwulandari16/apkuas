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

enum MatchShape {
  square,
  circle,
  triangle,
  invertedTriangle,
  star
}

class MatchItem {
  final int index;
  final MatchShape shape;
  final Color color;
  final String label;

  MatchItem({
    required this.index,
    required this.shape,
    required this.color,
    required this.label,
  });
}

class MatchConnection {
  final int leftIndex;
  final int rightIndex;

  MatchConnection({
    required this.leftIndex,
    required this.rightIndex,
  });
}

class IdenticalMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const IdenticalMatchingScreen({super.key, this.levelId = 31});

  @override
  ConsumerState<IdenticalMatchingScreen> createState() => _IdenticalMatchingScreenState();
}

class _ColorPalette {
  static const Color colOrange = Color(0xFFFF8A3D);
  static const Color colYellow = Color(0xFFFFD54F);
  static const Color colGreen = Color(0xFF4CAF50);
  static const Color colBlue = Color(0xFF3EA5E1);
  static const Color colPink = Color(0xFFF48FB1);
  static const Color colPurple = Color(0xFFB39DDB);
}

class _IdenticalMatchingScreenState extends ConsumerState<IdenticalMatchingScreen> {
  final List<MatchItem> _leftItems = [
    MatchItem(index: 0, shape: MatchShape.square, color: _ColorPalette.colOrange, label: 'orange_square'),
    MatchItem(index: 1, shape: MatchShape.circle, color: _ColorPalette.colYellow, label: 'yellow_circle'),
    MatchItem(index: 2, shape: MatchShape.triangle, color: _ColorPalette.colGreen, label: 'green_triangle'),
    MatchItem(index: 3, shape: MatchShape.invertedTriangle, color: _ColorPalette.colBlue, label: 'blue_inverted_triangle'),
    MatchItem(index: 4, shape: MatchShape.star, color: _ColorPalette.colYellow, label: 'yellow_star'),
    MatchItem(index: 5, shape: MatchShape.circle, color: _ColorPalette.colPink, label: 'pink_circle'),
    MatchItem(index: 6, shape: MatchShape.square, color: _ColorPalette.colPurple, label: 'purple_square'),
  ];

  final List<MatchItem> _rightItems = [
    MatchItem(index: 0, shape: MatchShape.circle, color: _ColorPalette.colYellow, label: 'yellow_circle'),
    MatchItem(index: 1, shape: MatchShape.triangle, color: _ColorPalette.colGreen, label: 'green_triangle'),
    MatchItem(index: 2, shape: MatchShape.square, color: _ColorPalette.colPurple, label: 'purple_square'),
    MatchItem(index: 3, shape: MatchShape.star, color: _ColorPalette.colYellow, label: 'yellow_star'),
    MatchItem(index: 4, shape: MatchShape.circle, color: _ColorPalette.colPink, label: 'pink_circle'),
    MatchItem(index: 5, shape: MatchShape.square, color: _ColorPalette.colOrange, label: 'orange_square'),
    MatchItem(index: 6, shape: MatchShape.invertedTriangle, color: _ColorPalette.colBlue, label: 'blue_inverted_triangle'),
  ];

  final List<MatchConnection> _connections = [];
  int? _activeStartLeftIndex;
  Offset? _currentDragPosition;
  final Set<int> _animatingLeftIndices = {};
  final Set<int> _animatingRightIndices = {};

  int? _findLeftIndexAtPos(Offset localPos, Size size) {
    final W = size.width;
    final H = size.height;
    double hitRadius = 45.0;
    for (int i = 0; i < 7; i++) {
      Offset pos = Offset(W * 0.26, H * (i + 0.5) / 7);
      if ((localPos - pos).distance < hitRadius) {
        return i;
      }
      Offset shapeCenter = Offset(W * 0.15, H * (i + 0.5) / 7);
      if ((localPos - shapeCenter).distance < hitRadius) {
        return i;
      }
    }
    return null;
  }

  int? _findRightIndexAtPos(Offset localPos, Size size) {
    final W = size.width;
    final H = size.height;
    double hitRadius = 45.0;
    for (int j = 0; j < 7; j++) {
      Offset pos = Offset(W * 0.74, H * (j + 0.5) / 7);
      if ((localPos - pos).distance < hitRadius) {
        return j;
      }
      Offset shapeCenter = Offset(W * 0.85, H * (j + 0.5) / 7);
      if ((localPos - shapeCenter).distance < hitRadius) {
        return j;
      }
    }
    return null;
  }

  void _handlePanStart(Offset localPos, Size size) {
    final index = _findLeftIndexAtPos(localPos, size);
    if (index != null) {
      final isAlreadyMatched = _connections.any((conn) => conn.leftIndex == index);
      if (!isAlreadyMatched) {
        HapticService.light();
        setState(() {
          _activeStartLeftIndex = index;
          _currentDragPosition = localPos;
        });
      }
    }
  }

  void _handlePanUpdate(Offset localPos) {
    if (_activeStartLeftIndex == null) return;
    setState(() {
      _currentDragPosition = localPos;
    });
  }

  void _handlePanEnd(Size size) {
    if (_activeStartLeftIndex == null || _currentDragPosition == null) return;

    final targetIndex = _findRightIndexAtPos(_currentDragPosition!, size);
    if (targetIndex != null) {
      final isRightAlreadyMatched = _connections.any((conn) => conn.rightIndex == targetIndex);
      if (!isRightAlreadyMatched) {
        final leftItem = _leftItems[_activeStartLeftIndex!];
        final rightItem = _rightItems[targetIndex];

        if (leftItem.label == rightItem.label) {
          SoundService.playSuccess();
          HapticService.success();

          setState(() {
            _connections.add(MatchConnection(
              leftIndex: _activeStartLeftIndex!,
              rightIndex: targetIndex,
            ));
            _animatingLeftIndices.add(_activeStartLeftIndex!);
            _animatingRightIndices.add(targetIndex);
          });

          final currentLeft = _activeStartLeftIndex!;
          final currentRight = targetIndex;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _animatingLeftIndices.remove(currentLeft);
                _animatingRightIndices.remove(currentRight);
              });
            }
          });

          if (_connections.length == 7) {
            _onLevelComplete();
          }
        } else {
          HapticService.failure();
        }
      } else {
        HapticService.failure();
      }
    } else {
      HapticService.failure();
    }

    setState(() {
      _activeStartLeftIndex = null;
      _currentDragPosition = null;
    });
  }

  void _onLevelComplete() async {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    try {
      await UserService.updateProgress(31);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 31: $e');
    }

    if (!mounted) return;
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 32,
      title: 'Hebat Sekali!',
      message: 'Kamu pintar mencocokkan bentuk dan warna!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    final W = size.width;
                    final H = size.height;
                    const double shapeSize = 52.0;
                    const double dotSize = 16.0;

                    return GestureDetector(
                      onPanStart: (details) => _handlePanStart(details.localPosition, size),
                      onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
                      onPanEnd: (details) => _handlePanEnd(size),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Draw paths
                          Positioned.fill(
                            child: CustomPaint(
                              painter: ConnectionPainter(
                                connections: _connections,
                                activeStartLeftIndex: _activeStartLeftIndex,
                                dragPosition: _currentDragPosition,
                                size: size,
                              ),
                            ),
                          ),

                          // Left Column items & anchor dots
                          ...List.generate(7, (i) {
                            final item = _leftItems[i];
                            final isAnimating = _animatingLeftIndices.contains(i);
                            final isMatched = _connections.any((c) => c.leftIndex == i);

                            return Stack(
                              children: [
                                // Left shape
                                Positioned(
                                  left: W * 0.14 - shapeSize / 2,
                                  top: H * (i + 0.5) / 7 - shapeSize / 2,
                                  child: AnimatedScale(
                                    scale: isAnimating ? 1.3 : 1.0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.bounceOut,
                                    child: Container(
                                      width: shapeSize,
                                      height: shapeSize,
                                      alignment: Alignment.center,
                                      child: CustomPaint(
                                        size: const Size(shapeSize, shapeSize),
                                        painter: ShapePainter(
                                          shape: item.shape,
                                          color: item.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Left anchor dot
                                Positioned(
                                  left: W * 0.26 - dotSize / 2,
                                  top: H * (i + 0.5) / 7 - dotSize / 2,
                                  child: Container(
                                    width: dotSize,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      color: isMatched ? const Color(0xFF2E7D32) : const Color(0xFFB0BEC5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),

                          // Right Column items & anchor dots
                          ...List.generate(7, (j) {
                            final item = _rightItems[j];
                            final isAnimating = _animatingRightIndices.contains(j);
                            final isMatched = _connections.any((c) => c.rightIndex == j);

                            return Stack(
                              children: [
                                // Right shape
                                Positioned(
                                  left: W * 0.86 - shapeSize / 2,
                                  top: H * (j + 0.5) / 7 - shapeSize / 2,
                                  child: AnimatedScale(
                                    scale: isAnimating ? 1.3 : 1.0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.bounceOut,
                                    child: Container(
                                      width: shapeSize,
                                      height: shapeSize,
                                      alignment: Alignment.center,
                                      child: CustomPaint(
                                        size: const Size(shapeSize, shapeSize),
                                        painter: ShapePainter(
                                          shape: item.shape,
                                          color: item.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Right anchor dot
                                Positioned(
                                  left: W * 0.74 - dotSize / 2,
                                  top: H * (j + 0.5) / 7 - dotSize / 2,
                                  child: Container(
                                    width: dotSize,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      color: isMatched ? const Color(0xFF2E7D32) : const Color(0xFFB0BEC5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 31',
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC8E6C9),
          width: 2.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFF388E3C), size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Hubungkan bentuk dan warna yang sama!',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class ShapePainter extends CustomPainter {
  final MatchShape shape;
  final Color color;

  ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    switch (shape) {
      case MatchShape.square:
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, w - 4, h - 4),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, fillPaint);
        canvas.drawRRect(rect, strokePaint);
        break;
      case MatchShape.circle:
        final rect = Rect.fromLTWH(2, 2, w - 4, h - 4);
        canvas.drawOval(rect, fillPaint);
        canvas.drawOval(rect, strokePaint);
        break;
      case MatchShape.triangle:
        final path = Path()
          ..moveTo(w / 2, 2)
          ..lineTo(w - 2, h - 2)
          ..lineTo(2, h - 2)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
      case MatchShape.invertedTriangle:
        final path = Path()
          ..moveTo(2, 2)
          ..lineTo(w - 2, 2)
          ..lineTo(w / 2, h - 2)
          ..close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
      case MatchShape.star:
        final path = _getStarPath(w, h);
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;
    }
  }

  Path _getStarPath(double width, double height) {
    double cx = width / 2;
    double cy = height / 2;
    int points = 5;
    double outerRadius = width / 2 - 2;
    double innerRadius = outerRadius * 0.45;
    double rot = -pi / 2;
    double step = pi / points;

    Path path = Path();
    path.moveTo(cx + cos(rot) * outerRadius, cy + sin(rot) * outerRadius);
    for (int i = 0; i < points * 2; i++) {
      double r = (i % 2 == 0) ? outerRadius : innerRadius;
      double x = cx + cos(rot) * r;
      double y = cy + sin(rot) * r;
      path.lineTo(x, y);
      rot += step;
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}

class ConnectionPainter extends CustomPainter {
  final List<MatchConnection> connections;
  final int? activeStartLeftIndex;
  final Offset? dragPosition;
  final Size size;

  ConnectionPainter({
    required this.connections,
    required this.activeStartLeftIndex,
    required this.dragPosition,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    // 1. Draw existing connections
    for (var conn in connections) {
      final startPos = Offset(W * 0.26, H * (conn.leftIndex + 0.5) / 7);
      final endPos = Offset(W * 0.74, H * (conn.rightIndex + 0.5) / 7);

      final paint = Paint()
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(startPos + const Offset(0, 3), endPos + const Offset(0, 3), shadowPaint);

      canvas.drawLine(startPos, endPos, paint);
    }

    // 2. Draw active dragging line preview
    if (activeStartLeftIndex != null && dragPosition != null) {
      final startPos = Offset(W * 0.26, H * (activeStartLeftIndex! + 0.5) / 7);

      final dragPaint = Paint()
        ..color = const Color(0xFFFF9800)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(startPos, dragPosition!, dragPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return oldDelegate.connections.length != connections.length ||
        oldDelegate.activeStartLeftIndex != activeStartLeftIndex ||
        oldDelegate.dragPosition != dragPosition;
  }
}
