import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class FishShapeMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const FishShapeMatchingScreen({super.key, this.levelId = 47});

  @override
  ConsumerState<FishShapeMatchingScreen> createState() => _FishShapeMatchingScreenState();
}

class _FishShapeMatchingScreenState extends ConsumerState<FishShapeMatchingScreen> {
  // Level 47 matching definition
  final List<String> _fishList = [
    'puffer',     // 0: Puffer Fish (Yellow)
    'striped',    // 1: Black-Yellow Striped Fish
    'green',      // 2: Green Fish
    'pink',       // 3: Pink Fish
    'dark_blue',  // 4: Dark Blue Fish
    'light_blue', // 5: Light Blue Fish
    'clown',      // 6: Clown Fish (Orange)
  ];

  final List<String> _shapeList = [
    'triangle', // 0: Segitiga
    'star',     // 1: Bintang
    'heart',    // 2: Hati
    'hexagon',  // 3: Segienam
    'square',   // 4: Persegi
    'circle',   // 5: Lingkaran
    'diamond',  // 6: Belah Ketupat
  ];

  // Correct pairings (Fish index -> Shape index)
  // Ikan Badut (6) -> Segienam (3)
  // Ikan Biru Tua (4) -> Bintang (1)
  // Ikan Buntal (0) -> Persegi (4)
  // Ikan Biru Muda (5) -> Segitiga (0)
  // Ikan Pink (3) -> Hati (2)
  // Ikan Hijau (2) -> Lingkaran (5)
  // Ikan Garis Hitam-Kuning (1) -> Belah Ketupat (6)
  final Map<int, int> _correctPairings = {
    6: 3,
    4: 1,
    0: 4,
    5: 0,
    3: 2,
    2: 5,
    1: 6,
  };

  // State
  final Map<int, int> _completedLines = {}; // Fish index -> Shape index
  int? _activeStartFishIndex;
  Offset? _activeEndPosition;
  bool _isSolved = false;

