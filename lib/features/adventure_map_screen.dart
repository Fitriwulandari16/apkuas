import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

class AdventureMapScreen extends ConsumerWidget {
  const AdventureMapScreen({super.key});

  // Trophy/Vase silhouette structure (top to bottom) matching reference image
  static const List<int> rowCounts = [3, 6, 7, 8, 8, 9, 8, 7, 6, 6, 8, 9, 11];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedLevel = ref.watch(progressProvider);

    // Calculate total levels and map IDs to rows
    List<List<int>> levelRows = [];
    int totalLevels = rowCounts.reduce((a, b) => a + b);
    int currentId = totalLevels;

    for (int count in rowCounts) {
      List<int> row = [];
      for (int i = 0; i < count; i++) {
        row.add(currentId--);
      }
      levelRows.add(row.reversed.toList());
    }

    const Color deepBlueBg = Color(0xFF3B4B70);
    const Color headerFooterBlue = Color(0xFF5C7BC1);

    return ResponsiveWrapper(
      backgroundColor: deepBlueBg,
      child: Scaffold(
        backgroundColor: deepBlueBg,
        appBar: AppBar(
          backgroundColor: headerFooterBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Adventure',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
          ),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Dynamically calculate tile size based on available width
            // 11 is the maximum number of tiles in a row
            double horizontalPadding = 24;
            double tileSize = (constraints.maxWidth - horizontalPadding) / 11;
            // Cap tile size for very large screens (Desktop/Web)
            if (tileSize > 45) tileSize = 45;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        // Trophy Header
                        const Icon(Icons.emoji_events_rounded, size: 80, color: Color(0xFF26334D)),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Take part in the Adventure\nand win the trophy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Custom Level Map
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                          child: Column(
                            children: levelRows.map((row) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 0.5),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: row.map((id) {
                                    bool isUnlocked = id <= unlockedLevel;
                                    bool isCurrent = id == unlockedLevel;
                                    return _LevelTile(
                                      id: id,
                                      tileSize: tileSize,
                                      isUnlocked: isUnlocked,
                                      isCurrent: isCurrent,
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // Bottom Button Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  color: headerFooterBlue,
                  child: SafeArea(
                    top: false,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LevelResolver.buildLevel(unlockedLevel))),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Level $unlockedLevel',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int id;
  final double tileSize;
  final bool isUnlocked;
  final bool isCurrent;

  const _LevelTile({
    required this.id,
    required this.tileSize,
    required this.isUnlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    const Color tileColor = Color(0xFF26334D);
    const Color highlightColor = Color(0xFFFFD54F);

    return Container(
      width: tileSize - 1, // Subtract small margin
      height: tileSize - 1,
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: isCurrent ? highlightColor : tileColor,
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  '$id',
                  style: TextStyle(
                    color: isCurrent ? Colors.black87 : (isUnlocked ? Colors.white60 : Colors.white24),
                    fontSize: tileSize * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (isCurrent)
            Positioned(
              top: -1,
              child: Icon(Icons.bookmark, color: Colors.orange.withOpacity(0.8), size: tileSize * 0.4),
            ),
        ],
      ),
    );
  }
}
