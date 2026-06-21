import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/services/sound_service.dart';

class SequenceLineMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const SequenceLineMatchingScreen({super.key, this.levelId = 21});

  @override
  ConsumerState<SequenceLineMatchingScreen> createState() => _SequenceLineMatchingScreenState();
}

class HexagonNode {
  final int number; // 1 to 5
  final Color color;
  final Offset position; // Normalized coordinates (0.0 to 1.0)

  HexagonNode({
    required this.number,
    required this.color,
    required this.position,
  });
}

class ChallengeBoxData {
  final int id;
  final List<HexagonNode> nodes;
  List<int> completedConnections; // Stores starting node numbers of completed connections (e.g., [1] means 1->2 is connected)
  bool isCompleted;

  ChallengeBoxData({
    required this.id,
    required this.nodes,
  })  : completedConnections = [],
        isCompleted = false;
}

class _SequenceLineMatchingScreenState extends ConsumerState<SequenceLineMatchingScreen> with TickerProviderStateMixin {
  late List<ChallengeBoxData> _challenges;
  bool _isDrawing = false;

  // Active drag state
  int? _activeChallengeId;
  int? _dragStartNode; // 1 to 4
  Offset? _currentDragPosition;

  // Node Colors:
  static const Color col1 = Color(0xFFE76F51); // 1 - Merah
  static const Color col2 = Color(0xFF2EC4B6); // 2 - Hijau
  static const Color col3 = Color(0xFF3EA5E1); // 3 - Biru
  static const Color col4 = Color(0xFFF15BB5); // 4 - Pink
  static const Color col5 = Color(0xFFFFAA00); // 5 - Kuning

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    _challenges = [
      // Challenge 1: Numbers shown (Tutorial Box)
      ChallengeBoxData(
        id: 0,
        nodes: [
          HexagonNode(number: 1, color: col1, position: const Offset(0.20, 0.18)),
          HexagonNode(number: 2, color: col2, position: const Offset(0.80, 0.28)),
          HexagonNode(number: 3, color: col3, position: const Offset(0.55, 0.50)),
          HexagonNode(number: 4, color: col4, position: const Offset(0.22, 0.72)),
          HexagonNode(number: 5, color: col5, position: const Offset(0.78, 0.82)),
        ],
      ),
      // Challenge 2: Numbers hidden
      ChallengeBoxData(
        id: 1,
        nodes: [
          HexagonNode(number: 1, color: col1, position: const Offset(0.22, 0.18)),
          HexagonNode(number: 2, color: col2, position: const Offset(0.80, 0.38)),
          HexagonNode(number: 3, color: col3, position: const Offset(0.80, 0.82)),
          HexagonNode(number: 4, color: col4, position: const Offset(0.50, 0.50)),
          HexagonNode(number: 5, color: col5, position: const Offset(0.20, 0.80)),
        ],
      ),
      // Challenge 3: Numbers hidden
      ChallengeBoxData(
        id: 2,
        nodes: [
          HexagonNode(number: 1, color: col1, position: const Offset(0.80, 0.82)),
          HexagonNode(number: 2, color: col2, position: const Offset(0.80, 0.35)),
          HexagonNode(number: 3, color: col3, position: const Offset(0.20, 0.82)),
          HexagonNode(number: 4, color: col4, position: const Offset(0.20, 0.18)),
          HexagonNode(number: 5, color: col5, position: const Offset(0.45, 0.50)),
        ],
      ),
      // Challenge 4: Numbers hidden
      ChallengeBoxData(
        id: 3,
        nodes: [
          HexagonNode(number: 1, color: col1, position: const Offset(0.68, 0.18)),
          HexagonNode(number: 2, color: col2, position: const Offset(0.20, 0.45)),
          HexagonNode(number: 3, color: col3, position: const Offset(0.48, 0.82)),
          HexagonNode(number: 4, color: col4, position: const Offset(0.78, 0.58)),
          HexagonNode(number: 5, color: col5, position: const Offset(0.80, 0.82)),
        ],
      ),
    ];
  }

  void _resetLevel() {
    HapticService.light();
    setState(() {
      _initLevel();
      _activeChallengeId = null;
      _dragStartNode = null;
      _currentDragPosition = null;
      _isDrawing = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleDragStart(int challengeId, Offset localPos, Size boxSize) {
    final challenge = _challenges[challengeId];
    if (challenge.isCompleted) return;

    // Determine the next expected connection start node (1 to 4)
    final int nextStartNumber = challenge.completedConnections.length + 1;
    if (nextStartNumber > 4) return;

    // Find the node corresponding to nextStartNumber
    final startNode = challenge.nodes.firstWhere((n) => n.number == nextStartNumber);
    final Offset nodePos = Offset(startNode.position.dx * boxSize.width, startNode.position.dy * boxSize.height);

    // If tap is close to the start node
    if ((localPos - nodePos).distance < 30.0) {
      HapticService.light();
      setState(() {
        _activeChallengeId = challengeId;
        _dragStartNode = nextStartNumber;
        _currentDragPosition = localPos;
        _isDrawing = true;
      });
    }
  }

  void _handleDragUpdate(Offset localPos) {
    if (_activeChallengeId == null) return;
    setState(() {
      _currentDragPosition = localPos;
    });
  }

  void _handleDragEnd(Size boxSize) {
    if (_activeChallengeId == null || _dragStartNode == null) return;

    final challenge = _challenges[_activeChallengeId!];
    final int targetNumber = _dragStartNode! + 1;

    // Find the target node
    final targetNode = challenge.nodes.firstWhere((n) => n.number == targetNumber);
    final Offset nodePos = Offset(targetNode.position.dx * boxSize.width, targetNode.position.dy * boxSize.height);

    // If release is close to the target node
    if (_currentDragPosition != null && (_currentDragPosition! - nodePos).distance < 30.0) {
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        challenge.completedConnections.add(_dragStartNode!);
        if (challenge.completedConnections.length == 4) {
          challenge.isCompleted = true;
        }
      });

      // Check if all challenge boxes are completed
      if (_challenges.every((c) => c.isCompleted)) {
        _onLevelComplete();
      }
    } else {
      HapticService.failure();
    }

    // Reset drag state
    setState(() {
      _activeChallengeId = null;
      _dragStartNode = null;
      _currentDragPosition = null;
      _isDrawing = false;
    });
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 22,
      title: 'Hebat Sekali!',
      message: 'Kamu berhasil menghubungkan semua garis sesuai urutan warna!',
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
            
            // Legend of sequence colors (Hexagons 1-5)
            _buildLegendCard(),

            // 2x2 Grid of 4 Challenge Boxes (Fixed Height Layout)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildChallengeBox(0)),
                          const SizedBox(width: 14),
                          Expanded(child: _buildChallengeBox(1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildChallengeBox(2)),
                          const SizedBox(width: 14),
                          Expanded(child: _buildChallengeBox(3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Symmetrical, Horizontally Centered Reset Button
            TextButton.icon(
              onPressed: _resetLevel,
              icon: const Icon(Icons.refresh_rounded, color: Colors.blueGrey, size: 20),
              label: Text(
                'Ulangi',
                style: GoogleFonts.fredoka(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
              'Level 21',
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
          const Icon(Icons.gesture_rounded, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Buat garis sesuai urutan warna!',
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

  Widget _buildLegendCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendHexagon(1, col1),
          _buildLegendHexagon(2, col2),
          _buildLegendHexagon(3, col3),
          _buildLegendHexagon(4, col4),
          _buildLegendHexagon(5, col5),
        ],
      ),
    );
  }

  Widget _buildLegendHexagon(int number, Color color) {
    return Column(
      children: [
        ClipPath(
          clipper: HexagonClipper(),
          child: Container(
            width: 44,
            height: 44,
            color: color,
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeBox(int challengeId) {
    final challenge = _challenges[challengeId];

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Listener(
          key: ValueKey('challenge_box_$challengeId'),
          onPointerDown: (PointerDownEvent event) {
            setState(() {
              _isDrawing = true;
            });
            void route(PointerEvent e) {
              if (e is PointerUpEvent || e is PointerCancelEvent) {
                GestureBinding.instance.pointerRouter.removeGlobalRoute(route);
                setState(() {
                  _isDrawing = false;
                });
              }
            }
            GestureBinding.instance.pointerRouter.addGlobalRoute(route);
          },
          child: RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerPanGestureRecognizer>(
                () => EagerPanGestureRecognizer(debugOwner: 'eagerPan'),
                (EagerPanGestureRecognizer instance) {
                  instance.onStart = (details) => _handleDragStart(challengeId, details.localPosition, boxSize);
                  instance.onUpdate = (details) => _handleDragUpdate(details.localPosition);
                  instance.onEnd = (details) => _handleDragEnd(boxSize);
                  instance.onCancel = () {
                    setState(() {
                      _isDrawing = false;
                      _activeChallengeId = null;
                      _dragStartNode = null;
                      _currentDragPosition = null;
                    });
                  };
                },
              ),
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: challenge.isCompleted ? Colors.teal.shade300 : Colors.grey.shade300,
                  width: challenge.isCompleted ? 3.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: challenge.isCompleted
                        ? Colors.teal.withOpacity(0.05)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Completed & active drawing lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LineConnectorPainter(
                        nodes: challenge.nodes,
                        completedConnections: challenge.completedConnections,
                        isCurrentDragActive: _activeChallengeId == challengeId,
                        dragStartNode: _dragStartNode,
                        currentDragPosition: _currentDragPosition,
                        boxSize: boxSize,
                      ),
                    ),
                  ),

                  // Hexagon nodes positioned inside the stack
                  ...challenge.nodes.map((node) {
                    final double x = node.position.dx * boxSize.width - 22; // Hexagon is 44x44
                    final double y = node.position.dy * boxSize.height - 22;

                    // Box 1 (id 0) shows numbers inside, other boxes hide them (or show small dots)
                    final bool showNumber = challenge.id == 0;

                    return Positioned(
                      left: x,
                      top: y,
                      child: ClipPath(
                        clipper: HexagonClipper(),
                        child: Container(
                          width: 44,
                          height: 44,
                          color: node.color,
                          child: Center(
                            child: showNumber
                                ? Text(
                                    '${node.number}',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white60,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Complete Badge icon
                  if (challenge.isCompleted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.teal.shade400,
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    // Hexagon pointing upwards
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LineConnectorPainter extends CustomPainter {
  final List<HexagonNode> nodes;
  final List<int> completedConnections;
  final bool isCurrentDragActive;
  final int? dragStartNode;
  final Offset? currentDragPosition;
  final Size boxSize;

  LineConnectorPainter({
    required this.nodes,
    required this.completedConnections,
    required this.isCurrentDragActive,
    required this.dragStartNode,
    required this.currentDragPosition,
    required this.boxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Drawing finished lines with custom arrow style
    for (int startNum in completedConnections) {
      final startNode = nodes.firstWhere((n) => n.number == startNum);
      final targetNode = nodes.firstWhere((n) => n.number == startNum + 1);

      final startPos = Offset(startNode.position.dx * size.width, startNode.position.dy * size.height);
      final endPos = Offset(targetNode.position.dx * size.width, targetNode.position.dy * size.height);

      final paint = Paint()
        ..color = startNode.color.withOpacity(0.8)
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      _drawArrow(canvas, startPos, endPos, paint);
    }

    // Drawing the active dragged line
    if (isCurrentDragActive && dragStartNode != null && currentDragPosition != null) {
      final startNode = nodes.firstWhere((n) => n.number == dragStartNode);
      final startPos = Offset(startNode.position.dx * size.width, startNode.position.dy * size.height);

      final paint = Paint()
        ..color = startNode.color.withOpacity(0.5)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(startPos, currentDragPosition!, paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);

    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double length = sqrt(dx * dx + dy * dy);
    if (length < 10) return;

    final double ux = dx / length;
    final double uy = dy / length;

    final double arrowSize = 10.0;
    
    // Position arrowhead just at the border edge of target hexagon (approx 22px from center)
    const double offsetDist = 23.0;
    final Offset arrowTip = Offset(end.dx - ux * offsetDist, end.dy - uy * offsetDist);

    final Offset leftWing = Offset(
      arrowTip.dx - ux * arrowSize + uy * (arrowSize * 0.6),
      arrowTip.dy - uy * arrowSize - ux * (arrowSize * 0.6),
    );

    final Offset rightWing = Offset(
      arrowTip.dx - ux * arrowSize - uy * (arrowSize * 0.6),
      arrowTip.dy - uy * arrowSize + ux * (arrowSize * 0.6),
    );

    final Path arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();

    final Paint arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant LineConnectorPainter oldDelegate) {
    return oldDelegate.completedConnections.length != completedConnections.length ||
        oldDelegate.isCurrentDragActive != isCurrentDragActive ||
        oldDelegate.currentDragPosition != currentDragPosition;
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
