import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

class AdventureMapScreen extends ConsumerWidget {
  const AdventureMapScreen({super.key});

  static const List<int> rowCounts = [11, 9, 8, 6, 6, 7, 8, 9, 8, 8, 7, 6, 3];
  static const double tileSize = 32.0;
  static const double tileMargin = 1.0;
  static const double rowPadding = 2.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedLevel = ref.watch(progressProvider);

    List<List<int>> rows = [];
    Map<int, Offset> levelPositions = {};
    int levelCounter = 1;
    double currentY = 0;
    
    for (int count in rowCounts) {
      List<int> row = [];
      double rowWidth = count * (tileSize + (tileMargin * 2));
      double startX = -rowWidth / 2;
      for (int i = 0; i < count; i++) {
        int levelId = levelCounter++;
        row.add(levelId);
        double x = startX + (i * (tileSize + (tileMargin * 2))) + tileMargin + (tileSize / 2);
        levelPositions[levelId] = Offset(x, currentY + (tileSize / 2));
      }
      rows.add(row);
      currentY += tileSize + (tileMargin * 2) + (rowPadding * 2);
    }
    double totalHeight = currentY;

    return Scaffold(
      backgroundColor: const Color(0xFF2E4482),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C78C1),
        elevation: 0,
        title: const Text('Peta Petualangan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
            onPressed: () => _showResetDialog(context, ref),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double centerX = constraints.maxWidth / 2;
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.emoji_events, size: 100, color: Color(0xFF1A2A52)),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text('Ikuti Petualangan dan menangkan pialanya!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      height: totalHeight,
                      width: constraints.maxWidth,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (var entry in levelPositions.entries)
                            Positioned(
                              left: centerX + entry.value.dx - (tileSize / 2),
                              top: totalHeight - entry.value.dy - (tileSize / 2),
                              child: _LevelTile(level: entry.key, isUnlocked: entry.key <= unlockedLevel, isCurrent: entry.key == unlockedLevel),
                            ),
                          if (levelPositions.containsKey(unlockedLevel))
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                              left: centerX + levelPositions[unlockedLevel]!.dx - (tileSize / 2) + 8,
                              top: totalHeight - levelPositions[unlockedLevel]!.dy - (tileSize / 2) - 18,
                              child: const IgnorePointer(child: Icon(Icons.flag_rounded, color: Colors.yellow, size: 24)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
              _BottomPlayButton(unlockedLevel: unlockedLevel),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Reset Progres?'), content: const Text('Semua level akan dikunci kembali.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), TextButton(onPressed: () { ref.read(progressProvider.notifier).resetProgress(); Navigator.pop(context); }, child: const Text('Reset', style: TextStyle(color: Colors.red)))]));
  }
}

class _LevelTile extends StatelessWidget {
  final int level; final bool isUnlocked; final bool isCurrent;
  const _LevelTile({required this.level, required this.isUnlocked, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => LevelResolver.buildLevel(level))) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: AdventureMapScreen.tileSize, height: AdventureMapScreen.tileSize,
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFF4A68B1) : (isUnlocked ? Colors.yellow.withOpacity(0.9) : const Color(0xFF1E2F5A)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isCurrent ? Colors.white : (isUnlocked ? Colors.orange.shade300 : Colors.transparent), width: isCurrent ? 2 : 1),
          boxShadow: isCurrent ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 8)] : null,
        ),
        alignment: Alignment.center,
        child: Text('$level', style: TextStyle(color: isCurrent ? Colors.white : (isUnlocked ? Colors.brown.shade700 : Colors.white24), fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _BottomPlayButton extends StatelessWidget {
  final int unlockedLevel;
  const _BottomPlayButton({required this.unlockedLevel});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity, height: 110,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, const Color(0xFF2E4482).withOpacity(0.9), const Color(0xFF2E4482)])),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LevelResolver.buildLevel(unlockedLevel))),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade400, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8, shadowColor: Colors.green.withOpacity(0.5)),
          child: Text('MAINKAN LEVEL $unlockedLevel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ),
      ),
    );
  }
}
