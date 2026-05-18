import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class CompositionMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const CompositionMatchingScreen({super.key, this.levelId = 13});

  @override
  ConsumerState<CompositionMatchingScreen> createState() => _CompositionMatchingScreenState();
}

class _CompositionMatchingScreenState extends ConsumerState<CompositionMatchingScreen> {
  final List<_CompositionData> items = [
    _CompositionData(
      id: 0,
      outerShape: _ShapeType.square,
      outerColor: Colors.blue,
      innerShape: _ShapeType.circle,
      innerColor: Colors.red,
    ),
    _CompositionData(
      id: 1,
      outerShape: _ShapeType.circle,
      outerColor: Colors.green,
      innerShape: _ShapeType.hexagon,
      innerColor: Colors.yellow.shade700,
    ),
    _CompositionData(
      id: 2,
      outerShape: _ShapeType.square,
      outerColor: Colors.purple,
      innerShape: _ShapeType.circle,
      innerColor: Colors.lightGreen,
    ),
    _CompositionData(
      id: 3,
      outerShape: _ShapeType.hexagon,
      outerColor: Colors.yellow.shade700,
      innerShape: _ShapeType.hexagon,
      innerColor: Colors.pink,
    ),
  ];

  late List<_CompositionData> leftItems;
  late List<_CompositionData> rightItems;
  late List<GlobalKey> leftKeys;
  late List<GlobalKey> rightKeys;
  final GlobalKey _areaKey = GlobalKey();
  
  Map<int, bool> matched = {};
  List<_Connection> connections = [];
  
  Offset? currentDragStart;
  Offset? currentDragEnd;
  int? activeDragId;


  @override
  void initState() {
    super.initState();
    _resetLevel();
  }

  void _resetLevel() {
    leftItems = List.from(items);
    rightItems = List.from(items)..shuffle();
    leftKeys = List.generate(items.length, (_) => GlobalKey());
    rightKeys = List.generate(items.length, (_) => GlobalKey());
    matched = {for (var item in items) item.id: false};
    connections = [];
  }

  void _onLevelComplete() {
    HapticService.success();
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 14,
      title: 'Luar Biasa!',
      message: 'Kamu Ahli Komposisi!',
    );
  }

  Offset _getCenter(GlobalKey key) {
    if (key.currentContext == null) return Offset.zero;
    final RenderBox? box = key.currentContext!.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final position = box.localToGlobal(Offset.zero);
    return Offset(position.dx + box.size.width / 2, position.dy + box.size.height / 2);
  }

  void _handleDragStart(Offset globalPos, Size areaSize) {
    for (int i = 0; i < leftItems.length; i++) {
      final item = leftItems[i];
      if (matched[item.id]!) continue;
      
      if (leftKeys[i].currentContext != null) {
        final nodePos = _getCenter(leftKeys[i]);
        if ((globalPos - nodePos).distance < 40) {
          setState(() {
            activeDragId = item.id;
            currentDragStart = nodePos;
            currentDragEnd = globalPos;
          });
          HapticService.light();
          return;
        }
      }
    }
  }

  void _handleDragUpdate(Offset globalPos) {
    if (activeDragId == null) return;
    setState(() => currentDragEnd = globalPos);
  }

  void _handleDragEnd(Offset globalPos, Size areaSize) {
    if (activeDragId == null) return;

    int? hitIndex;
    Offset? targetCenter;
    for (int i = 0; i < rightItems.length; i++) {
      if (rightKeys[i].currentContext != null) {
        final nodePos = _getCenter(rightKeys[i]);
        if ((globalPos - nodePos).distance < 30) { // Snap mechanics pada radius 30
          if (rightItems[i].id == activeDragId) {
            hitIndex = i;
            targetCenter = nodePos;
          }
          break;
        }
      }
    }

    if (hitIndex != null && targetCenter != null) {
      final item = leftItems.firstWhere((e) => e.id == activeDragId);
      setState(() {
        matched[activeDragId!] = true;
        connections.add(_Connection(
          color: item.outerColor, // Warna dinamis dari objek asal
          start: currentDragStart!,
          end: targetCenter!,
        ));
      });
      HapticService.success();
      if (matched.values.every((v) => v)) _onLevelComplete();
    } else {
      HapticService.failure();
    }

    setState(() {
      activeDragId = null;
      currentDragStart = null;
      currentDragEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Light blue background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final areaSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onPanStart: (d) => _handleDragStart(d.globalPosition, areaSize),
                    onPanUpdate: (d) => _handleDragUpdate(d.globalPosition),
                    onPanEnd: (d) => _handleDragEnd(d.globalPosition, areaSize),
                    child: Stack(
                      key: _areaKey,
                      children: [
                        Container(color: Colors.transparent),

                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LinePainter(
                              connections: connections,
                              activeStart: currentDragStart,
                              activeEnd: currentDragEnd,
                              activeColor: activeDragId != null ? leftItems.firstWhere((e) => e.id == activeDragId).outerColor : null,
                              context: context,
                            ),
                          ),
                        ),

                        ...List.generate(leftItems.length, (i) {
                          // Rough position for Container, precise position taken via GlobalKey
                          double segmentHeight = areaSize.height / items.length;
                          double y = (i + 0.5) * segmentHeight;
                          return Positioned(
                            left: 40,
                            top: y - 40,
                            child: _buildCompositeItem(leftItems[i], true, leftKeys[i]),
                          );
                        }),

                        // Right Column (Separated Components)
                        ...List.generate(rightItems.length, (i) {
                          double segmentHeight = areaSize.height / items.length;
                          double y = (i + 0.5) * segmentHeight;
                          return Positioned(
                            right: 40,
                            top: y - 40,
                            child: _buildCompositionItem(rightItems[i], false, rightKeys[i]),
                          );
                        }),

                      ],
                    ),
                  );
                },
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
              'Level 13',
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Text(
        'Hubungkan gambar dengan komposisi penyusunnya!',
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildCompositeItem(_CompositionData data, bool isLeft, GlobalKey key) {
    bool isItemMatched = matched[data.id]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            border: Border.all(
              color: isItemMatched ? Colors.green : Colors.transparent,
              width: 3,
            ),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ShapeWidget(type: data.outerShape, color: data.outerColor, size: 60),
                _ShapeWidget(type: data.innerShape, color: data.innerColor, size: 25),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildNode(isItemMatched, key),
      ],
    );
  }

  Widget _buildCompositionItem(_CompositionData data, bool isLeft, GlobalKey key) {

    bool isItemMatched = connections.any((c) => rightItems.indexWhere((ri) => ri.id == data.id) != -1 && c.end.dx > 200); // Simple logic to check if this right item is matched
    // Better logic:
    bool isRightMatched = matched[data.id]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNode(isRightMatched, key),
        const SizedBox(width: 10),
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            border: Border.all(
              color: isRightMatched ? Colors.green : Colors.transparent,
              width: 3,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShapeWidget(type: data.innerShape, color: data.innerColor, size: 30),
              _ShapeWidget(type: data.outerShape, color: data.outerColor, size: 35),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNode(bool isMatched, Key key) {
    return Container(
      key: key,
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: isMatched ? Colors.green : Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
      ),
    );
  }
}

