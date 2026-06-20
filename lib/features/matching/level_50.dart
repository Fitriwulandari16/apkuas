import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class Level50Screen extends ConsumerStatefulWidget {
  const Level50Screen({super.key});

  @override
  ConsumerState<Level50Screen> createState() => _Level50ScreenState();
}

class _Level50ScreenState extends ConsumerState<Level50Screen> {
  final List<int> _gridNumbers = [];
  final List<int?> _userColors = List.generate(100, (_) => null);
  int? _selectedColorNumber;
  bool _isSolved = false;

  @visibleForTesting
  List<int> get gridNumbers => _gridNumbers;

  @visibleForTesting
  List<int?> get userColors => _userColors;

  @visibleForTesting
  int? get selectedColorNumber => _selectedColorNumber;

  @override
  void initState() {
    super.initState();
    _generateGrid();
  }

  void _generateGrid() {
    final random = Random();
    _gridNumbers.clear();
    for (int i = 0; i < 100; i++) {
      _gridNumbers.add(random.nextInt(6) + 1);
    }
    _userColors.fillRange(0, 100, null);
    _selectedColorNumber = null;
    _isSolved = false;
  }

  void _resetLevel() {
    setState(() {
      _generateGrid();
    });
  }

  Color _getColorForNumber(int num) {
    switch (num) {
      case 1:
        return const Color(0xFF4CAF50); // Hijau
      case 2:
        return const Color(0xFF2196F3); // Biru
      case 3:
        return const Color(0xFFE53935); // Merah
      case 4:
        return const Color(0xFF9C27B0); // Ungu
      case 5:
        return const Color(0xFFFFEB3B); // Kuning
      case 6:
        return const Color(0xFFFF9800); // Oranye
      default:
        return Colors.white;
    }
  }

  void _handleCellTap(int index) {
    if (_isSolved) return;
    if (_userColors[index] != null) return; // Already colored

    if (_selectedColorNumber == null) {
      // Play alert/vibration to indicate no color selected
      HapticFeedback.lightImpact();
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih warna terlebih dahulu di palet bawah!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final int cellNum = _gridNumbers[index];
    if (_selectedColorNumber == cellNum) {
      // Correct color selected
      HapticFeedback.lightImpact();
      SoundService.playSuccess();
      setState(() {
        _userColors[index] = cellNum;
        if (_userColors.every((val) => val != null)) {
          gameWin();
        }
      });
    } else {
      // Incorrect color selected
      HapticFeedback.lightImpact();
      SoundService.playError();
    }
  }

  void gameWin() {
    _onLevelComplete();
  }

  void _onLevelComplete() async {
    setState(() {
      _isSolved = true;
    });

    ref.read(progressProvider.notifier).completeLevel(50);

    try {
      await UserService.updateProgress(50);
    } catch (e) {
      debugPrint('Cloud sync failed for level 50: $e');
    }

    if (!mounted) return;

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 51,
      title: 'TANTANGAN SELESAI! 🎉',
      message: 'Luar biasa! Kamu berhasil menamatkan petualangan Level 50!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 8),
            // Main Grid View area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 3.0),
                  ),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: GridView.builder(
                        key: const ValueKey('level50_grid'),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 10,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: 100,
                        itemBuilder: (context, index) {
                          final number = _gridNumbers[index];
                          final coloredNum = _userColors[index];
                          final bool isColored = coloredNum != null;
                          final Color cellColor = isColored ? _getColorForNumber(coloredNum) : Colors.white;
                          final Color textColor = isColored 
                              ? (coloredNum == 5 ? Colors.black87 : Colors.white) 
                              : Colors.grey.shade700;

                          return GestureDetector(
                            key: ValueKey('grid_cell_$index'),
                            onTap: () => _handleCellTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isColored ? cellColor.withOpacity(0.8) : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: isColored ? [
                                  BoxShadow(
                                    color: cellColor.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ] : [],
                              ),
                              child: Center(
                                child: Text(
                                  '$number',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Color Picker Palette at the bottom
            _buildInteractivePalette(),
            const SizedBox(height: 12),
            // Reset button at the bottom center
            Center(
              child: TextButton.icon(
                onPressed: _resetLevel,
                icon: const Icon(Icons.refresh_rounded, color: Colors.orange, size: 22),
                label: const Text(
                  'Ulangi',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 50',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CilikTheme.tealTua,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.color_lens_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Pilih warna di palet bawah dulu, lalu warnai kotak angka yang cocok!',
              style: GoogleFonts.fredoka(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractivePalette() {
    final List<Map<String, dynamic>> legendItems = [
      {'num': 1, 'name': 'Hijau', 'color': const Color(0xFF4CAF50)},
      {'num': 2, 'name': 'Biru', 'color': const Color(0xFF2196F3)},
      {'num': 3, 'name': 'Merah', 'color': const Color(0xFFE53935)},
      {'num': 4, 'name': 'Ungu', 'color': const Color(0xFF9C27B0)},
      {'num': 5, 'name': 'Kuning', 'color': const Color(0xFFFFEB3B)},
      {'num': 6, 'name': 'Oranye', 'color': const Color(0xFFFF9800)},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'PALET PILIHAN WARNA',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: legendItems.map((item) {
              final int num = item['num'] as int;
              final Color color = item['color'] as Color;
              final String name = item['name'] as String;
              final bool isSelected = _selectedColorNumber == num;
              final bool isYellow = num == 5;

              return GestureDetector(
                key: ValueKey('palette_color_$num'),
                onTap: () {
                  setState(() {
                    _selectedColorNumber = num;
                  });
                  HapticFeedback.lightImpact();
                },
                child: AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black87, width: 3.0)
                              : Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? Colors.black26 : color.withOpacity(0.3),
                              blurRadius: isSelected ? 6 : 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$num',
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isYellow ? Colors.black87 : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: GoogleFonts.fredoka(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}