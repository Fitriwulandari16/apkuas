import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvancedLineTracingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const AdvancedLineTracingScreen({super.key, this.levelId = 2});

  @override
  ConsumerState<AdvancedLineTracingScreen> createState() => _AdvancedLineTracingScreenState();
}

class _AdvancedLineTracingScreenState extends ConsumerState<AdvancedLineTracingScreen> {
  final List<Offset> dotPositions = [
    const Offset(0.25, 0.25), // Top-left
    const Offset(0.75, 0.25), // Top-right
    const Offset(0.25, 0.75), // Bottom-left
    const Offset(0.75, 0.75), // Bottom-right
  ];

  late List<LineChallenge> _challenges;

  // Active drawing state
  int? _activeChallengeId;
  int? _activeStartDotIndex;
  Offset? _currentDragPosition;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    _challenges = [
      LineChallenge(
        id: 0,
        color: const Color(0xFFFFB300), // Amber
        title: 'Garis Vertikal',
        expectedLines: [const _Line(0, 2), const _Line(1, 3)],
      ),
      LineChallenge(
        id: 1,
        color: const Color(0xFF1E88E5), // Blue
        title: 'Garis Horizontal',
        expectedLines: [const _Line(0, 1), const _Line(2, 3)],
      ),
      LineChallenge(
        id: 2,
        color: const Color(0xFFE53935), // Red
        title: 'Garis Diagonal',
        expectedLines: [const _Line(0, 3), const _Line(1, 2)],
      ),
    ];
  }

  void _resetLevel() {
    setState(() {
      for (var challenge in _challenges) {
        challenge.drawnLines = [];
        challenge.isCompleted = false;
      }
      _activeChallengeId = null;
      _activeStartDotIndex = null;
      _currentDragPosition = null;
      _isDrawing = false;
    });
  }

  void _handlePanStart(int challengeId, Offset localPos, Size size) {
    final challenge = _challenges[challengeId];
    if (challenge.isCompleted) return;

    final dotIndex = _findNearestDot(localPos, size);
    if (dotIndex != null) {
      HapticService.light();
      setState(() {
        _activeChallengeId = challengeId;
        _activeStartDotIndex = dotIndex;
        _currentDragPosition = localPos;
        _isDrawing = true;
      });
    } else {
      setState(() {
        _isDrawing = true;
      });
    }
  }

  void _handlePanUpdate(int challengeId, Offset localPos) {
    if (_activeChallengeId != challengeId) return;
    setState(() {
      _currentDragPosition = localPos;
    });
  }

  void _handlePanEnd(int challengeId, Size size) {
    setState(() {
      _isDrawing = false;
    });

    if (_activeChallengeId != challengeId ||
        _activeStartDotIndex == null ||
        _currentDragPosition == null) {
      setState(() {
        _activeChallengeId = null;
        _activeStartDotIndex = null;
        _currentDragPosition = null;
      });
      return;
    }

    final challenge = _challenges[challengeId];
    final endDotIndex = _findNearestDot(_currentDragPosition!, size);

    if (endDotIndex != null && endDotIndex != _activeStartDotIndex) {
      final newLine = _Line(_activeStartDotIndex!, endDotIndex);

      // Check if this connection matches any expected line
      bool isMatch = challenge.expectedLines.any((tl) => tl == newLine);

      if (isMatch) {
        // Check if already drawn
        bool alreadyDrawn = challenge.drawnLines.any((dl) => dl == newLine);

        if (!alreadyDrawn) {
          SoundService.playSuccess();
          HapticService.success();

          setState(() {
            challenge.drawnLines.add(newLine);
            if (challenge.drawnLines.length == challenge.expectedLines.length) {
              challenge.isCompleted = true;
            }
          });

          // Check level completion
          if (_challenges.every((c) => c.isCompleted)) {
            _checkLevelComplete();
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
      _activeChallengeId = null;
      _activeStartDotIndex = null;
      _currentDragPosition = null;
    });
  }

  void _checkLevelComplete() {
    if (_challenges.every((c) => c.isCompleted)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _completeGame();
        }
      });
    }
  }

  void _completeGame() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    HapticService.success();
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 3,
      title: 'LUAR BIASA! 🎉',
      message: 'Level 2 Selesai! Kamu arsitek yang sangat pintar!',
    );
  }

  Offset _getDotPosition(int index, Size size) {
    return Offset(
      dotPositions[index].dx * size.width,
      dotPositions[index].dy * size.height,
    );
  }

  int? _findNearestDot(Offset pos, Size size) {
    double threshold = 35.0;
    for (int i = 0; i < 4; i++) {
      Offset dotPos = _getDotPosition(i, size);
      if ((pos - dotPos).distance < threshold) {
        return i;
      }
    }
    return null;
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
              _buildInstruction(),
              Expanded(
                child: SingleChildScrollView(
                  physics: _isDrawing
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        _buildRowChallenge(0),
                        const WavyDivider(),
                        _buildRowChallenge(1),
                        const WavyDivider(),
                        _buildRowChallenge(2),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton.icon(
                            onPressed: _resetLevel,
                            icon: const Icon(Icons.refresh_rounded, color: Colors.orange, size: 20),
                            label: const Text(
                              'Ulangi',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
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
              'Garis Majemuk',
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
          const Icon(Icons.create_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Tiru garis tegak, datar, dan miring di bawah ini!',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowChallenge(int index) {
    final challenge = _challenges[index];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                challenge.title,
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: challenge.color.withOpacity(0.85),
                ),
              ),
              if (challenge.isCompleted)
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai!',
                      style: GoogleFonts.fredoka(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Sisi Kiri: Contoh (Read-only)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _StaticLinesPainter(
                                  lines: challenge.expectedLines,
                                  color: challenge.color,
                                  getDotPositions: (s) => [
                                    _getDotPosition(0, s),
                                    _getDotPosition(1, s),
                                    _getDotPosition(2, s),
                                    _getDotPosition(3, s),
                                  ],
                                ),
                              ),
                            ),
                            // Dots
                            ...List.generate(4, (dotIndex) {
                              final pos = _getDotPosition(dotIndex, size);
                              return Positioned(
                                left: pos.dx - 8,
                                top: pos.dy - 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD54F),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ),
              // Sisi Kanan: Area Gambar (Interactive)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);

                      return RawGestureDetector(
                        key: ValueKey('drawing_area_${challenge.id}'),
                        gestures: <Type, GestureRecognizerFactory>{
                          EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerPanGestureRecognizer>(
                            () => EagerPanGestureRecognizer(debugOwner: 'eagerPan'),
                            (EagerPanGestureRecognizer instance) {
                              instance.onStart = (details) => _handlePanStart(challenge.id, details.localPosition, size);
                              instance.onUpdate = (details) => _handlePanUpdate(challenge.id, details.localPosition);
                              instance.onEnd = (details) => _handlePanEnd(challenge.id, size);
                              instance.onCancel = () {
                                setState(() {
                                  _isDrawing = false;
                                  _activeChallengeId = null;
                                  _activeStartDotIndex = null;
                                  _currentDragPosition = null;
                                });
                              };
                            },
                          ),
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: challenge.isCompleted ? challenge.color.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: challenge.isCompleted ? challenge.color : Colors.grey.shade200,
                              width: challenge.isCompleted ? 2.0 : 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _InteractiveLinesPainter(
                                    drawnLines: challenge.drawnLines,
                                    color: challenge.color,
                                    isDrawing: _activeChallengeId == challenge.id,
                                    activeStartDot: _activeStartDotIndex,
                                    dragPos: _currentDragPosition,
                                    getDotPositions: (s) => [
                                      _getDotPosition(0, s),
                                      _getDotPosition(1, s),
                                      _getDotPosition(2, s),
                                      _getDotPosition(3, s),
                                    ],
                                  ),
                                ),
                              ),
                              // Dots
                              ...List.generate(4, (dotIndex) {
                                final pos = _getDotPosition(dotIndex, size);
                                final isStartDot = _activeChallengeId == challenge.id && _activeStartDotIndex == dotIndex;

                                return Positioned(
                                  left: pos.dx - 8,
                                  top: pos.dy - 8,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isStartDot ? 20 : 16,
                                    height: isStartDot ? 20 : 16,
                                    decoration: BoxDecoration(
                                      color: challenge.isCompleted
                                          ? challenge.color
                                          : (isStartDot ? challenge.color : const Color(0xFFFFD54F)),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        if (isStartDot || challenge.isCompleted)
                                          BoxShadow(
                                            color: challenge.color.withOpacity(0.5),
                                            blurRadius: 6,
                                            spreadRadius: 2,
                                          )
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line {
  final int start;
  final int end;
  const _Line(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      other is _Line &&
      ((start == other.start && end == other.end) || (start == other.end && end == other.start));

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class LineChallenge {
  final int id;
  final Color color;
  final String title;
  final List<_Line> expectedLines;
  List<_Line> drawnLines;
  bool isCompleted;

  LineChallenge({
    required this.id,
    required this.color,
    required this.title,
    required this.expectedLines,
  })  : drawnLines = [],
        isCompleted = false;
}

class WavyDivider extends StatelessWidget {
  final Color color;
  const WavyDivider({super.key, this.color = const Color(0xFF29B6F6)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: CustomPaint(
        size: const Size(double.infinity, 12),
        painter: _WavyPainter(color: color),
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  final Color color;
  _WavyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);

    double waveLength = 16.0;
    double amplitude = 3.0;
    for (double x = 0; x < size.width; x += waveLength) {
      path.relativeQuadraticBezierTo(
        waveLength / 4, -amplitude,
        waveLength / 2, 0,
      );
      path.relativeQuadraticBezierTo(
        waveLength / 4, amplitude,
        waveLength / 2, 0,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StaticLinesPainter extends CustomPainter {
  final List<_Line> lines;
  final Color color;
  final List<Offset> Function(Size) getDotPositions;

  _StaticLinesPainter({
    required this.lines,
    required this.color,
    required this.getDotPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dots = getDotPositions(size);

    for (var line in lines) {
      canvas.drawLine(dots[line.start], dots[line.end], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticLinesPainter oldDelegate) => false;
}

class _InteractiveLinesPainter extends CustomPainter {
  final List<_Line> drawnLines;
  final Color color;
  final bool isDrawing;
  final int? activeStartDot;
  final Offset? dragPos;
  final List<Offset> Function(Size) getDotPositions;

  _InteractiveLinesPainter({
    required this.drawnLines,
    required this.color,
    required this.isDrawing,
    required this.activeStartDot,
    required this.dragPos,
    required this.getDotPositions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dots = getDotPositions(size);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var line in drawnLines) {
      canvas.drawLine(dots[line.start], dots[line.end], paint);
    }

    if (isDrawing && activeStartDot != null && dragPos != null) {
      final previewPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(dots[activeStartDot!], dragPos!, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveLinesPainter oldDelegate) {
    return oldDelegate.drawnLines.length != drawnLines.length ||
        oldDelegate.isDrawing != isDrawing ||
        oldDelegate.dragPos != dragPos;
  }
}

class EagerPanGestureRecognizer extends PanGestureRecognizer {
  EagerPanGestureRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
