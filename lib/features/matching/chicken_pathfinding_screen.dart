import 'dart:async';
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
import 'package:apkuas/core/widgets/responsive_wrapper.dart';

class ChickenPathfindingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ChickenPathfindingScreen({super.key, this.levelId = 45});

  @override
  ConsumerState<ChickenPathfindingScreen> createState() => _ChickenPathfindingScreenState();
}

class _ChickenPathfindingScreenState extends ConsumerState<ChickenPathfindingScreen> {
  late List<Map<String, dynamic>> level45Dots;
  final bool _showingHint = false; // Kept for testing compatibility

  // Vibration Guard (Debounce/Throttle)
  Timer? _vibrationTimer;
  bool _canVibrate = true;

  void _triggerGagalGetar() {
    if (!_canVibrate) return;
    _canVibrate = false;
    HapticFeedback.lightImpact();
    _vibrationTimer?.cancel();
    _vibrationTimer = Timer(const Duration(milliseconds: 500), () {
      _canVibrate = true;
    });
  }

  // Optimized static const lists for memory efficiency
  static const List<Map<String, Object>> _legendRules = [
    {'color': Colors.blue, 'mark': 'x'},
    {'color': Colors.pink, 'mark': 'plus'},
    {'color': Colors.green, 'mark': 'triangle'},
    {'color': Colors.yellow, 'mark': 'circle'},
    {'color': Colors.purple, 'mark': 'square'},
  ];

  static const List<String> _partsBinShapes = ['x', 'plus', 'triangle', 'circle', 'square'];

  @visibleForTesting
  List<Map<String, dynamic>> get dots => level45Dots;

