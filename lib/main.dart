import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
//import 'package:apkuas/features/coding/coding_workspace.dart';
import 'package:apkuas/features/level_selection_screen.dart';
import 'package:apkuas/features/adventure_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('progress');

  runApp(
    const ProviderScope(
      child: CilikCodeApp(),
    ),
  );
}

class CilikCodeApp extends StatelessWidget {
  const CilikCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CilikCode',
      debugShowCheckedModeBanner: false,
      theme: CilikTheme.lightTheme,
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CilikTheme.backgroundPastel, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon Placeholder
                const Icon(
                  Icons.extension_rounded,
                  size: 120,
                  color: CilikTheme.primaryPastel,
                ),
                const SizedBox(height: 24),
                Text(
                  'CilikCode',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: CilikTheme.primaryPastel,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Belajar Coding Jadi Seru!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 64),
                _MenuButton(
                  title: 'Mulai Belajar',
                  icon: Icons.play_arrow_rounded,
                  color: CilikTheme.primaryPastel,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LevelSelectionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  title: 'Peta Petualangan',
                  icon: Icons.map_rounded,
                  color: Colors.blue.shade200,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdventureMapScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  title: 'Dashboard Orang Tua',
                  icon: Icons.family_restroom_rounded,
                  color: CilikTheme.accentPastel,
                  onPressed: () {
                    // TODO: Parental Dashboard
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 4,
          shadowColor: color.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}