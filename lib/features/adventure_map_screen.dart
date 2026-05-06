import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';

class AdventureMapScreen extends ConsumerWidget {
  const AdventureMapScreen({super.key});

  // Trophy/Vase silhouette structure (top to bottom)
  static const List<int> rowCounts = [3, 6, 7, 8, 8, 9, 8, 8, 7, 6, 8, 9, 11];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedLevel = ref.watch(progressProvider);

    // Calculate total levels and map IDs to rows
    List<List<int>> levelRows = [];
    int totalLevels = rowCounts.reduce((a, b) => a + b);
    int currentId = totalLevels; // We'll build from top to bottom (98 down to 1)

    for (int count in rowCounts) {
      List<int> row = [];
      for (int i = 0; i < count; i++) {
        row.add(currentId--);
      }
      // Keep levels in ascending order within the row for logic, but we'll reverse visual display
      levelRows.add(row.reversed.toList());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E2F5A), // Original deep blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4482),
        elevation: 0,
        centerTitle: true,
        title: const Text('Peta Petualangan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Trophy Header
                const Icon(Icons.emoji_events_rounded, size: 100, color: Color(0xFF2D3E50)),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Ikuti Petualangan dan menangkan pialanya!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 40),

                // Custom Level Map (Vase Shape)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: levelRows.map((row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: row.map((id) {
                            bool isUnlocked = id <= unlockedLevel;
                            bool isCurrent = id == unlockedLevel;
                            return _LevelTile(
                              id: id,
                              isUnlocked: isUnlocked,
                              isCurrent: isCurrent,
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 150), // Bottom padding for FAB
              ],
            ),
          ),

          // Floating Play Button
          Align(
            alignment: Alignment.bottomCenter,
            child: _FloatingPlayButton(unlockedLevel: unlockedLevel),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Progres?'),
        content: const Text('Semua level akan dikunci kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(progressProvider.notifier).resetProgress();
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int id;
  final bool isUnlocked;
  final bool isCurrent;

  const _LevelTile({required this.id, required this.isUnlocked, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked
          ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => LevelResolver.buildLevel(id)))
          : null,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.all(3),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isCurrent 
                  ? const Color(0xFF5C78C1) 
                  : (isUnlocked ? const Color(0xFF4A90E2) : const Color(0xFF162548)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent ? Colors.white : (isUnlocked ? Colors.white24 : Colors.transparent),
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isUnlocked ? [
                BoxShadow(
                  color: isCurrent ? Colors.white.withOpacity(0.3) : Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Center(
              child: Text(
                '$id',
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white24,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isCurrent)
            const Positioned(
              top: -14,
              child: Icon(Icons.flag_rounded, color: Colors.yellow, size: 20),
            ),
        ],
      ),
    );
  }
}

class _FloatingPlayButton extends StatelessWidget {
  final int unlockedLevel;
  const _FloatingPlayButton({required this.unlockedLevel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 25.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF81C784), Color(0xFF43A047)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LevelResolver.buildLevel(unlockedLevel))),
              child: Center(
                child: Text(
                  'MAINKAN LEVEL $unlockedLevel',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