  @visibleForTesting
  bool get showingHint => _showingHint;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    level45Dots = [
      {'color': Colors.blue, 'mark': ''},
      {'color': Colors.pink, 'mark': ''},
      {'color': Colors.green, 'mark': ''},
      {'color': Colors.yellow, 'mark': ''},
      {'color': Colors.purple, 'mark': ''},
      {'color': Colors.blue, 'mark': ''},
      {'color': Colors.green, 'mark': ''},
      {'color': Colors.yellow, 'mark': ''},
      {'color': Colors.pink, 'mark': ''},
      {'color': Colors.purple, 'mark': ''},
      {'color': Colors.blue, 'mark': ''},
      {'color': Colors.green, 'mark': ''},
    ];
  }

  void gameWin() {
    _onLevelComplete();
  }

  void _onLevelComplete() async {
    HapticService.success();
    SoundService.playSuccess();

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
      message: 'Kamu berhasil mengenali pola dan memasangkan semua bentuk dengan benar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      backgroundColor: const Color(0xFFE2F0D9), // Light pasture green background
      child: Scaffold(
        backgroundColor: const Color(0xFFE2F0D9),
        body: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Menampilkan 3 lingkaran per baris
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: level45Dots.length,
                  itemBuilder: (context, index) {
                    var dot = level45Dots[index];
                    final displayMark = dot['mark'] as String;

                    return DragTarget<String>(
                      onWillAccept: (data) => data != null,
                      onAccept: (shape) {
                        bool correct = false;
                        if (dot['color'] == Colors.blue && shape == 'x') {
                          correct = true;
                        } else if (dot['color'] == Colors.pink && shape == 'plus') {
                          correct = true;
                        } else if (dot['color'] == Colors.green && shape == 'triangle') {
                          correct = true;
                        } else if (dot['color'] == Colors.yellow && shape == 'circle') {
                          correct = true;
                        } else if (dot['color'] == Colors.purple && shape == 'square') {
                          correct = true;
                        }

                        if (correct) {
                          SoundService.playSuccess();
                          HapticService.success();
                          setState(() {
                            dot['mark'] = shape;
                            // Pengecekan menang
                            if (level45Dots.every((d) => d['mark'] != '')) {
                              gameWin();
                            }
                          });
                        } else {
                          SoundService.playError();
                          _triggerGagalGetar(); // Throttled haptic vibration
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Center(
                          child: CircleWidget(
                            color: dot['color'] as Color, 
                            mark: displayMark,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPartsBin(),
            const SizedBox(height: 24),
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
              'Level 45',
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
          const Icon(Icons.extension_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Seret bentuk ke gelembung yang sesuai dengan petunjuk contoh!',
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

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _legendRules.map((rule) {
          return SizedBox(
            width: 50,
            height: 50,
            child: CustomPaint(
              painter: LegendBubblePainter(
                bubbleColor: rule['color'] as Color,
                mark: rule['mark'] as String,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPartsBin() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SERET BENTUK KE GELEMBUNG YANG COCOK',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _partsBinShapes.map((shape) {
              return Draggable<String>(
                data: shape,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.85,
                    child: PartsBinItem(shape: shape),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.35,
                  child: PartsBinItem(shape: shape),
                ),
                child: PartsBinItem(shape: shape),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class PartsBinItem extends StatelessWidget {
  final String shape;

  const PartsBinItem({super.key, required this.shape});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CustomPaint(
        painter: PartsBinItemPainter(shape: shape),
      ),
    );
  }
}

class PartsBinItemPainter extends CustomPainter {
  final String shape;

  PartsBinItemPainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = min(w, h) * 0.28;

    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (shape) {
      case 'x':
        canvas.drawLine(Offset(cx - r * 0.7, cy - r * 0.7), Offset(cx + r * 0.7, cy + r * 0.7), paint);
        canvas.drawLine(Offset(cx + r * 0.7, cy - r * 0.7), Offset(cx - r * 0.7, cy + r * 0.7), paint);
        break;
      case 'plus':
        canvas.drawLine(Offset(cx - r * 0.8, cy), Offset(cx + r * 0.8, cy), paint);
        canvas.drawLine(Offset(cx, cy - r * 0.8), Offset(cx, cy + r * 0.8), paint);
        break;
      case 'triangle':
        final path = Path()
          ..moveTo(cx, cy - r * 0.95)
          ..lineTo(cx - r * 0.9, cy + r * 0.6)
          ..lineTo(cx + r * 0.9, cy + r * 0.6)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), r * 0.85, paint);
        break;
      case 'square':
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.6, height: r * 1.6), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant PartsBinItemPainter oldDelegate) => oldDelegate.shape != shape;
}

class CircleWidget extends StatelessWidget {
  final Color color;
  final String mark;

  const CircleWidget({super.key, required this.color, required this.mark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 55,
      height: 55,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bubble background fill
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 5,
                  offset: const Offset(0, 2.5),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
          // Gloss effect
          Positioned(
            top: 4,
            left: 8,
            child: Container(
              width: 15,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: const BorderRadius.all(Radius.elliptical(15, 8)),
              ),
            ),
          ),
          // Markings CustomPaint (without clipping, so it can draw outside bounds)
          Positioned.fill(
            child: CustomPaint(
              painter: MarkPainter(mark: mark),
            ),
          ),
        ],
      ),
    );
  }
}

class MarkPainter extends CustomPainter {
  final String mark;

  MarkPainter({required this.mark});

  @override
  void paint(Canvas canvas, Size size) {
    if (mark == '') return;

    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (mark) {
      case 'x':
        canvas.drawLine(
          Offset(cx - r * 0.5, cy - r * 0.5),
          Offset(cx + r * 0.5, cy + r * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(cx + r * 0.5, cy - r * 0.5),
          Offset(cx - r * 0.5, cy + r * 0.5),
          paint,
        );
        break;
      case 'plus':
        canvas.drawLine(
          Offset(cx - r * 0.6, cy),
          Offset(cx + r * 0.6, cy),
          paint,
        );
        canvas.drawLine(
          Offset(cx, cy - r * 0.6),
          Offset(cx, cy + r * 0.6),
          paint,
        );
        break;
      case 'triangle':
        final path = Path()
          ..moveTo(cx, cy - r * 1.35)
          ..lineTo(cx - r * 1.3, cy + r * 1.05)
          ..lineTo(cx + r * 1.3, cy + r * 1.05)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), r * 1.25, paint);
        break;
      case 'square':
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2.4, height: r * 2.4),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant MarkPainter oldDelegate) => oldDelegate.mark != mark;
}

class LegendBubblePainter extends CustomPainter {
  final Color bubbleColor;
  final String mark;

  LegendBubblePainter({required this.bubbleColor, required this.mark});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = min(w, h) * 0.28;

    // Draw bubble
    final fillPaint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, fillPaint);

    // Subtle gloss
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(cx - r * 0.5, cy - r * 0.7, r * 0.7, r * 0.35),
      glossPaint,
    );

    // Draw border/mark
    final markPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (mark) {
      case 'x':
        canvas.drawLine(
          Offset(cx - r * 0.5, cy - r * 0.5),
          Offset(cx + r * 0.5, cy + r * 0.5),
          markPaint,
        );
        canvas.drawLine(
          Offset(cx + r * 0.5, cy - r * 0.5),
          Offset(cx - r * 0.5, cy + r * 0.5),
          markPaint,
        );
        break;
      case 'plus':
        canvas.drawLine(
          Offset(cx - r * 0.6, cy),
          Offset(cx + r * 0.6, cy),
          markPaint,
        );
        canvas.drawLine(
          Offset(cx, cy - r * 0.6),
          Offset(cx, cy + r * 0.6),
          markPaint,
        );
        break;
      case 'triangle':
        final path = Path()
          ..moveTo(cx, cy - r * 1.35)
          ..lineTo(cx - r * 1.3, cy + r * 1.05)
          ..lineTo(cx + r * 1.3, cy + r * 1.05)
          ..close();
        canvas.drawPath(path, markPaint);
        break;
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), r * 1.25, markPaint);
        break;
      case 'square':
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: r * 2.4, height: r * 2.4), markPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
