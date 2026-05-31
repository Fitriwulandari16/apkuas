import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ScatterDiceModel {
  final int index;
  final int dots;
  final double relativeX;
  final double relativeY;
  final Color correctColor;
  Color? currentColor;
  bool isSolved;

  ScatterDiceModel({
    required this.index,
    required this.dots,
    required this.relativeX,
    required this.relativeY,
    required this.correctColor,
    this.currentColor,
    this.isSolved = false,
  });
}

class ScatterDiceColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ScatterDiceColoringScreen({super.key, this.levelId = 42});

  @override
  ConsumerState<ScatterDiceColoringScreen> createState() => _ScatterDiceColoringScreenState();
}

class _ScatterDiceColoringScreenState extends ConsumerState<ScatterDiceColoringScreen> {
  // 5 colors defined in workbook specifications
  static const Color colOrange = Color(0xFFF97316);    // 1 = Oranye
  static const Color colLightBlue = Color(0xFF38BDF8); // 2 = Biru Muda
  static const Color colYellow = Color(0xFFFACC15);    // 3 = Kuning
  static const Color colGreen = Color(0xFF22C55E);     // 4 = Hijau
  static const Color colBrown = Color(0xFF8B5A2B);     // 5 = Cokelat

  final Map<Color, String> _colorNames = {
    colOrange: 'Oranye',
    colLightBlue: 'Biru Muda',
    colYellow: 'Kuning',
    colGreen: 'Hijau',
    colBrown: 'Cokelat',
  };

  Color? _selectedColor;
  late List<ScatterDiceModel> _diceList;
  int? _shakingDiceIndex;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 15 scattered dice from workbook page 22 layout
    final List<Map<String, dynamic>> scatterLayout = [
      {'dots': 5, 'rx': 0.10, 'ry': 0.04},
      {'dots': 4, 'rx': 0.40, 'ry': 0.08},
      {'dots': 3, 'rx': 0.63, 'ry': 0.02},
      {'dots': 2, 'rx': 0.86, 'ry': 0.08},
      {'dots': 2, 'rx': 0.08, 'ry': 0.28},
      {'dots': 1, 'rx': 0.32, 'ry': 0.22},
      {'dots': 5, 'rx': 0.67, 'ry': 0.24},
      {'dots': 5, 'rx': 0.20, 'ry': 0.42},
      {'dots': 4, 'rx': 0.49, 'ry': 0.36},
      {'dots': 1, 'rx': 0.87, 'ry': 0.35},
      {'dots': 3, 'rx': 0.69, 'ry': 0.50},
      {'dots': 1, 'rx': 0.08, 'ry': 0.62},
      {'dots': 3, 'rx': 0.30, 'ry': 0.58},
      {'dots': 5, 'rx': 0.52, 'ry': 0.66},
      {'dots': 2, 'rx': 0.88, 'ry': 0.61},
    ];