  @visibleForTesting
  Map<int, int> get completedLines => _completedLines;

  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    setState(() {
      _completedLines.clear();
      _activeStartFishIndex = null;
      _activeEndPosition = null;
      _isSolved = false;
    });
  }

  void _handleLineDrop(int fishIndex, int shapeIndex) {
    if (_isSolved) return;

    if (_correctPairings[fishIndex] == shapeIndex) {
      // Correct match!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        _completedLines[fishIndex] = shapeIndex;
        // Verify win condition
        if (_completedLines.length == 7) {
          _onLevelComplete();
        }
      });
    } else {
      // Wrong match
      SoundService.playError();
      HapticFeedback.lightImpact(); // Trigger haptic warning for incorrect drop
    }
  }

  void _onLevelComplete() async {
    setState(() {
      _isSolved = true;
    });

    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    try {
      await UserService.updateProgress(widget.levelId);
    } catch (e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    }

    if (!mounted) return;
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: widget.levelId + 1,
      title: 'HEBAT! 🌟',
      message: 'Kamu berhasil mencocokkan semua gambar ikan dengan bentuk geometri yang sesuai!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 8),
            _buildLegendPreview(),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 3.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;

                        // Dynamic layout metrics
                        final leftAnchorX = 125.0;
                        final rightAnchorX = width - 125.0;

                        final y0 = height * 0.08;
                        final rowHeight = height * 0.13;

                        final List<Offset> leftAnchors = List.generate(
                          7, (i) => Offset(leftAnchorX, y0 + i * rowHeight),
                        );
                        final List<Offset> rightAnchors = List.generate(
                          7, (i) => Offset(rightAnchorX, y0 + i * rowHeight),
                        );

                        return GestureDetector(
                          key: const ValueKey('drawing_gesture_detector'),
                          onPanStart: (details) {
                            if (_isSolved) return;
                            final localPos = details.localPosition;

                            // Find nearest fish anchor point
                            for (int i = 0; i < leftAnchors.length; i++) {
                              if ((localPos - leftAnchors[i]).distance < 35.0) {
                                if (!_completedLines.containsKey(i)) {
                                  setState(() {
                                    _activeStartFishIndex = i;
                                    _activeEndPosition = localPos;
                                  });
                                  HapticService.light();
                                }
                                break;
                              }
                            }
                          },
                          onPanUpdate: (details) {
                            if (_activeStartFishIndex != null) {
                              setState(() {
                                _activeEndPosition = details.localPosition;
                              });
                            }
                          },
                          onPanEnd: (details) {
                            if (_activeStartFishIndex != null && _activeEndPosition != null) {
                              // Check if close to any shape anchor point
                              int matchedShapeIdx = -1;
                              for (int i = 0; i < rightAnchors.length; i++) {
                                if ((_activeEndPosition! - rightAnchors[i]).distance < 35.0) {
                                  matchedShapeIdx = i;
                                  break;
                                }
                              }

                              if (matchedShapeIdx != -1) {
                                _handleLineDrop(_activeStartFishIndex!, matchedShapeIdx);
                              }
                            }

                            setState(() {
                              _activeStartFishIndex = null;
                              _activeEndPosition = null;
                            });
                          },
                          child: Stack(
                            children: [
                              // 1. Line Drawing Painter Overlay
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: LinePainter(
                                    completedLines: _completedLines,
                                    activeStartFishIndex: _activeStartFishIndex,
                                    activeEndPosition: _activeEndPosition,
                                    leftAnchors: leftAnchors,
                                    rightAnchors: rightAnchors,
                                  ),
                                ),
                              ),

                              // 2. Render Left Column (Fish list)
                              ...List.generate(7, (i) {
                                final double cardH = 50.0;
                                final double cardW = 90.0;
                                final yPos = leftAnchors[i].dy;

                                return Positioned(
                                  left: 12,
                                  top: yPos - cardH / 2,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: cardW,
                                        height: cardH,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                                        ),
                                        child: CustomPaint(
                                          painter: FishPainter(_fishList[i]),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Right-pointing arrow anchor indicator
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: _completedLines.containsKey(i) 
                                            ? Colors.green.shade400 
                                            : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // 3. Render Right Column (Geometric Shapes list)
                              ...List.generate(7, (i) {
                                final double cardH = 50.0;
                                final double cardW = 90.0;
                                final yPos = rightAnchors[i].dy;

                                final bool isCorrectlyConnected = _completedLines.containsValue(i);

                                return Positioned(
                                  right: 12,
                                  top: yPos - cardH / 2,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Left-pointing arrow anchor indicator
                                      Icon(
                                        Icons.arrow_back_rounded,
                                        color: isCorrectlyConnected 
                                            ? Colors.green.shade400 
                                            : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: cardW,
                                        height: cardH,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                                        ),
                                        child: CustomPaint(
                                          painter: ShapePainter(_shapeList[i]),
                                        ),
                                      ),
                                    ],
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
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _resetLevel,
                icon: const Icon(Icons.refresh_rounded, color: Colors.indigo, size: 20),
                label: const Text(
                  'Ulangi',
                  style: TextStyle(
                    color: Colors.indigo,
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
              'Level 47',
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gesture_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Tarik garis dari titik ikan ke bentuk geometri yang sesuai!',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPreview() {
    final previewPairs = [
      {'fish': 'clown', 'shape': 'hexagon'},
      {'fish': 'dark_blue', 'shape': 'star'},
      {'fish': 'puffer', 'shape': 'square'},
      {'fish': 'light_blue', 'shape': 'triangle'},
      {'fish': 'pink', 'shape': 'heart'},
      {'fish': 'green', 'shape': 'circle'},
      {'fish': 'striped', 'shape': 'diamond'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'CONTOH PASANGAN (LEGEND)',
            style: GoogleFonts.fredoka(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: previewPairs.map((pair) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 20,
                        child: CustomPaint(painter: FishPainter(pair['fish']!)),
                      ),
                      const Icon(Icons.swap_horiz_rounded, size: 12, color: Colors.grey),
                      SizedBox(
                        width: 24,
                        height: 20,
                        child: CustomPaint(painter: ShapePainter(pair['shape']!)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CUSTOM PAINTERS ──────────────────────────────────────────────────────────

class FishPainter extends CustomPainter {
  final String fishType;
  FishPainter(this.fishType);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final eyePaint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    switch (fishType) {
      case 'puffer':
        bodyPaint.color = const Color(0xFFFFD54F);
        canvas.drawCircle(Offset(cx, cy), h * 0.35, bodyPaint);

        // Spikes
        final spikePaint = Paint()..color = const Color(0xFFFFD54F)..style = PaintingStyle.stroke..strokeWidth = 2.0;
        for (int i = 0; i < 8; i++) {
          double angle = i * pi / 4;
          canvas.drawLine(
            Offset(cx + cos(angle) * h * 0.35, cy + sin(angle) * h * 0.35),
            Offset(cx + cos(angle) * h * 0.43, cy + sin(angle) * h * 0.43),
            spikePaint,
          );
        }
        // Tail
        final tailPath = Path()
          ..moveTo(cx - h * 0.35, cy)
          ..lineTo(cx - w * 0.48, cy - h * 0.15)
          ..lineTo(cx - w * 0.48, cy + h * 0.15)
          ..close();
        canvas.drawPath(tailPath, bodyPaint);
        // Eye
        canvas.drawCircle(Offset(cx + w * 0.12, cy - h * 0.1), 3.0, eyePaint);
        break;

      case 'striped':
        bodyPaint.color = const Color(0xFFFFEB3B);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.65, height: h * 0.5), bodyPaint);
        // Tail
        final tailPath = Path()
          ..moveTo(cx - w * 0.325, cy)
          ..lineTo(cx - w * 0.46, cy - h * 0.15)
          ..lineTo(cx - w * 0.46, cy + h * 0.15)
          ..close();
        canvas.drawPath(tailPath, bodyPaint);
        // Black stripes
        final stripePaint = Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 4.0;
        canvas.drawLine(Offset(cx - w * 0.08, cy - h * 0.22), Offset(cx - w * 0.08, cy + h * 0.22), stripePaint);
        canvas.drawLine(Offset(cx + w * 0.08, cy - h * 0.22), Offset(cx + w * 0.08, cy + h * 0.22), stripePaint);
        // Eye
        canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.08), 3.0, eyePaint);
        break;

      case 'green':
        bodyPaint.color = const Color(0xFF4CAF50);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.68, height: h * 0.5), bodyPaint);
        // Tail
        final tailPath = Path()
          ..moveTo(cx - w * 0.34, cy)
          ..lineTo(cx - w * 0.46, cy - h * 0.15)
          ..lineTo(cx - w * 0.46, cy + h * 0.15)
          ..close();
        canvas.drawPath(tailPath, bodyPaint);
        // Stripes
        final stripePaint = Paint()..color = const Color(0xFFFFEE58)..style = PaintingStyle.stroke..strokeWidth = 3.0;
        canvas.drawLine(Offset(cx - w * 0.08, cy - h * 0.2), Offset(cx - w * 0.08, cy + h * 0.2), stripePaint);
        canvas.drawLine(Offset(cx + w * 0.06, cy - h * 0.2), Offset(cx + w * 0.06, cy + h * 0.2), stripePaint);
        // Eye
        canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.08), 3.0, eyePaint);
        break;

      case 'pink':
        bodyPaint.color = const Color(0xFFE91E63);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.68, height: h * 0.5), bodyPaint);
        // Tail
        final tailPath = Path()
          ..moveTo(cx - w * 0.34, cy)
          ..lineTo(cx - w * 0.46, cy - h * 0.15)
          ..lineTo(cx - w * 0.46, cy + h * 0.15)
          ..close();
        canvas.drawPath(tailPath, bodyPaint);
        // Stripes
        final stripePaint = Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 3.0;
        canvas.drawLine(Offset(cx - w * 0.08, cy - h * 0.2), Offset(cx - w * 0.08, cy + h * 0.2), stripePaint);
        canvas.drawLine(Offset(cx + w * 0.06, cy - h * 0.2), Offset(cx + w * 0.06, cy + h * 0.2), stripePaint);
        // Eye
        canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.08), 3.0, eyePaint);
        break;

      case 'dark_blue':
        bodyPaint.color = const Color(0xFF1E3A8A);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.68, height: h * 0.45), bodyPaint);
        // Tail
        final tailPath = Path()
          ..moveTo(cx - w * 0.34, cy)
          ..lineTo(cx - w * 0.46, cy - h * 0.15)
          ..lineTo(cx - w * 0.46, cy + h * 0.15)
          ..close();
        canvas.drawPath(tailPath, bodyPaint);
        // Eye
        canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.08), 3.0, eyePaint);
        break;

      case 'light_blue':
        bodyPaint.color = const Color(0xFF60A5FA);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.68, height: h * 0.5), bodyPaint);
        // Tail
        final tailPath = Path()
          ..moveTo(cx - w * 0.34, cy)
          ..lineTo(cx - w * 0.46, cy - h * 0.15)
          ..lineTo(cx - w * 0.46, cy + h * 0.15)
          ..close();
        canvas.drawPath(tailPath, bodyPaint);
        // Stripes
        final stripePaint = Paint()..color = const Color(0xFFFBBF24)..style = PaintingStyle.stroke..strokeWidth = 3.0;
        canvas.drawLine(Offset(cx - w * 0.12, cy - h * 0.2), Offset(cx - w * 0.12, cy + h * 0.2), stripePaint);
        canvas.drawLine(Offset(cx + w * 0.04, cy - h * 0.2), Offset(cx + w * 0.04, cy + h * 0.2), stripePaint);
        // Eye
        canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.08), 3.0, eyePaint);
        break;

      case 'clown':
        bodyPaint.color = const Color(0xFFFF5722);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.68, height: h * 0.48), bodyPaint);
        // Tail
        final tailPath = Path()
          ..moveTo(cx - w * 0.34, cy)
          ..lineTo(cx - w * 0.46, cy - h * 0.15)
          ..lineTo(cx - w * 0.46, cy + h * 0.15)
          ..close();
        canvas.drawPath(tailPath, bodyPaint);
        // White stripe with black borders
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.1, height: h * 0.46), whitePaint);
        final borderPaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2.0;
        canvas.drawLine(Offset(cx - w * 0.05, cy - h * 0.23), Offset(cx - w * 0.05, cy + h * 0.23), borderPaint);
        canvas.drawLine(Offset(cx + w * 0.05, cy - h * 0.23), Offset(cx + w * 0.05, cy + h * 0.23), borderPaint);
        // Eye
        canvas.drawCircle(Offset(cx + w * 0.18, cy - h * 0.08), 3.0, eyePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShapePainter extends CustomPainter {
  final String shapeType;
  ShapePainter(this.shapeType);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    final paint = Paint()
      ..color = Colors.deepPurple.shade700
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (shapeType) {
      case 'triangle':
        final path = Path()
          ..moveTo(cx, cy - h * 0.35)
          ..lineTo(cx - w * 0.35, cy + h * 0.28)
          ..lineTo(cx + w * 0.35, cy + h * 0.28)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'star':
        final path = Path();
        int points = 5;
        double outerRadius = w * 0.36;
        double innerRadius = w * 0.16;
        double angle = -pi / 2;
        double angleStep = pi / points;
        path.moveTo(cx + cos(angle) * outerRadius, cy + sin(angle) * outerRadius);
        for (int i = 0; i < points * 2; i++) {
          angle += angleStep;
          double r = (i % 2 == 0) ? innerRadius : outerRadius;
          path.lineTo(cx + cos(angle) * r, cy + sin(angle) * r);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'heart':
        final path = Path()
          ..moveTo(cx, cy + h * 0.23)
          ..cubicTo(cx - w * 0.42, cy - h * 0.18, cx - w * 0.23, cy - h * 0.42, cx, cy - h * 0.18)
          ..cubicTo(cx + w * 0.23, cy - h * 0.42, cx + w * 0.42, cy - h * 0.18, cx, cy + h * 0.23);
        canvas.drawPath(path, paint);
        break;
      case 'hexagon':
        final path = Path();
        for (int i = 0; i < 6; i++) {
          double angle = i * pi / 3 - pi / 6;
          double x = cx + cos(angle) * w * 0.35;
          double y = cy + sin(angle) * h * 0.35;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'square':
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.58, height: h * 0.58), paint);
        break;
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), w * 0.32, paint);
        break;
      case 'diamond':
        final path = Path()
          ..moveTo(cx, cy - h * 0.35)
          ..lineTo(cx + w * 0.35, cy)
          ..lineTo(cx, cy + h * 0.35)
          ..lineTo(cx - w * 0.35, cy)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LinePainter extends CustomPainter {
  final Map<int, int> completedLines;
  final int? activeStartFishIndex;
  final Offset? activeEndPosition;
  final List<Offset> leftAnchors;
  final List<Offset> rightAnchors;

  LinePainter({
    required this.completedLines,
    this.activeStartFishIndex,
    this.activeEndPosition,
    required this.leftAnchors,
    required this.rightAnchors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Distinct matching line colors mapped by fish index
    final List<Color> fishLineColors = [
      const Color(0xFFD97706), // Puffer - Golden Yellow
      const Color(0xFF4B5563), // Striped - Gray
      const Color(0xFF16A34A), // Green
      const Color(0xFFDB2777), // Pink
      const Color(0xFF1E3A8A), // Dark Blue
      const Color(0xFF2563EB), // Light Blue
      const Color(0xFFEA580C), // Clown - Orange/Red
    ];

    // Paint completed lines
    completedLines.forEach((fishIdx, shapeIdx) {
      if (fishIdx >= 0 && fishIdx < leftAnchors.length && shapeIdx >= 0 && shapeIdx < rightAnchors.length) {
        final linePaint = Paint()
          ..color = fishLineColors[fishIdx].withOpacity(0.85)
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.drawLine(leftAnchors[fishIdx], rightAnchors[shapeIdx], linePaint);

        // Draw small endpoints indicators
        final dotPaint = Paint()..color = fishLineColors[fishIdx]..style = PaintingStyle.fill;
        canvas.drawCircle(leftAnchors[fishIdx], 5.5, dotPaint);
        canvas.drawCircle(rightAnchors[shapeIdx], 5.5, dotPaint);
      }
    });

    // Paint active line dragging
    if (activeStartFishIndex != null && activeEndPosition != null) {
      final activePaint = Paint()
        ..color = Colors.indigo.withOpacity(0.6)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(leftAnchors[activeStartFishIndex!], activeEndPosition!, activePaint);

      final startDotPaint = Paint()..color = Colors.indigo..style = PaintingStyle.fill;
      canvas.drawCircle(leftAnchors[activeStartFishIndex!], 5.0, startDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) => true;
}
