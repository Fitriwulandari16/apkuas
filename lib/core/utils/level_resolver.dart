import 'package:flutter/material.dart';
import 'package:apkuas/features/spatial/line_tracing_screen.dart';
import 'package:apkuas/features/spatial/advanced_line_tracing_screen.dart';
import 'package:apkuas/features/matching/matching_balloon_screen.dart';
import 'package:apkuas/features/spatial/object_relation_screen.dart';
import 'package:apkuas/features/spatial/shape_matching_screen.dart';
import 'package:apkuas/features/spatial/conditional_drawing_screen.dart';
import 'package:apkuas/features/spatial/multi_step_conditional_drawing_screen.dart';
import 'package:apkuas/features/matching/flower_matching_screen.dart';
import 'package:apkuas/features/matching/shape_line_matching_screen.dart';
import 'package:apkuas/features/spatial/hot_air_balloon_coloring_screen.dart';
import 'package:apkuas/features/spatial/advanced_balloon_coloring_screen.dart';

class LevelResolver {
  static Widget buildLevel(int levelId) {
    switch (levelId) {
      case 1:
        return const LineTracingScreen(levelId: 1);
      case 2:
        return const AdvancedLineTracingScreen(levelId: 2);
      case 3:
        return const MatchingBalloonScreen(levelId: 3);
      case 4:
        return const ObjectRelationScreen(levelId: 4);
      case 5:
        return const ShapeMatchingScreen(levelId: 5);
      case 6:
        return const ConditionalDrawingScreen(levelId: 6);
      case 7:
        return const MultiStepConditionalDrawingScreen(levelId: 7);
      case 8:
        return const FlowerMatchingScreen(levelId: 8);
      case 9:
        return const ShapeLineMatchingScreen(levelId: 9);
      case 10:
        return const HotAirBalloonColoringScreen(levelId: 10);
      case 11:
        return const AdvancedBalloonColoringScreen(levelId: 11);
      default:
        // Fallback or placeholder for future levels
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.construction_rounded, size: 100, color: Colors.orange),
                const SizedBox(height: 20),
                Text('Level $levelId Sedang Dibangun!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop, 
                  child: const Text('KEMBALI')
                ),
              ],
            ),
          ),
        );
    }
  }
}

class LevelTransitionScreen extends StatefulWidget {
  final int nextLevelId;
  const LevelTransitionScreen({super.key, required this.nextLevelId});

  @override
  State<LevelTransitionScreen> createState() => _LevelTransitionScreenState();
}

class _LevelTransitionScreenState extends State<LevelTransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    // Auto navigate after transition
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LevelResolver.buildLevel(widget.nextLevelId)),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5C78C1),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, size: 120, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                'LEVEL UP!',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4),
              ),
              const SizedBox(height: 12),
              Text(
                'Tantangan Berikutnya: Level ${widget.nextLevelId}',
                style: const TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
