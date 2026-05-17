import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'dart:math' as math;

class StarColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const StarColoringScreen({super.key, this.levelId = 10});

  @override
  ConsumerState<StarColoringScreen> createState() => _StarColoringScreenState();
}

class _StarColoringScreenState extends ConsumerState<StarColoringScreen> {

  // Target colors: Center is yellow, tips are mixed red and blue
  final Map<int, Color> targetColors = {
    0: Colors.yellow, // Center
    1: Colors.red,    // Tip 1 (Top)
    2: Colors.blue,   // Tip 2
    3: Colors.red,    // Tip 3
    4: Colors.blue,   // Tip 4
    5: Colors.red,    // Tip 5
  };

  // User's current colors
  late Map<int, Color> userColors;
  
  Color selectedColor = Colors.yellow;
  bool isComplete = false;

  final List<Color> palette = [
    Colors.yellow,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    // Initialize user colors with white (uncolored)
    userColors = {
      0: Colors.white,
      1: Colors.white,
      2: Colors.white,
      3: Colors.white,
      4: Colors.white,
      5: Colors.white,
    };
  }

  void _onPartTap(int index) {
    if (isComplete) return;
    
    setState(() {
      userColors[index] = selectedColor;
    });
    HapticService.light();
    _checkCompletion();
  }

  void _checkCompletion() {
    bool allMatched = true;
    for (int i = 0; i < 6; i++) {
      if (userColors[i] != targetColors[i]) {
        allMatched = false;
        break;
      }
    }

    if (allMatched) {
      setState(() => isComplete = true);
      HapticService.success();
      
      ref.read(progressProvider.notifier).updateHighestLevel(11);
      
      CelebrationUtils.showCelebrationAndLevelUp(
        context: context,
        nextLevelId: 11,
        title: 'HEBAT!',
        message: 'Bintangnya sangat indah!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F7FF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Mewarnai Bintang', 
            style: GoogleFonts.fredoka(color: CilikTheme.tealTua, fontWeight: FontWeight.bold, fontSize: 24)
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Reference Section
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Text('Ikuti Warna Ini!', 
                        style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: StarPartPainter(colors: targetColors),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Canvas Section
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onTapUp: (details) {
                                int? tappedPart = _getTappedPart(details.localPosition, constraints.biggest);
                                if (tappedPart != null) {
                                  _onPartTap(tappedPart);
                                }
                              },
                              child: CustomPaint(
                                size: constraints.biggest,
                                painter: StarPartPainter(
                                  colors: userColors,
                                  showOutline: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                _buildPalette(),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int? _getTappedPart(Offset localPosition, Size size) {
    final painter = StarPartPainter(colors: userColors);
    return painter.getPartAtPoint(localPosition, size);
  }

  Widget _buildPalette() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: palette.map((color) {
              bool isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() => selectedColor = color);
                  HapticService.light();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 65 : 55,
                  height: isSelected ? 65 : 55,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? CilikTheme.tealTua : Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 30) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class StarPartPainter extends CustomPainter {
  final Map<int, Color> colors;
  final bool showOutline;

  StarPartPainter({required this.colors, this.showOutline = false});

  List<Path> _getPaths(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width * 0.45;
    final r = R * 0.45;

    List<Offset> points = [];
    for (int i = 0; i < 10; i++) {
      double radius = i.isEven ? R : r;
      double angle = (i * 36 - 90) * math.pi / 180;
      points.add(Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ));
    }

    // Index 0: Center Pentagon
    final centerPath = Path()
      ..moveTo(points[1].dx, points[1].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..lineTo(points[5].dx, points[5].dy)
      ..lineTo(points[7].dx, points[7].dy)
      ..lineTo(points[9].dx, points[9].dy)
      ..close();

    // Tips
    final tip1 = Path()..moveTo(points[0].dx, points[0].dy)..lineTo(points[1].dx, points[1].dy)..lineTo(points[9].dx, points[9].dy)..close();
    final tip2 = Path()..moveTo(points[2].dx, points[2].dy)..lineTo(points[3].dx, points[3].dy)..lineTo(points[1].dx, points[1].dy)..close();
    final tip3 = Path()..moveTo(points[4].dx, points[4].dy)..lineTo(points[5].dx, points[5].dy)..lineTo(points[3].dx, points[3].dy)..close();
    final tip4 = Path()..moveTo(points[6].dx, points[6].dy)..lineTo(points[7].dx, points[7].dy)..lineTo(points[5].dx, points[5].dy)..close();
    final tip5 = Path()..moveTo(points[8].dx, points[8].dy)..lineTo(points[9].dx, points[9].dy)..lineTo(points[7].dx, points[7].dy)..close();

    return [centerPath, tip1, tip2, tip3, tip4, tip5];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paths = _getPaths(size);
    
    final paint = Paint()..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < paths.length; i++) {
      paint.color = colors[i] ?? Colors.white;
      canvas.drawPath(paths[i], paint);
      if (showOutline) {
        canvas.drawPath(paths[i], outlinePaint);
      }
    }
  }

  int? getPartAtPoint(Offset point, Size size) {
    final paths = _getPaths(size);
    for (int i = 0; i < paths.length; i++) {
      if (paths[i].contains(point)) {
        return i;
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant StarPartPainter oldDelegate) => true;
}
