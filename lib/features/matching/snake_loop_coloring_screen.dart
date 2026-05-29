import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SnakeSegment {
  final int index;
  final Offset position;
  final Color expectedColor;
  Color? currentColor;

  SnakeSegment({
    required this.index,
    required this.position,
    required this.expectedColor,
    this.currentColor,
  });
}

class SnakeLoopColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const SnakeLoopColoringScreen({super.key, this.levelId = 33});

  @override
  ConsumerState<SnakeLoopColoringScreen> createState() => _SnakeLoopColoringScreenState();
}

class _SnakeLoopColoringScreenState extends ConsumerState<SnakeLoopColoringScreen> {
  static const Color colYellow = Color(0xFFFDD835); // Head Yellow
  static const Color colGreen = Color(0xFF4CAF50);  // Loop Green
  static const Color colOrange = Color(0xFFFF9800); // Loop Orange

  Color? _selectedColor;
  late List<SnakeSegment> _segments;
  int _currentToColorIndex = 3; // Neck and segment 2 are pre-colored (0, 1, 2)

  // Track shake animation for incorrect tap
  int? _shakingIndex;

  @override
  void initState() {
    super.initState();
    _initSnake();
  }

  void _initSnake() {
    // Winding snake positions in normalized coordinates [0..1]
    final List<Offset> positions = [
      const Offset(0.24, 0.24), // 0: Head (Yellow)
      const Offset(0.36, 0.28), // 1: Neck (Green)
      const Offset(0.48, 0.32), // 2: Segment (Orange)
      const Offset(0.60, 0.31), // 3: Hijau
      const Offset(0.71, 0.26), // 4: Oranye
      const Offset(0.80, 0.22), // 5: Hijau
      const Offset(0.85, 0.31), // 6: Oranye
      const Offset(0.81, 0.41), // 7: Hijau
      const Offset(0.71, 0.47), // 8: Oranye
      const Offset(0.59, 0.49), // 9: Hijau
      const Offset(0.47, 0.49), // 10: Oranye
      const Offset(0.35, 0.47), // 11: Hijau
      const Offset(0.24, 0.43), // 12: Oranye
      const Offset(0.15, 0.46), // 13: Hijau
      const Offset(0.12, 0.55), // 14: Oranye
      const Offset(0.16, 0.64), // 15: Hijau
      const Offset(0.26, 0.69), // 16: Oranye
      const Offset(0.38, 0.71), // 17: Hijau
      const Offset(0.50, 0.71), // 18: Oranye
      const Offset(0.62, 0.69), // 19: Hijau
      const Offset(0.73, 0.66), // 20: Oranye
      const Offset(0.82, 0.69), // 21: Hijau
      const Offset(0.85, 0.78), // 22: Oranye
      const Offset(0.78, 0.85), // 23: Hijau
      const Offset(0.67, 0.85), // 24: Oranye (Tail)
    ];

    _segments = List.generate(positions.length, (i) {
      Color expected;
      Color? current;

      if (i == 0) {
        expected = colYellow;
        current = colYellow;
      } else {
        // Pattern: Hijau (1), Oranye (2), Hijau (3), Oranye (4)...
        expected = (i % 2 == 1) ? colGreen : colOrange;
        if (i < 3) {
          current = expected; // Pre-colored
        }
      }

      return SnakeSegment(
        index: i,
        position: positions[i],
        expectedColor: expected,
        currentColor: current,
      );
    });
  }

