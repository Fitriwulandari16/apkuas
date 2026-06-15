import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:apkuas/core/widgets/level_up_overlay.dart';
import 'dart:math' as math;

class CelebrationUtils {
  static void showCelebrationAndLevelUp({
    required BuildContext context,
    required int nextLevelId,
    String? title,
    String? message,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => _CelebrationScreen(
          nextLevelId: nextLevelId,
          title: title ?? 'Hebat! Kamu Pintar!',
          message: message ?? 'Tantangan Berikutnya: Level $nextLevelId',
        ),
      ),
    );
  }
}

class _CelebrationScreen extends StatefulWidget {
  final int nextLevelId;
  final String title;
  final String message;

  const _CelebrationScreen({
    required this.nextLevelId,
    required this.title,
    required this.message,
  });

  @override
  State<_CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<_CelebrationScreen> {
  late ConfettiController _confettiController;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    // Safety backup to manually stop confetti after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _confettiController.stop();
      }
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showOverlay = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.stop();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: _showOverlay ? Colors.black.withOpacity(0.7) : Colors.transparent,
          ),
          if (_showOverlay)
            Center(
              child: LevelUpOverlay(
                title: widget.title,
                message: widget.message,
                nextRoute: '/level_${widget.nextLevelId}',
                isEmbedded: true, // Tell the overlay not to render its own Scaffold background
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2, // Straight down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}