enum _ShapeType { circle, square, hexagon }

class _CompositionData {
  final int id;
  final _ShapeType outerShape;
  final Color outerColor;
  final _ShapeType innerShape;
  final Color innerColor;

  _CompositionData({
    required this.id,
    required this.outerShape,
    required this.outerColor,
    required this.innerShape,
    required this.innerColor,
  });
}

class _ShapeWidget extends StatelessWidget {
  final _ShapeType type;
  final Color color;
  final double size;

  const _ShapeWidget({required this.type, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShapePainter(type: type, color: color),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final _ShapeType type;
  final Color color;

  _ShapePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    switch (type) {
      case _ShapeType.circle:
        canvas.drawCircle(center, size.width / 2, paint);
        break;
      case _ShapeType.square:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case _ShapeType.hexagon:
        final path = Path();
        for (int i = 0; i < 6; i++) {
          double angle = (i * 60 - 30) * math.pi / 180;
          double x = center.dx + (size.width / 2) * math.cos(angle);
          double y = center.dy + (size.height / 2) * math.sin(angle);
          if (i == 0) path.moveTo(x, y);
          else path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Connection {
  final Color color;
  final Offset start;
  final Offset end;
  _Connection({required this.color, required this.start, required this.end});
}

class _LinePainter extends CustomPainter {
  final List<_Connection> connections;
  final Offset? activeStart;
  final Offset? activeEnd;
  final Color? activeColor;
  final BuildContext context;

  _LinePainter({required this.connections, this.activeStart, this.activeEnd, this.activeColor, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    // Mapping koordinat global ke posisi CustomPaint
    final canvasOffset = renderObject.localToGlobal(Offset.zero);

    // Draw permanent connections
    for (var conn in connections) {
      // Indikator Glow Hijau di bawah garis untuk efek visual sukses
      paint.color = Colors.green.withOpacity(0.4);
      paint.strokeWidth = 11.0;
      canvas.drawLine(conn.start - canvasOffset, conn.end - canvasOffset, paint);
      
      // Warna asli dari objek asal
      paint.color = conn.color; 
      paint.strokeWidth = 7.0;
      canvas.drawLine(conn.start - canvasOffset, conn.end - canvasOffset, paint);
    }

    // Draw active drag line
    if (activeStart != null && activeEnd != null && activeColor != null) {
      paint.color = activeColor!; // Warna asli dari objek asal
      paint.strokeWidth = 7.0;
      canvas.drawLine(activeStart! - canvasOffset, activeEnd! - canvasOffset, paint);
    }
  }

  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

