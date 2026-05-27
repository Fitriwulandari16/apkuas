import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class PatternLetterImitationScreen extends ConsumerStatefulWidget {
  final int levelId;
  const PatternLetterImitationScreen({super.key, this.levelId = 25});

  @override
  ConsumerState<PatternLetterImitationScreen> createState() => _PatternLetterImitationScreenState();
}

class LetterPatternChallenge {
  final int id;
  final Color color;
  final String title;
  final List<Set<int>> expectedLines;
  List<Set<int>> drawnLines;
  bool isCompleted;

  LetterPatternChallenge({
    required this.id,
    required this.color,
    required this.title,
    required this.expectedLines,
  })  : drawnLines = [],
        isCompleted = false;
}

class _PatternLetterImitationScreenState extends ConsumerState<PatternLetterImitationScreen> {
  late List<LetterPatternChallenge> _challenges;

  // Active drawing state
  int? _activeChallengeId;
  int? _activeStartDotIndex;
  Offset? _currentDragPosition;

  // Premium colors corresponding to the textbook image
  static const Color colBlue = Color(0xFF29B6F6);    // Baris 1: Biru (Huruf T)
  static const Color colBrown = Color(0xFF8D6E63);   // Baris 2: Cokelat (Huruf U)
  static const Color colLightGreen = Color(0xFF9CCC65); // Baris 3: Hijau Muda (Huruf N/Z)
  static const Color colPurple = Color(0xFFAB47BC);  // Baris 4: Ungu (Huruf G)

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    _challenges = [
      // Baris 1: Huruf T
      LetterPatternChallenge(
        id: 0,
        color: colBlue,
        title: 'Huruf T',
        expectedLines: [
          {0, 2}, // Atas horizontal (0-1-2)
          {1, 7}, // Tengah vertikal (1-4-7)
        ],
      ),
      // Baris 2: Huruf U (Alternating / S-like path)
      LetterPatternChallenge(
        id: 1,
        color: colBrown,
        title: 'Huruf U',
        expectedLines: [
          {6, 0}, // Kiri vertikal (6-3-0)
          {0, 1}, // Atas horizontal (0-1)
          {1, 7}, // Tengah vertikal (1-4-7)
          {7, 8}, // Bawah horizontal (7-8)
          {8, 2}, // Kanan vertikal (8-5-2)
        ],
      ),
      // Baris 3: Huruf N (Z-like path)
      LetterPatternChallenge(
        id: 2,
        color: colLightGreen,
        title: 'Huruf N',
        expectedLines: [
          {0, 2}, // Atas horizontal (0-1-2)
          {2, 6}, // Diagonal miring (2-4-6)
          {6, 8}, // Bawah horizontal (6-7-8)
        ],
      ),
      // Baris 4: Huruf G
      LetterPatternChallenge(
        id: 3,
        color: colPurple,
        title: 'Huruf G',
        expectedLines: [
          {2, 0}, // Atas horizontal (2-1-0)
          {0, 6}, // Kiri vertikal (0-3-6)
          {6, 8}, // Bawah horizontal (6-7-8)
          {8, 5}, // Kanan bawah vertikal (8-5)
          {5, 4}, // Tengah horizontal (5-4)
        ],
      ),
    ];
  }

  Offset _getDotPosition(int index, Size size) {
    double padding = size.width * 0.15;
    double spacing = (size.width - 2 * padding) / 2;
    int row = index ~/ 3;
    int col = index % 3;
    return Offset(padding + col * spacing, padding + row * spacing);
  }

  int? _findNearestDot(Offset pos, Size size) {
    double threshold = 28.0;
    for (int i = 0; i < 9; i++) {
      Offset dotPos = _getDotPosition(i, size);
      if ((pos - dotPos).distance < threshold) {
        return i;
      }
    }
    return null;
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
    if (_activeChallengeId != challengeId || _activeStartDotIndex == null || _currentDragPosition == null) return;

    final challenge = _challenges[challengeId];
    final endDotIndex = _findNearestDot(_currentDragPosition!, size);

    if (endDotIndex != null && endDotIndex != _activeStartDotIndex) {
      final connection = {_activeStartDotIndex!, endDotIndex};

      // Check if this connection matches any expected line
      bool isMatch = false;
      for (var expected in challenge.expectedLines) {
        if (expected.contains(_activeStartDotIndex!) && expected.contains(endDotIndex)) {
          isMatch = true;
          break;
        }
      }

      if (isMatch) {
        // Check if already drawn
        bool alreadyDrawn = false;
        for (var drawn in challenge.drawnLines) {
          if (drawn.contains(_activeStartDotIndex!) && drawn.contains(endDotIndex)) {
            alreadyDrawn = true;
            break;
          }
        }

        if (!alreadyDrawn) {
          SoundService.playSuccess();
          HapticService.success();

          setState(() {
            challenge.drawnLines.add(connection);
            if (challenge.drawnLines.length == challenge.expectedLines.length) {
              challenge.isCompleted = true;
            }
          });

          // Check level completion
          if (_challenges.every((c) => c.isCompleted)) {
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
      _activeChallengeId = null;
      _activeStartDotIndex = null;
      _currentDragPosition = null;
    });
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 26, // Fallback to map or upcoming stages
      title: 'Hebat Sekali!',
      message: 'Kamu berhasil meniru semua pola huruf dengan sempurna!',
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      _buildRowChallenge(0),
                      const WavyDivider(color: colBlue),
                      _buildRowChallenge(1),
                      const WavyDivider(color: colBrown),
                      _buildRowChallenge(2),
                      const WavyDivider(color: colLightGreen),
                      _buildRowChallenge(3),
                      const SizedBox(height: 30),
                    ],
                  ),
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
              'Level 25',
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
          const Icon(Icons.spellcheck_rounded, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Gambarkan garis yang sama di sebelah kanan!',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
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
          // Row Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                challenge.title,
                style: GoogleFonts.fredoka(
                  fontSize: 15,
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

          // Double Grid Layout (Example Left, Draw Right)
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
                            // Lines
                            Positioned.fill(
                              child: CustomPaint(
                                painter: StaticLinesPainter(
                                  lines: challenge.expectedLines,
                                  color: challenge.color,
                                  size: size,
                                ),
                              ),
                            ),
                            // Dots
                            ...List.generate(9, (dotIndex) {
                              final pos = _getDotPosition(dotIndex, size);
                              return Positioned(
                                left: pos.dx - 8,
                                top: pos.dy - 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: challenge.color.withOpacity(0.9),
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

              // Arrow Indicator middle
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

                      return GestureDetector(
                        onPanStart: (details) => _handlePanStart(challenge.id, details.localPosition, size),
                        onPanUpdate: (details) => _handlePanUpdate(challenge.id, details.localPosition),
                        onPanEnd: (details) => _handlePanEnd(challenge.id, size),
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
                              // Lines (Drawn + Drag preview)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: InteractiveLinesPainter(
                                    drawnLines: challenge.drawnLines,
                                    color: challenge.color,
                                    isDrawing: _activeChallengeId == challenge.id,
                                    activeStartDot: _activeStartDotIndex,
                                    dragPos: _currentDragPosition,
                                    size: size,
                                  ),
                                ),
                              ),

                              // Dots
                              ...List.generate(9, (dotIndex) {
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
                                          : (isStartDot ? challenge.color : Colors.grey.shade300),
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

class WavyDivider extends StatelessWidget {
  final Color color;
  const WavyDivider({super.key, required this.color});

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
      ..color = color.withOpacity(0.25)
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

class StaticLinesPainter extends CustomPainter {
  final List<Set<int>> lines;
  final Color color;
  final Size size;

  StaticLinesPainter({
    required this.lines,
    required this.color,
    required this.size,
  });

  Offset _getDotPosition(int index, Size size) {
    double padding = size.width * 0.15;
    double spacing = (size.width - 2 * padding) / 2;
    int row = index ~/ 3;
    int col = index % 3;
    return Offset(padding + col * spacing, padding + row * spacing);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var line in lines) {
      final list = line.toList();
      if (list.length == 2) {
        final start = _getDotPosition(list[0], size);
        final end = _getDotPosition(list[1], size);
        canvas.drawLine(start, end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaticLinesPainter oldDelegate) => false;
}

class InteractiveLinesPainter extends CustomPainter {
  final List<Set<int>> drawnLines;
  final Color color;
  final bool isDrawing;
  final int? activeStartDot;
  final Offset? dragPos;
  final Size size;

  InteractiveLinesPainter({
    required this.drawnLines,
    required this.color,
    required this.isDrawing,
    required this.activeStartDot,
    required this.dragPos,
    required this.size,
  });

  Offset _getDotPosition(int index, Size size) {
    double padding = size.width * 0.15;
    double spacing = (size.width - 2 * padding) / 2;
    int row = index ~/ 3;
    int col = index % 3;
    return Offset(padding + col * spacing, padding + row * spacing);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw already correct drawn lines
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var line in drawnLines) {
      final list = line.toList();
      if (list.length == 2) {
        final start = _getDotPosition(list[0], size);
        final end = _getDotPosition(list[1], size);
        canvas.drawLine(start, end, paint);
      }
    }

    // Draw active drawing line preview
    if (isDrawing && activeStartDot != null && dragPos != null) {
      final start = _getDotPosition(activeStartDot!, size);
      final previewPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, dragPos!, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveLinesPainter oldDelegate) {
    return oldDelegate.drawnLines.length != drawnLines.length ||
        oldDelegate.isDrawing != isDrawing ||
        oldDelegate.dragPos != dragPos;
  }
}
