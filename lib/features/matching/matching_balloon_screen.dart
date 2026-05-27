import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/services/sound_service.dart';

class MatchingBalloonScreen extends ConsumerStatefulWidget {
  final int levelId;
  const MatchingBalloonScreen({super.key, this.levelId = 3});

  @override
  ConsumerState<MatchingBalloonScreen> createState() => _MatchingBalloonScreenState();
}

class _MatchingBalloonScreenState extends ConsumerState<MatchingBalloonScreen> with TickerProviderStateMixin {
  late List<Color> startGroup;
  late List<Color> endGroup;
  Map<Color, bool> matchedColors = {};
  
  Offset? currentDragStart;
  Offset? currentDragEnd;
  Color? activeDragColor;
  List<_Connection> connections = [];

  final Map<Color, GlobalKey> startKeys = {};
  final Map<Color, GlobalKey> endKeys = {};



  @override
  void initState() { 
    super.initState(); 
    _resetGame(); 
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _resetGame() {
    // Ensuring standard colors including Red
    List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    startKeys.clear(); 
    endKeys.clear();
    for (var color in colors) { 
      startKeys[color] = GlobalKey(); 
      endKeys[color] = GlobalKey(); 
    }
    setState(() {
      startGroup = List.from(colors); 
      endGroup = List.from(colors)..shuffle();
      matchedColors = {for (var color in colors) color: false};
      connections = []; 
      currentDragStart = null; 
      currentDragEnd = null; 
      activeDragColor = null; 
    });
  }

  void _playSound(String name) async {
    SoundService.playSuccess();
  }

  void _onLevelComplete() {
    HapticService.success();
    _playSound('level_win');
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 4,
      title: 'HEBAT! 🎈',
      message: 'Level 3 Selesai! Kamu sangat pintar mencocokkan warna!',
    );
  }

  Offset _getCenter(GlobalKey key) {
    if (key.currentContext == null) return Offset.zero;
    final RenderBox? box = key.currentContext!.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final position = box.localToGlobal(Offset.zero);
    return Offset(position.dx + box.size.width / 2, position.dy + box.size.height / 2);
  }

  void _handleDragStart(Color color, Offset globalPos) {
    if (matchedColors[color]!) return;
    
    // Menggunakan fungsi _getCenter yang presisi
    if (startKeys[color]?.currentContext != null) {
      final position = _getCenter(startKeys[color]!);
      setState(() { 
        activeDragColor = color; 
        currentDragStart = position; 
        currentDragEnd = position; 
      });
    }
    HapticService.light();
  }

  void _handleDragUpdate(Offset globalPos) { 
    if (activeDragColor == null) return; 
    setState(() => currentDragEnd = globalPos); 
  }

  void _handleDragEnd(Offset globalPos) {
    if (activeDragColor == null || !mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      Color? hitColor;
      Offset? hitCenter;

      for (var entry in endKeys.entries) {
        final RenderBox? renderBox = entry.value.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          // Area hit sedikit lebih luas
          if (Rect.fromLTWH(position.dx - 10, position.dy - 10, size.width + 20, size.height + 20).contains(globalPos)) {
            hitColor = entry.key;
            hitCenter = _getCenter(entry.value);
            break;
          }
        }
      }

      if (hitColor != null && hitColor == activeDragColor) {
        _playSound('success');
        setState(() {
          matchedColors[activeDragColor!] = true;
          connections.add(_Connection(
            color: activeDragColor!,
            start: currentDragStart!,
            end: hitCenter!,
            isCorrect: true,
          ));
        });
        HapticService.success();
        if (matchedColors.values.every((v) => v == true)) _onLevelComplete();
      } else {
        // Wrong match or missed - add a temporary connection that fades out
        _playSound('error');
      }

      setState(() {
        activeDragColor = null;
        currentDragStart = null;
        currentDragEnd = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Cocokkan Balon', 
            style: GoogleFonts.fredoka(color: CilikTheme.tealTua, fontWeight: FontWeight.bold, fontSize: 24)
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned(
              top: 10, 
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: Colors.orangeAccent, size: 22),
                      const SizedBox(width: 8),
                      Text('Hubungkan warna yang sama', 
                        style: GoogleFonts.fredoka(color: Colors.blueGrey, fontSize: 16, fontWeight: FontWeight.w600)
                      )
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => CustomPaint(
                  painter: _ConnectionPainter(
                    activeStart: currentDragStart, 
                    activeEnd: currentDragEnd, 
                    activeColor: activeDragColor, 
                    connections: connections, 
                    context: context
                  )
                )
              )
            ),
            Column(
              children: [
                const SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                  children: startGroup.map((color) => _buildItem(color, true)).toList()
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                  children: endGroup.map((color) => _buildItem(color, false)).toList()
                ),
                const SizedBox(height: 120),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Color color, bool isStart) {
    final key = isStart ? startKeys[color]! : endKeys[color]!;
    final bool isMatched = matchedColors[color] ?? false;

    return Flexible(
      child: GestureDetector(
        onPanStart: isStart ? (details) => _handleDragStart(color, details.globalPosition) : null,
        onPanUpdate: isStart ? (details) => _handleDragUpdate(details.globalPosition) : null,
        onPanEnd: isStart ? (details) => _handleDragEnd(details.globalPosition) : null,
        child: _AnimatedBalloon(
          balloonKey: key,
          color: color, 
          isMatched: isMatched, 
          isStart: isStart,
        ),
      ),
    );
  }
}

class _AnimatedBalloon extends StatefulWidget {
  final GlobalKey balloonKey;
  final Color color;
  final bool isMatched;
  final bool isStart;

  const _AnimatedBalloon({required this.balloonKey, required this.color, required this.isMatched, required this.isStart});

  @override
  State<_AnimatedBalloon> createState() => _AnimatedBalloonState();
}

class _AnimatedBalloonState extends State<_AnimatedBalloon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.isMatched ? 0 : (widget.isStart ? 1.0 : -1.0) * 5 * _controller.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis abu-abu dihapus sesuai instruksi
              Container(
                key: widget.balloonKey, // Key diletakkan tepat di kontainer balon
                width: 60,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color.lerp(widget.color, Colors.white, 0.4)!, // Opacity diganti agar solid, menutupi garis
                      widget.color,
                    ],
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 15,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Connection { 
  final Color color; 
  final Offset start; 
  final Offset end; 
  final bool isCorrect;
  _Connection({required this.color, required this.start, required this.end, this.isCorrect = false}); 
}

class _ConnectionPainter extends CustomPainter {
  final Offset? activeStart; 
  final Offset? activeEnd; 
  final Color? activeColor; 
  final List<_Connection> connections; 
  final BuildContext context;

  _ConnectionPainter({this.activeStart, this.activeEnd, this.activeColor, required this.connections, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 8.0 // Sesuai instruksi strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    // Kurangi hasil koordinat dengan posisi global dari CustomPaint
    final canvasOffset = renderObject.localToGlobal(Offset.zero);

    // Draw completed connections
    for (var conn in connections) {
      paint.color = conn.color; // Gunakan warna asli dari objek asal
      canvas.drawLine(conn.start - canvasOffset, conn.end - canvasOffset, paint);
    }

    // Draw active drag line
    if (activeStart != null && activeEnd != null && activeColor != null) {
      paint.color = activeColor!; // Gunakan warna solid asal
      canvas.drawLine(activeStart! - canvasOffset, activeEnd! - canvasOffset, paint);
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

