import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/features/level_selection_screen.dart';
import 'package:apkuas/features/adventure_map_screen.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:apkuas/core/providers/profile_provider.dart';
import 'package:apkuas/features/awards_screen.dart';
import 'package:apkuas/features/parents/parent_gate_screen.dart';
import 'package:apkuas/features/parents/parent_dashboard_screen.dart';
import 'package:apkuas/features/creativity/free_coloring_screen.dart';
import 'package:apkuas/features/creativity/gallery_screen.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:apkuas/core/services/gallery_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('progress');
  await GalleryService.init();

  runApp(const ProviderScope(child: CilikCodeApp()));
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
        '/level_1': (context) => LevelResolver.buildLevel(1),
        '/level_2': (context) => LevelResolver.buildLevel(2),
        '/level_3': (context) => LevelResolver.buildLevel(3),
        '/level_4': (context) => LevelResolver.buildLevel(4),
        '/level_5': (context) => LevelResolver.buildLevel(5),
        '/level_6': (context) => LevelResolver.buildLevel(6),
        '/level_7': (context) => LevelResolver.buildLevel(7),
        '/level_8': (context) => LevelResolver.buildLevel(8),
        '/level_9': (context) => LevelResolver.buildLevel(9),
        '/level_10': (context) => LevelResolver.buildLevel(10),
        '/level_11': (context) => LevelResolver.buildLevel(11),
        '/level_12': (context) => LevelResolver.buildLevel(12),
        '/level_13': (context) => LevelResolver.buildLevel(13),
        '/level_14': (context) => LevelResolver.buildLevel(14),
        '/level_15': (context) => LevelResolver.buildLevel(15),
        '/level_16': (context) => LevelResolver.buildLevel(16),
        '/level_17': (context) => LevelResolver.buildLevel(17),
        '/level_18': (context) => LevelResolver.buildLevel(18),
        '/level_19': (context) => LevelResolver.buildLevel(19),
        '/level_20': (context) => LevelResolver.buildLevel(20),
        '/level_21': (context) => LevelResolver.buildLevel(21),
        '/level_22': (context) => LevelResolver.buildLevel(22),
        '/level_23': (context) => LevelResolver.buildLevel(23),
        '/level_24': (context) => LevelResolver.buildLevel(24),
        '/level_25': (context) => LevelResolver.buildLevel(25),
        '/level_26': (context) => LevelResolver.buildLevel(26),
        '/level_27': (context) => LevelResolver.buildLevel(27),
        '/level_28': (context) => LevelResolver.buildLevel(28),
        '/level_29': (context) => LevelResolver.buildLevel(29),
        '/level_30': (context) => LevelResolver.buildLevel(30),
        '/level_31': (context) => LevelResolver.buildLevel(31),
        '/level_32': (context) => LevelResolver.buildLevel(32),
        '/level_33': (context) => LevelResolver.buildLevel(33),
        '/level_34': (context) => LevelResolver.buildLevel(34),
        '/level_35': (context) => LevelResolver.buildLevel(35),
        '/level_36': (context) => LevelResolver.buildLevel(36),
        '/level_37': (context) => LevelResolver.buildLevel(37),
        '/level_38': (context) => LevelResolver.buildLevel(38),
        '/level_39': (context) => LevelResolver.buildLevel(39),
        '/level_40': (context) => LevelResolver.buildLevel(40),
        '/level_41': (context) => LevelResolver.buildLevel(41),
        '/level_42': (context) => LevelResolver.buildLevel(42),
        '/level_43': (context) => LevelResolver.buildLevel(43),
        '/parent_gate': (context) => const ParentGateScreen(),
        '/parent_dashboard': (context) => const ParentDashboardScreen(),
        '/free_coloring': (context) => const FreeColoringScreen(),
        '/gallery': (context) => const GalleryScreen(),
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
  String? _activeFilter;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: CilikTheme.tealTua,
                          ),
                          onPressed: () {},
                        ),
                        Text(
                          'CilikCode',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
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
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.09,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Transform.rotate(
                            angle: -0.02,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
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

                          if (_activeFilter == null) ...[
                            _StylizedButton(
                              title: 'Mulai Belajar',
                              icon: Icons.play_arrow_rounded,
                              color: CilikTheme.tealTua,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => const LevelSelectionScreen(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          var scaleTween =
                                              Tween(begin: 0.8, end: 1.0).chain(
                                                CurveTween(
                                                  curve: Curves.easeOutBack,
                                                ),
                                              );
                                          var fadeTween =
                                              Tween(begin: 0.0, end: 1.0).chain(
                                                CurveTween(
                                                  curve: Curves.easeOut,
                                                ),
                                              );
                                          return FadeTransition(
                                            opacity: animation.drive(fadeTween),
                                            child: ScaleTransition(
                                              scale: animation.drive(
                                                scaleTween,
                                              ),
                                              child: child,
                                            ),
                                          );
                                        },
                                    transitionDuration: const Duration(
                                      milliseconds: 500,
                                    ),
                                  ),
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
                              onPressed: () {
                                Navigator.pushNamed(context, '/parent_gate');
                              },
                            ),
                          ] else if (_activeFilter == 'Logika Dasar') ...[
                            _buildLevelGrid(),
                          ] else if (_activeFilter == 'Kreativitas') ...[
                            _buildCreativityOptions(),
                          ],
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
                                isSelected: _activeFilter == 'Logika Dasar',
                                onTap: () => setState(
                                  () => _activeFilter =
                                      _activeFilter == 'Logika Dasar'
                                      ? null
                                      : 'Logika Dasar',
                                ),
                              ),
                              const SizedBox(width: 12),
                              _Badge(
                                label: 'Kreativitas',
                                icon: Icons.auto_awesome_rounded,
                                color: const Color(0xFFF3E5F5),
                                iconColor: Colors.teal,
                                isSelected: _activeFilter == 'Kreativitas',
                                onTap: () => setState(
                                  () => _activeFilter =
                                      _activeFilter == 'Kreativitas'
                                      ? null
                                      : 'Kreativitas',
                                ),
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

  Widget _buildLevelGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pilih Level',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _activeFilter = null),
              child: const Text('Kembali'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: 13,
          itemBuilder: (context, index) {
            int levelId = index + 1;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LevelResolver.buildLevel(levelId),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$levelId',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CilikTheme.tealTua,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreativityOptions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menu Kreativitas',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _activeFilter = null),
              child: const Text('Kembali'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StylizedButton(
          title: 'Kanvas Mewarnai Bebas',
          icon: Icons.brush_rounded,
          color: Colors.pink.shade300,
          onPressed: () => Navigator.pushNamed(context, '/free_coloring'),
        ),
        const SizedBox(height: 16),
        _StylizedButton(
          title: 'Galeri Karyaku',
          icon: Icons.collections_rounded,
          color: Colors.orange.shade400,
          onPressed: () => Navigator.pushNamed(context, '/gallery'),
        ),
      ],
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
  ConsumerState<_ProfilePopupContent> createState() =>
      _ProfilePopupContentState();
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
                  child: Text(
                    profile.avatarIcon,
                    style: const TextStyle(fontSize: 45),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${profile.totalStars} Bintang',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16,
                          ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
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
                      ref
                          .read(profileProvider.notifier)
                          .updateAvatar(avatar['emoji']!);

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
                        color: isSelected
                            ? const Color(0xFF00695C).withOpacity(0.1)
                            : Colors.grey.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00695C)
                              : Colors.transparent,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          avatar['emoji']!,
                          style: const TextStyle(fontSize: 40),
                        ),
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
          side: color == Colors.white
              ? BorderSide(color: Colors.grey.shade300, width: 2)
              : null,
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
  final bool isSelected;
  final VoidCallback onTap;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.iconColor,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.2) : color,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: iconColor, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? iconColor : Colors.blueGrey,
              ),
            ),
          ],
        ),
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
          color: isSelected
              ? CilikTheme.mintGreen.withOpacity(0.4)
              : Colors.transparent,
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
