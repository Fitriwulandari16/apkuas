import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
//import 'package:apkuas/features/coding/coding_workspace.dart';
import 'package:apkuas/features/level_selection_screen.dart';
import 'package:apkuas/features/adventure_map_screen.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenuScreen(),
        '/adventure_map': (context) => const AdventureMapScreen(),
      },
    );
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      backgroundColor: Colors.transparent,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE0F2F1), // Very light teal
                Colors.white,
                Color(0xFFFFF3E0), // Very light orange
              ],
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: CilikTheme.tealTua),
                          onPressed: () {},
                        ),
                        Text(
                          'CilikCode',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: CilikTheme.tealTua,
                                letterSpacing: 1.2,
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                      child: Column(
                        children: [
                        Transform.rotate(
                          angle: -0.05,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: AspectRatio(
                              aspectRatio: 1.2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/images/rocket.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Title
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Belajar Coding',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: MediaQuery.of(context).size.width * 0.09,
                                  color: Colors.black87,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Transform.rotate(
                          angle: -0.02,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: CilikTheme.tealTua,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Text(
                                'Jadi Seru!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                          const SizedBox(height: 48),

                          // Main Buttons
                          _StylizedButton(
                            title: 'Mulai Belajar',
                            icon: Icons.play_arrow_rounded,
                            color: CilikTheme.tealTua,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LevelSelectionScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _StylizedButton(
                            title: 'Peta Petualangan',
                            icon: Icons.map_rounded,
                            color: CilikTheme.woodBrown,
                            onPressed: () {
                              Navigator.pushNamed(context, '/adventure_map');
                            },
                          ),
                          const SizedBox(height: 16),
                          _StylizedButton(
                            title: 'Dashboard Orang Tua',
                            icon: Icons.account_tree_rounded,
                            color: Colors.white,
                            textColor: Colors.blueGrey,
                            onPressed: () {},
                          ),
                          const SizedBox(height: 40),

                          // Badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Badge(
                                label: 'Logika Dasar',
                                icon: Icons.extension_rounded,
                                color: const Color(0xFFE3F2FD),
                                iconColor: Colors.teal,
                              ),
                              const SizedBox(width: 12),
                              _Badge(
                                label: 'Kreativitas',
                                icon: Icons.auto_awesome_rounded,
                                color: const Color(0xFFF3E5F5),
                                iconColor: Colors.teal,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Bottom Nav
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        icon: Icons.home_filled,
                        label: 'Home',
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _NavItem(
                        icon: Icons.map_rounded,
                        label: 'Map',
                        isSelected: _selectedIndex == 1,
                        onTap: () {
                          setState(() => _selectedIndex = 1);
                          Navigator.pushNamed(context, '/adventure_map');
                        },
                      ),
                      _NavItem(
                        icon: Icons.stars_rounded,
                        label: 'Awards',
                        isSelected: _selectedIndex == 2,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StylizedButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _StylizedButton({
    required this.title,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.9,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: color == Colors.white ? BorderSide(color: Colors.grey.shade300, width: 2) : null,
        ),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: FittedBox(child: Icon(icon, color: textColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CilikTheme.mintGreen.withOpacity(0.4) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? CilikTheme.tealTua : Colors.blueGrey,
              size: 28,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? CilikTheme.tealTua : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}