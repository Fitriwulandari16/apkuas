import 'package:flutter/material.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/features/matching/matching_balloon_screen.dart';
import 'package:apkuas/features/spatial/line_tracing_screen.dart';
import 'package:apkuas/features/spatial/advanced_line_tracing_screen.dart';
import 'package:apkuas/features/spatial/object_relation_screen.dart';
import 'package:apkuas/features/spatial/shape_matching_screen.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Scaffold(
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: CilikTheme.tealTua),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CilikCode',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: CilikTheme.tealTua,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(Icons.face_retouching_natural_rounded, color: CilikTheme.tealTua),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Pilih Petualangan',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: CilikTheme.tealTua),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
          _StageCard(
            title: 'Tahap 1: Detektif Visual',
            description: 'Ayo cari benda yang sama!',
            color: CilikTheme.mintGreen,
            icon: Icons.search_rounded,
            levels: [
              _LevelItem(
                title: 'Mencocokkan Balon (Lvl 3)',
                icon: Icons.bubble_chart_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchingBalloonScreen()));
                },
              ),
              _LevelItem(
                title: 'Mencocokkan Bentuk (Lvl 5)',
                icon: Icons.category_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ShapeMatchingScreen()));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _StageCard(
            title: 'Tahap 2: Arsitek Cilik',
            description: 'Belajar membangun dan menggambar.',
            color: const Color(0xFFFFCC80), // Pastel orange
            icon: Icons.architecture_rounded,
            isLocked: false,
            levels: [
              _LevelItem(
                title: 'Tiru Garis Dasar (Lvl 1)',
                icon: Icons.gesture_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LineTracingScreen()));
                },
              ),
              _LevelItem(
                title: 'Garis Majemuk (Lvl 2)',
                icon: Icons.gesture_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdvancedLineTracingScreen()));
                },
              ),
              _LevelItem(
                title: 'Hubungkan Objek (Lvl 4)',
                icon: Icons.link_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ObjectRelationScreen()));
                },
              ),
            ],
          ),
        ],
      ),
            ),
          ],
        ),
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
