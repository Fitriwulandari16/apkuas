import 'package:flutter/material.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/features/matching/matching_balloon_screen.dart';
import 'package:apkuas/features/spatial/line_tracing_screen.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Petualangan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _StageCard(
            title: 'Tahap 1: Detektif Visual',
            description: 'Ayo cari benda yang sama!',
            color: CilikTheme.primaryPastel,
            icon: Icons.search_rounded,
            levels: [
              _LevelItem(
                title: 'Mencocokkan Balon',
                icon: Icons.bubble_chart_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MatchingBalloonScreen()),
                  );
                },
              ),
              _LevelItem(
                title: 'Mencocokkan Bentuk',
                icon: Icons.category_rounded,
                onTap: () {
                  // TODO: Implement Shape Matching
                },
                isLocked: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StageCard(
            title: 'Tahap 2: Arsitek Cilik',
            description: 'Belajar membangun dan menggambar.',
            color: CilikTheme.secondaryPastel,
            icon: Icons.architecture_rounded,
            isLocked: false,
            levels: [
              _LevelItem(
                title: 'Tiru Garis',
                icon: Icons.gesture_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LineTracingScreen()),
                  );
                },
              ),
              _LevelItem(
                title: 'Puzzle Gunting',
                icon: Icons.content_cut_rounded,
                onTap: () {},
                isLocked: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StageCard(
            title: 'Tahap 3: Ahli Logika',
            description: 'Pecahkan misteri dengan logika.',
            color: CilikTheme.accentPastel,
            icon: Icons.psychology_rounded,
            levels: [],
            isLocked: true,
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final List<_LevelItem> levels;
  final bool isLocked;

  const _StageCard({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.levels,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: color, size: 40),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(description),
            trailing: isLocked ? const Icon(Icons.lock_rounded, color: Colors.grey) : null,
          ),
          if (!isLocked && levels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: levels,
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLocked;

  const _LevelItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isLocked ? Colors.grey : Colors.blueGrey),
      title: Text(
        title,
        style: TextStyle(
          color: isLocked ? Colors.grey : Colors.black87,
        ),
      ),
      trailing: isLocked ? const Icon(Icons.lock_outline_rounded, size: 20) : const Icon(Icons.chevron_right_rounded),
      onTap: isLocked ? null : onTap,
    );
  }
}
