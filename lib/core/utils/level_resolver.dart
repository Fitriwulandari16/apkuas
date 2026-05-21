import 'package:flutter/material.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
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
import 'package:apkuas/features/spatial/star_coloring_screen.dart';
import 'package:apkuas/features/spatial/shape_completion_screen.dart';
import 'package:apkuas/features/spatial/bee_home_screen.dart';
import 'package:apkuas/features/matching/composition_matching_screen.dart';
import 'package:apkuas/features/matching/decomposition_matching_screen.dart';
import 'package:apkuas/features/matching/shape_color_matching_screen.dart';
import 'package:apkuas/features/matching/pattern_loop_coloring_screen.dart';
import 'package:apkuas/features/matching/sequence_completion_screen.dart';
import 'package:apkuas/features/matching/infinite_drag_matching_screen.dart';
import 'package:apkuas/features/matching/image_matching_legend_screen.dart';
import 'package:apkuas/features/matching/circle_matching_size_screen.dart';


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
        return const StarColoringScreen(levelId: 10);
      case 11:
        return const ShapeCompletionScreen(levelId: 11);
      case 12:
        return const BeeHomeScreen(levelId: 12);
      case 13:
        return const CompositionMatchingScreen(levelId: 13);
      case 14:
        return const DecompositionMatchingScreen(levelId: 14);
      case 15:
        return const ShapeColorMatchingScreen(levelId: 15);
      case 16:
        return const PatternLoopColoringScreen(levelId: 16);
      case 17:
        return const SequenceCompletionScreen(levelId: 17);
      case 18:
        return const InfiniteDragMatchingScreen(levelId: 18);
      case 19:
        return const ImageMatchingLegendScreen(levelId: 19);
      case 20:
        return const CircleMatchingSizeScreen(levelId: 20);

      default:
        // Fallback or placeholder for future levels
        return Builder(
          builder: (context) => Scaffold(
            backgroundColor: CilikTheme.backgroundLight,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.construction_rounded, size: 120, color: CilikTheme.tealTua),
                  const SizedBox(height: 24),
                  Text(
                    'Level $levelId',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(color: CilikTheme.tealTua),
                  ),
                  Text(
                    'Sedang Dibangun!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context), 
                      style: ElevatedButton.styleFrom(backgroundColor: CilikTheme.woodBrown),
                      child: const Text('KEMBALI'),
                    ),
                  ),
                ],
              ),
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
        if (widget.nextLevelId == 11) {
          Navigator.pushReplacementNamed(context, '/level_11');
        } else if (widget.nextLevelId == 12) {
          Navigator.pushReplacementNamed(context, '/level_12');
        } else if (widget.nextLevelId == 13) {
          Navigator.pushReplacementNamed(context, '/level_13');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LevelResolver.buildLevel(widget.nextLevelId)),
          );
        }
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
      backgroundColor: CilikTheme.tealTua,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, size: 150, color: Colors.amberAccent),
              const SizedBox(height: 32),
              const Text(
                'LEVEL UP!',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tantangan Berikutnya: Level ${widget.nextLevelId}',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 60),
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 6),
            ],
          ),
        ),
      ),
    );
  }
}
