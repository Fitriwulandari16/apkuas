import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/providers/profile_provider.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class BeeHomeScreen extends ConsumerStatefulWidget {
  final int levelId;
  const BeeHomeScreen({super.key, this.levelId = 12});

  @override
  ConsumerState<BeeHomeScreen> createState() => _BeeHomeScreenState();
}

class _BeeHomeScreenState extends ConsumerState<BeeHomeScreen> {
  int beeIndex = 0;
  late List<Color> hexagonColors;
  Color? selectedColor;

  // Pattern: Blue (0), Green (1), Blue (2), Green (3)...
  final List<Color> targetPattern = List.generate(20, (index) => index % 2 == 0 ? Colors.blue : Colors.green);

  late List<Offset> positions;
  final double hexSize = 75.0;

  @override
  void initState() {
    super.initState();
    hexagonColors = List.generate(20, (_) => Colors.white);
    // Initial hint for first hexagon
    hexagonColors[0] = Colors.blue;
    _generateSPath();
  }

  void _generateSPath() {
    positions = [];
    double startX = 60;
    double startY = 110;
    double hSpace = 85;
    double vSpace = 75;

    // Row 1: 3 hexagons to the right
    positions.add(Offset(startX, startY));
    positions.add(Offset(startX + hSpace, startY));
    positions.add(Offset(startX + 2 * hSpace, startY));

    // Row 2: Down on the right side
    positions.add(Offset(startX + 2 * hSpace, startY + vSpace));

    // Row 3: 3 hexagons to the left
    positions.add(Offset(startX + 2 * hSpace, startY + 2 * vSpace));
    positions.add(Offset(startX + hSpace, startY + 2 * vSpace));
    positions.add(Offset(startX, startY + 2 * vSpace));

    // Row 4: Down on the left side
    positions.add(Offset(startX, startY + 3 * vSpace));

    // Row 5: 3 hexagons to the right (to hive)
    positions.add(Offset(startX, startY + 4 * vSpace));
    positions.add(Offset(startX + hSpace, startY + 4 * vSpace));
    positions.add(Offset(startX + 2 * hSpace, startY + 4 * vSpace));
  }

  void _onHexagonTap(int index) {
    if (selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih warna Biru atau Hijau di bawah terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    // Only allow coloring forward
    if (index < beeIndex) return;
    if (hexagonColors[index] == targetPattern[index]) return;

    if (selectedColor == targetPattern[index]) {
      SoundService.playSuccess();
      HapticService.success();
      setState(() {
        hexagonColors[index] = selectedColor!;
      });
      _checkMovement();
    } else {
      HapticFeedback.lightImpact();
      SoundService.playError();
    }
  }

  void _checkMovement() {
    int nextIndex = beeIndex + 1;
    while (nextIndex < positions.length && hexagonColors[nextIndex] == targetPattern[nextIndex]) {
      beeIndex = nextIndex;
      nextIndex = beeIndex + 1;
    }
    setState(() {});

    if (beeIndex == positions.length - 1) {
      gameWin();
    }
  }

  void gameWin() {
    _showLevelUpOverlay();
  }

  void _showLevelUpOverlay() async {
    HapticService.success();
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
      title: 'Hebat! Kamu Pintar!',
      message: 'Tantangan Berikutnya: Level 13',
    );
  }

  void _resetLevel() {
    setState(() {
      beeIndex = 0;
      selectedColor = null;
      hexagonColors = List.generate(20, (_) => Colors.white);
      hexagonColors[0] = Colors.blue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FDFB),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 380,
                    height: 520,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Decorative Clouds
                        Positioned(
                          top: 10,
                          left: -20,
                          child: Opacity(
                            opacity: 0.1,
                            child: Icon(Icons.cloud, size: 100, color: Colors.blue.shade200),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: -20,
                          child: Opacity(
                            opacity: 0.2,
                            child: Icon(Icons.park_rounded, size: 150, color: Colors.green.shade200),
                          ),
                        ),

                        // Hexagon Path
                        ...List.generate(positions.length, (index) {
                          final pos = positions[index];
                          return Positioned(
                            left: pos.dx,
                            top: pos.dy,
                            child: GestureDetector(
                              key: ValueKey('hexagon_tap_$index'),
                              onTap: () => _onHexagonTap(index),
                              child: SizedBox(
                                width: hexSize,
                                height: hexSize,
                                child: CustomPaint(
                                  painter: HexagonPainter(
                                    color: hexagonColors[index],
                                    showDash: hexagonColors[index] == Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Beehive (Pohon & Sarang)
                        Positioned(
                          left: positions.last.dx + 40,
                          top: positions.last.dy - 10,
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: CustomPaint(painter: BeehivePainter()),
                          ),
                        ),

                        // Bee Sprite
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          left: positions[beeIndex].dx + 10,
                          top: positions[beeIndex].dy - 35,
                          child: const SizedBox(
                            width: 55,
                            height: 55,
                            child: Center(
                              child: Text('🐝', style: TextStyle(fontSize: 45)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildPalette(),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _resetLevel,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.orange, size: 22),
                  label: const Text(
                    'Ulangi',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LEVEL 12',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Algoritma Pola',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      color: CilikTheme.tealTua,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: const Icon(Icons.person, color: CilikTheme.tealTua, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Warnai pola Biru ➔ Hijau untuk pulang!',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 14,
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPalette() {
    final colors = [Colors.blue, Colors.green];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: colors.map((color) {
          final isSelected = selectedColor == color;
          final colorText = color == Colors.blue ? 'Biru' : 'Hijau';

          return GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() {
                selectedColor = color;
              });
            },
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      child: const Center(
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
            ),
          );
        }).toList(),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  final bool showDash;

  HexagonPainter({required this.color, required this.showDash});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color == Colors.white ? Colors.grey.shade400 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = color == Colors.white ? 1.0 : 2.5;

    final path = Path();
    double w = size.width;
    double h = size.height;
    double cx = w / 2;
    double cy = h / 2;
    double radius = w / 2;

    for (int i = 0; i < 6; i++) {
      double angle = (i * 60 - 30) * math.pi / 180;
      double x = cx + radius * math.cos(angle);
      double y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    if (showDash) {
      canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = Colors.grey.shade300);
    }
  }

  @override
  bool shouldRepaint(covariant HexagonPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.showDash != showDash;
  }
}

class BeehivePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final treePaint = Paint()
      ..color = Colors.brown.shade400
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafPaint = Paint()..color = Colors.green.shade400;
    final hivePaint = Paint()..color = Colors.amber.shade600;
    final holePaint = Paint()..color = Colors.brown.shade800;

    // Draw Branch
    canvas.drawLine(const Offset(0, 0), const Offset(60, 20), treePaint);
    canvas.drawCircle(const Offset(10, -5), 15, leafPaint);
    canvas.drawCircle(const Offset(40, 5), 20, leafPaint);

    // Draw Hanging Hive
    canvas.drawLine(const Offset(50, 15), const Offset(50, 30), Paint()..color = Colors.brown.shade600..strokeWidth = 2);
    
    // Hive Shape
    Rect hiveRect = const Rect.fromLTWH(30, 30, 40, 50);
    canvas.drawOval(hiveRect, hivePaint);
    canvas.drawOval(const Rect.fromLTWH(32, 40, 36, 40), Paint()..color = Colors.amber.shade700);
    
    // Entrance Hole
    canvas.drawCircle(const Offset(50, 55), 8, holePaint);
    
    // Details
    final detailPaint = Paint()..color = Colors.amber.shade800..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawArc(hiveRect, 0, math.pi, false, detailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
