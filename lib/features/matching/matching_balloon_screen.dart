import 'package:flutter/material.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';

class MatchingBalloonScreen extends StatefulWidget {
  const MatchingBalloonScreen({super.key});

  @override
  State<MatchingBalloonScreen> createState() => _MatchingBalloonScreenState();
}

class _MatchingBalloonScreenState extends State<MatchingBalloonScreen> {
  final List<Color> balloonColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
  ];

  late List<Color> targets;
  late List<Color> choices;
  Map<Color, bool> score = {};

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    targets = List.from(balloonColors)..shuffle();
    choices = List.from(balloonColors)..shuffle();
    score = {for (var color in balloonColors) color: false};
  }

  @override
  Widget build(BuildContext context) {
    bool isWin = score.values.every((v) => v == true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Balon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _resetGame()),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Tarik balon ke kotak yang warnanya sama!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              // Target Areas
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: targets.map((color) {
                    return DragTarget<Color>(
                      onAccept: (receivedColor) {
                        if (receivedColor == color) {
                          setState(() {
                            score[color] = true;
                          });
                          HapticService.success();
                        } else {
                          HapticService.failure();
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return _BalloonBasket(
                          color: color,
                          isMatched: score[color]!,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              // Draggable Balloons
              Padding(
                padding: const EdgeInsets.only(bottom: 64),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: choices.map((color) {
                    return score[color]!
                        ? const SizedBox(width: 80, height: 80)
                        : Draggable<Color>(
                            data: color,
                            feedback: _BalloonWidget(color: color, isDragging: true),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _BalloonWidget(color: color),
                            ),
                            child: _BalloonWidget(color: color),
                          );
                  }).toList(),
                ),
              ),
            ],
          ),
          if (isWin) _WinOverlay(onReset: () => setState(() => _resetGame())),
        ],
      ),
    );
  }
}

class _BalloonWidget extends StatelessWidget {
  final Color color;
  final bool isDragging;

  const _BalloonWidget({required this.color, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.elliptical(40, 50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.4 : 0.1),
            blurRadius: isDragging ? 12 : 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shine highlight
          Positioned(
            top: 15,
            left: 15,
            child: Container(
              width: 15,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalloonBasket extends StatelessWidget {
  final Color color;
  final bool isMatched;

  const _BalloonBasket({required this.color, required this.isMatched});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 110,
          decoration: BoxDecoration(
            color: isMatched ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMatched ? color : Colors.grey.shade400,
              width: 3,
              style: BorderStyle.solid,
            ),
          ),
          child: isMatched
              ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 48)
              : Icon(Icons.add_rounded, color: Colors.grey.shade400, size: 40),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.4),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}

class _WinOverlay extends StatelessWidget {
  final VoidCallback onReset;

  const _WinOverlay({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Luar Biasa! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kamu berhasil mencocokkan semua balon!',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: onReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: CilikTheme.successPastel,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            ),
            child: const Text('Main Lagi'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali ke Menu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