  void _handleSegmentTap(int index) {
    if (index < 3) return; // Head and initial segments cannot be changed
    if (index < _currentToColorIndex) return; // Already colored correctly

    if (index > _currentToColorIndex) {
      // Out of order tap - show visual hint
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Warnai tubuh ular berurutan dari leher ke ekor ya!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_selectedColor == null) {
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih warna Hijau atau Oranye di bawah terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final targetSegment = _segments[index];

    if (_selectedColor == targetSegment.expectedColor) {
      // Success match!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        targetSegment.currentColor = _selectedColor;
        _currentToColorIndex++;
      });

      // Check if snake loop is completed
      if (_currentToColorIndex >= _segments.length) {
        _onLevelComplete();
      }
    } else {
      // Shake segment
      _shakeSegment(index);
    }
  }

  void _shakeSegment(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _shakingIndex = null;
      });
    }
  }

  void _onLevelComplete() async {
    // 1. Complete level in local notifier
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to Firebase
    try {
      await UserService.updateProgress(33);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 33: $e');
    }

    if (!mounted) return;

    // 3. Show Final Victory Dialog
    _showFinalVictoryDialog();
  }

  void _showFinalVictoryDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'FinalVictory',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFFFD54F), width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Graduation cup / Trophy icon
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD54F),
                      size: 110,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HORE! KAMU LULUS!',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selamat! Kamu telah menyelesaikan semua materi Coding Level 2 dengan sangat luar biasa!',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildSkillRow(Icons.check_circle_outline, 'Pola & Pengenalan Pola'),
                          const SizedBox(height: 6),
                          _buildSkillRow(Icons.loop_rounded, 'Algoritma Perulangan (Loop)'),
                          const SizedBox(height: 6),
                          _buildSkillRow(Icons.bug_report_outlined, 'Logika Kondisional & Debugging'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        // Pop dialog and return to adventure map
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close level 33 screen
                      },
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillRow(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ],
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    final W = size.width;
                    final H = size.height;

                    final double segmentSize = min(W * 0.12, 48.0);

                    return Stack(
                      children: [
                        // Winding Body Connection Line (Background stroke of the snake)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SnakeBodyPainter(
                              segments: _segments,
                            ),
                          ),
                        ),

                        // Interactive Snake segment spots
                        ..._segments.map((segment) {
                          final double shakeX = (_shakingIndex == segment.index) ? 8.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;
                          final center = Offset(
                            segment.position.dx * W + shakeX,
                            segment.position.dy * H,
                          );

                          final isNextToColor = segment.index == _currentToColorIndex;

                          return Positioned(
                            left: center.dx - segmentSize / 2,
                            top: center.dy - segmentSize / 2,
                            child: GestureDetector(
                              onTap: () => _handleSegmentTap(segment.index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: segmentSize,
                                height: segmentSize,
                                decoration: BoxDecoration(
                                  color: segment.currentColor ?? Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isNextToColor 
                                        ? const Color(0xFF2196F3) 
                                        : const Color(0xFF37474F),
                                    width: isNextToColor ? 3.5 : 2.5,
                                  ),
                                  boxShadow: [
                                    if (isNextToColor)
                                      BoxShadow(
                                        color: const Color(0xFF2196F3).withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    else
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: segment.index == 0
                                      ? const Text('🐱', style: TextStyle(fontSize: 22)) // Cute Head Emoji (or we draw cartoon face on painter)
                                      : segment.index == _segments.length - 1
                                          ? const Icon(Icons.star, color: Colors.amber, size: 18)
                                          : null,
                                ),
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
            _buildPalette(),
            const SizedBox(height: 12),
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
              'Level 33',
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
          const Icon(Icons.loop_rounded, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Ulangi pola warna: Hijau -> Oranye -> Hijau...',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalette() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [colGreen, colOrange].map((color) {
          final isSelected = _selectedColor == color;
          String colorText = color == colGreen ? 'Hijau' : 'Oranye';

          return GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() {
                _selectedColor = color;
              });
            },
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
                        width: isSelected ? 3.5 : 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.format_paint_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    colorText,
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SnakeBodyPainter extends CustomPainter {
  final List<SnakeSegment> segments;

  SnakeBodyPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    if (segments.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(segments[0].position.dx * W, segments[0].position.dy * H);

    for (int i = 1; i < segments.length; i++) {
      path.lineTo(segments[i].position.dx * W, segments[i].position.dy * H);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SnakeBodyPainter oldDelegate) {
    return oldDelegate.segments.length != segments.length;
  }
}
