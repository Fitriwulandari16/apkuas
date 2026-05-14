import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/features/level_selection_screen.dart';
import 'package:apkuas/features/adventure_map_screen.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:apkuas/core/providers/profile_provider.dart';
import 'package:apkuas/features/awards_screen.dart';
import 'package:apkuas/features/spatial/star_coloring_screen.dart';
import 'package:apkuas/features/spatial/shape_completion_screen.dart';
import 'package:apkuas/features/spatial/bee_home_screen.dart';
import 'package:apkuas/features/matching/composition_matching_screen.dart';

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
        '/awards': (context) => const AwardsScreen(),
        '/level_10': (context) => const StarColoringScreen(),
        '/level_11': (context) => const ShapeCompletionScreen(),
        '/level_12': (context) => const BeeHomeScreen(),
        '/level_13': (context) => const CompositionMatchingScreen(),
        '/level_14': (context) => const Scaffold(body: Center(child: Text('Level 14 Coming Soon!'))),
      },
    );
  }
}

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
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
                        GestureDetector(
                          onTap: () => _showProfileDialog(context),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween(begin: 1.0, end: 1.0),
                            builder: (context, scale, child) => Transform.scale(
                              scale: scale,
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE0F2F1),
                                child: Text(
                                  ref.watch(profileProvider).avatarIcon,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                          ),
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
                        Text(
                          'Belajar Coding',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: MediaQuery.of(context).size.width * 0.09,
                                color: Colors.black87,
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
                        onTap: () {
                          setState(() => _selectedIndex = 2);
                          Navigator.pushNamed(context, '/awards');
                        },
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

  void _showProfileDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      builder: (context) => const _ProfilePopupContent(),
    );
  }
}

class _ProfilePopupContent extends ConsumerStatefulWidget {
  const _ProfilePopupContent();

  @override
  ConsumerState<_ProfilePopupContent> createState() => _ProfilePopupContentState();
}

class _ProfilePopupContentState extends ConsumerState<_ProfilePopupContent> {
  bool isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final avatars = [
      {'emoji': '🦁', 'name': 'Singa'},
      {'emoji': '🦊', 'name': 'Rubah'},
      {'emoji': '🐶', 'name': 'Anjing'},
      {'emoji': '🐰', 'name': 'Kelinci'},
      {'emoji': '🐼', 'name': 'Panda'},
      {'emoji': '🐯', 'name': 'Harimau'},
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(profile.avatarIcon, style: const TextStyle(fontSize: 45)),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.totalStars} Bintang',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih Avatar Kamu:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ),
            const SizedBox(height: 20),
            AbsorbPointer(
              absorbing: isUpdating,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  // SINGLE SELECTION LOGIC: Only one can be true based on the global state
                  bool isSelected = profile.avatarIcon == avatar['emoji'];

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (isUpdating) return;
                      
                      setState(() => isUpdating = true);
                      print('DEBUG: Memilih Avatar ${avatar['name']}');
                      
                      // Update the global state
                      ref.read(profileProvider.notifier).updateAvatar(avatar['emoji']!);
                      
                      // Auto-close after selection with brief visual confirmation
                      Future.delayed(const Duration(milliseconds: 250), () {
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00695C).withOpacity(0.1) : Colors.grey.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00695C) : Colors.transparent,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(avatar['emoji']!, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
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
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
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