    _diceList = List.generate(scatterLayout.length, (i) {
      final item = scatterLayout[i];
      final int dots = item['dots'] as int;

      Color correct;
      switch (dots) {
        case 1:
          correct = colOrange;
          break;
        case 2:
          correct = colLightBlue;
          break;
        case 3:
          correct = colYellow;
          break;
        case 4:
          correct = colGreen;
          break;
        case 5:
        default:
          correct = colBrown;
          break;
      }

      return ScatterDiceModel(
        index: i,
        dots: dots,
        relativeX: item['rx'] as double,
        relativeY: item['ry'] as double,
        correctColor: correct,
      );
    });
  }

  void _handleDiceTap(int index) {
    final die = _diceList[index];
    if (die.isSolved) return;

    if (_selectedColor == null) {
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih warna di palet terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigoAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_selectedColor == die.correctColor) {
      // Correct color matches dot counts!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        die.currentColor = _selectedColor;
        die.isSolved = true;
      });

      // Check level completion
      if (_diceList.every((d) => d.isSolved)) {
        _onLevelComplete();
      }
    } else {
      // Wrong coloring choice
      _shakeDice(index);
    }
  }

  void _shakeDice(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingDiceIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _shakingDiceIndex = null;
      });
    }
  }

  void _onLevelComplete() async {
    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(42);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 42: $e');
    }

    if (!mounted) return;

    // 3. Show success victory dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'DiceSuccess',
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scaleValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: scaleValue,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.amber, width: 6),
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
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 110,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HORE! HEBAT!',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kamu hebat dalam menghitung titik dadu dan mencocokkan warnanya!',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
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
                        // Return back to Adventure Map
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close level 42 screen
                      },
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
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

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [colOrange, colLightBlue, colYellow, colGreen, colBrown];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            _buildLegendHeader(),
            const SizedBox(height: 4),
            // Play Area (Scatter Board Stack)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double boardW = constraints.maxWidth;
                        final double boardH = constraints.maxHeight;

                        // Responsive size for dice depending on constraints
                        final double diceSize = min(boardW * 0.16, boardH * 0.11);

                        return Stack(
                          children: _diceList.map((die) {
                            // Calculate absolute responsive coordinates
                            final double absoluteX = die.relativeX * (boardW - diceSize);
                            final double absoluteY = die.relativeY * (boardH - diceSize);

                            final isShaking = _shakingDiceIndex == die.index;
                            final double shakeX = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

                            return Positioned(
                              left: absoluteX + shakeX,
                              top: absoluteY,
                              width: diceSize,
                              height: diceSize,
                              child: GestureDetector(
                                onTap: () => _handleDiceTap(die.index),
                                child: Container(
                                  color: Colors.transparent, // Expand touch target
                                  child: CustomPaint(
                                    painter: DiceFacePainter(
                                      dots: die.dots,
                                      color: die.currentColor ?? Colors.white,
                                      isSolved: die.isSolved,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPalette(colors),
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
              'Level 42',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_hdr_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Pilih warna, lalu ketuk dadu yang jumlah titiknya sesuai!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
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

  Widget _buildLegendHeader() {
    final List<Map<String, dynamic>> legends = [
      {'dots': 1, 'color': colOrange},
      {'dots': 2, 'color': colLightBlue},
      {'dots': 3, 'color': colYellow},
      {'dots': 4, 'color': colGreen},
      {'dots': 5, 'color': colBrown},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: legends.map((legend) {
          final int dots = legend['dots'] as int;
          final Color color = legend['color'] as Color;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: Row(
              children: [
                Text(
                  '$dots',
                  style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star_rounded, color: color, size: 14),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPalette(List<Color> colors) {
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
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.map((color) {
          final isSelected = _selectedColor == color;
          final String colorName = _colorNames[color]!;

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
                    width: 50,
                    height: 50,
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
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.format_paint_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    colorName,
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DiceFacePainter extends CustomPainter {
  final int dots;
  final Color color;
  final bool isSolved;

  DiceFacePainter({
    required this.dots,
    required this.color,
    required this.isSolved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = min(w, h);

    // 1. Draw rounded die body
    final diePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, w - 4, h - 4),
      Radius.circular(r * 0.22),
    );

    canvas.drawRRect(rrect, diePaint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw subtle 3D inner drop shadow
    if (color == Colors.white) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.04)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 4, w - 8, h - 8),
          Radius.circular(r * 0.22),
        ),
        shadowPaint,
      );
    } else {
      // Highlight glow overlay for premium feel
      final glossPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromLTWH(6, 6, w * 0.5, h * 0.22),
        glossPaint,
      );
    }

    // 2. Draw dots (pips) inside die
    final pipPaint = Paint()
      ..color = isSolved ? Colors.white : const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    final double pipRadius = r * 0.09;
    final double cx = w / 2;
    final double cy = h / 2;

    // Relative offset percentage positions
    final double leftX = w * 0.26;
    final double rightX = w * 0.74;
    final double topY = h * 0.26;
    final double bottomY = h * 0.74;

    switch (dots) {
      case 1:
        // Center
        canvas.drawCircle(Offset(cx, cy), pipRadius, pipPaint);
        break;
      case 2:
        // Top-Left, Bottom-Right
        canvas.drawCircle(Offset(leftX, topY), pipRadius, pipPaint);
        canvas.drawCircle(Offset(rightX, bottomY), pipRadius, pipPaint);
        break;
      case 3:
        // Top-Left, Center, Bottom-Right
        canvas.drawCircle(Offset(leftX, topY), pipRadius, pipPaint);
        canvas.drawCircle(Offset(cx, cy), pipRadius, pipPaint);
        canvas.drawCircle(Offset(rightX, bottomY), pipRadius, pipPaint);
        break;
      case 4:
        // 4 Corners
        canvas.drawCircle(Offset(leftX, topY), pipRadius, pipPaint);
        canvas.drawCircle(Offset(rightX, topY), pipRadius, pipPaint);
        canvas.drawCircle(Offset(leftX, bottomY), pipRadius, pipPaint);
        canvas.drawCircle(Offset(rightX, bottomY), pipRadius, pipPaint);
        break;
      case 5:
      default:
        // 4 Corners + Center
        canvas.drawCircle(Offset(leftX, topY), pipRadius, pipPaint);
        canvas.drawCircle(Offset(rightX, topY), pipRadius, pipPaint);
        canvas.drawCircle(Offset(cx, cy), pipRadius, pipPaint);
        canvas.drawCircle(Offset(leftX, bottomY), pipRadius, pipPaint);
        canvas.drawCircle(Offset(rightX, bottomY), pipRadius, pipPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DiceFacePainter oldDelegate) {
    return oldDelegate.dots != dots || oldDelegate.color != color || oldDelegate.isSolved != isSolved;
  }
}
