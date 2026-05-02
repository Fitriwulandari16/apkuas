import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/features/spatial/line_tracing_screen.dart';
import 'package:apkuas/core/providers/progress_provider.dart';

class AdventureMapScreen extends ConsumerStatefulWidget {
  const AdventureMapScreen({super.key});

  @override
  ConsumerState<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends ConsumerState<AdventureMapScreen> {
  final List<int> rowCounts = [11, 9, 8, 6, 6, 7, 8, 9, 8, 8, 7, 6, 3];
  final double tileSize = 36.0; // 32 tile + 4 margin
  
  Map<int, Offset> _levelPositions = {};

  @override
  Widget build(BuildContext context) {
    final unlockedLevel = ref.watch(progressProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF2E4482),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C78C1),
        elevation: 0,
        title: const Text('Adventure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.emoji_events, size: 100, color: Color(0xFF1A2A52)),
                const SizedBox(height: 16),
                const Text(
                  'Selesaikan petualangan dan menangkan trofi!',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                
                // Map Container with Stack
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _calculatePositions(constraints.maxWidth);
                      
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Path/Tiles
                          Column(
                            children: _buildRows(),
                          ),
                          
                          // Animated Flag
                          if (_levelPositions.containsKey(unlockedLevel))
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                              left: _levelPositions[unlockedLevel]!.dx + 8, // Center on tile
                              top: _levelPositions[unlockedLevel]!.dy - 18, // Above tile
                              child: const Icon(Icons.flag_rounded, color: Colors.yellow, size: 24),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
          
          // Bottom Play Button
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomPlayButton(unlockedLevel: unlockedLevel),
          ),
        ],
      ),
    );
  }

  void _calculatePositions(double maxWidth) {
    _levelPositions.clear();
    int levelCounter = 1;
    double currentY = 0;
    
    // We reverse the rowCounts to match the top-to-bottom display
    final reversedCounts = rowCounts.reversed.toList();
    
    for (int r = 0; r < reversedCounts.length; r++) {
      int count = reversedCounts[r];
      double rowWidth = count * tileSize;
      double startX = (maxWidth - rowWidth) / 2;
      
      for (int i = 0; i < count; i++) {
        _levelPositions[levelCounter++] = Offset(startX + (i * tileSize), currentY);
      }
      currentY += tileSize + 4; // Add vertical spacing
    }
  }

  List<Widget> _buildRows() {
    List<Widget> rows = [];
    int levelCounter = 1;
    final reversedCounts = rowCounts.reversed.toList();
    final unlockedLevel = ref.watch(progressProvider);

    for (int count in reversedCounts) {
      List<Widget> tiles = [];
      for (int i = 0; i < count; i++) {
        int level = levelCounter++;
        tiles.add(_LevelTile(
          level: level, 
          status: level < unlockedLevel ? _LevelStatus.unlocked : (level == unlockedLevel ? _LevelStatus.current : _LevelStatus.locked),
        ));
      }
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: tiles),
      ));
    }
    return rows;
  }
}

enum _LevelStatus { locked, unlocked, current }

class _LevelTile extends StatelessWidget {
  final int level;
  final _LevelStatus status;

  const _LevelTile({required this.level, required this.status});

  @override
  Widget build(BuildContext context) {
    bool isClickable = status != _LevelStatus.locked;
    
    Color boxColor;
    Color textColor;
    
    switch (status) {
      case _LevelStatus.locked:
        boxColor = const Color(0xFF1E2F5A);
        textColor = Colors.white24;
        break;
      case _LevelStatus.unlocked:
        boxColor = Colors.yellow.withOpacity(0.8);
        textColor = Colors.brown;
        break;
      case _LevelStatus.current:
        boxColor = const Color(0xFF4A68B1);
        textColor = Colors.white;
        break;
    }

    return GestureDetector(
      onTap: isClickable ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LineTracingScreen(levelId: level)),
        );
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 32,
        height: 32,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(8),
          border: status == _LevelStatus.current ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: status == _LevelStatus.current ? [BoxShadow(color: boxColor.withOpacity(0.5), blurRadius: 8)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$level',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _BottomPlayButton extends StatelessWidget {
  final int unlockedLevel;
  const _BottomPlayButton({required this.unlockedLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF5C78C1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LineTracingScreen(levelId: unlockedLevel)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
        child: Text(
          'MAIN LEVEL $unlockedLevel',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
