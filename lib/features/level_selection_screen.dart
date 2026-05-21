import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/providers/profile_provider.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
import 'package:apkuas/core/widgets/responsive_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelSelectionScreen extends ConsumerStatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  ConsumerState<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen> with SingleTickerProviderStateMixin {
  String _activeTab = 'Logika Dasar';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    
    return ResponsiveWrapper(
      backgroundColor: const Color(0xFFF0F4F8),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header Informasi
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: CilikTheme.tealTua),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Mulai Belajar',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orange, size: 24),
                          const SizedBox(width: 6),
                          Text(
                            '${profile.totalStars}',
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Kategori Tab
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('Logika Dasar', Icons.extension_rounded, Colors.blue),
                      _buildTabButton('Kreativitas', Icons.palette_rounded, Colors.pink),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Content Area
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _activeTab == 'Logika Dasar' 
                      ? _buildLogikaDasarTab() 
                      : _buildKreativitasTab(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, Color activeColor) {
    bool isSelected = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? activeColor : Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogikaDasarTab() {
    final highestLevel = ref.watch(progressProvider);
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        final int levelId = index + 1;
        final bool isCompleted = levelId < highestLevel;
        final bool isActive = levelId == highestLevel;
        final bool isLocked = levelId > highestLevel;
        
        return GestureDetector(
          onTap: isLocked ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LevelResolver.buildLevel(levelId)),
            );
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              double scale = isActive ? 1.0 + (_pulseController.value * 0.05) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey.shade300 : (isCompleted ? CilikTheme.mintGreen : Colors.orange),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isLocked ? Colors.grey : (isCompleted ? Colors.green : Colors.orange)).withOpacity(0.3),
                        blurRadius: isActive ? 15 : 5,
                        spreadRadius: isActive ? 2 : 0,
                        offset: const Offset(0, 5),
                      )
                    ],
                    border: isActive ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$levelId',
                        style: GoogleFonts.fredoka(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isLocked ? Colors.grey.shade500 : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLocked ? Icons.lock_rounded : (isCompleted ? Icons.star_rounded : Icons.play_arrow_rounded),
                          color: isLocked ? Colors.grey : (isCompleted ? Colors.orange : Colors.orange),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildKreativitasTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildCreativityCard(
          title: 'Kanvas Bebas',
          subtitle: 'Ayo menggambar sesukamu!',
          icon: Icons.brush_rounded,
          color: Colors.pink.shade300,
          onTap: () => Navigator.pushNamed(context, '/free_coloring'),
        ),
        const SizedBox(height: 20),
        _buildCreativityCard(
          title: 'Galeri Karyaku',
          subtitle: 'Lihat semua hasil gambarmu!',
          icon: Icons.collections_rounded,
          color: Colors.orange.shade400,
          onTap: () => Navigator.pushNamed(context, '/gallery'),
        ),
      ],
    );
  }

  Widget _buildCreativityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 36),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
