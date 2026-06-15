import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class GridBoxModel {
  final int index;
  final Color color;
  final String correctLetter;
  String currentLetter;
  bool isSolved;

  GridBoxModel({
    required this.index,
    required this.color,
    required this.correctLetter,
    this.currentLetter = '',
    this.isSolved = false,
  });
}

class GridLetterColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const GridLetterColoringScreen({super.key, this.levelId = 39});

  @override
  ConsumerState<GridLetterColoringScreen> createState() => _GridLetterColoringScreenState();
}

class _GridLetterColoringScreenState extends ConsumerState<GridLetterColoringScreen> {
  // Vibrant squircle box colors matching reference specifications
  static const Color colYellow = Color(0xFFFBBF24); // Kuning for 'a'
  static const Color colBlue = Color(0xFF60A5FA);   // Biru for 'i'
  static const Color colRed = Color(0xFFF87171);    // Merah for 'u'
  static const Color colGreen = Color(0xFF4ADE80);  // Hijau for 'e'
  static const Color colPurple = Color(0xFFC084FC); // Ungu for 'o'

  final Map<String, Color> _letterColors = {
    'a': colYellow,
    'i': colBlue,
    'u': colRed,
    'e': colGreen,
    'o': colPurple,
  };

  late List<GridBoxModel> _gridItems;
  int? _selectedBoxIndex;
  int? _shakingBoxIndex;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 5x6 Grid layout (30 boxes)
    final List<String> sequence = [
      // Row 1
      'e', 'u', 'i', 'o', 'a', 'i',
      // Row 2
      'i', 'a', 'e', 'u', 'o', 'a',
      // Row 3
      'o', 'e', 'i', 'a', 'u', 'e',
      // Row 4
      'a', 'o', 'u', 'i', 'e', 'o',
      // Row 5
      'u', 'i', 'a', 'e', 'o', 'u',
    ];

    _gridItems = List.generate(sequence.length, (i) {
      final letter = sequence[i];
      return GridBoxModel(
        index: i,
        color: _letterColors[letter]!,
        correctLetter: letter,
      );
    });
  }

  void _handleBoxTap(int index) {
    final box = _gridItems[index];
    if (box.isSolved) return;

    HapticService.light();
    setState(() {
      _selectedBoxIndex = index;
    });
  }

  void _handleKeyboardPress(String letter) {
    if (_selectedBoxIndex == null) {
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ketuk kotak warna di atas terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigoAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final boxIndex = _selectedBoxIndex!;
    final box = _gridItems[boxIndex];

    if (box.correctLetter == letter.toLowerCase()) {
      // Correct input
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        box.currentLetter = letter;
        box.isSolved = true;
        _selectedBoxIndex = null; // deselect on success
      });

      // Check level completion
      if (_gridItems.every((item) => item.isSolved)) {
        _onLevelComplete();
      }
    } else {
      // Incorrect input
      _shakeBox(boxIndex);
    }
  }

  void _shakeBox(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingBoxIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _shakingBoxIndex = null;
      });
    }
  }

  void _onLevelComplete() async {
    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(widget.levelId);
    } catch (e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    }

    if (!mounted) return;

    // 3. Show Celebration and transition to next level
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: widget.levelId + 1,
      title: 'HEBAT! KAMU PINTAR!',
      message: 'Hebat! Kamu sudah bisa mengelompokkan huruf dengan sangat baik!',
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
            _buildLegendHeader(),
            const SizedBox(height: 4),
            // Play Area (5x6 Grid of colorful squircles)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _gridItems.length,
                        itemBuilder: (context, index) {
                          final box = _gridItems[index];
                          final isSelected = _selectedBoxIndex == index;
                          final isShaking = _shakingBoxIndex == index;
                          final double shakeX = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

                          return Transform.translate(
                            offset: Offset(shakeX, 0),
                            child: GestureDetector(
                              onTap: () => _handleBoxTap(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: box.color,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? Colors.indigo.shade800 : Colors.white.withOpacity(0.4),
                                    width: isSelected ? 4.0 : 2.5,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: Colors.indigo.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      )
                                    else
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // 3D Glassmorphic gloss highlights
                                    Positioned(
                                      top: 3,
                                      left: 3,
                                      right: 3,
                                      child: Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                            bottomLeft: Radius.circular(4),
                                            bottomRight: Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Letter content
                                    Center(
                                      child: Text(
                                        box.isSolved ? box.currentLetter : box.correctLetter,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: box.isSolved 
                                              ? const Color(0xFF1E293B) 
                                              : Colors.black12, // display outline/shadow letter initially
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildVocalKeyboard(),
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
              'Level 39',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.keyboard_alt_outlined, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Ketuk kotak warna di atas lalu ketik huruf vokal yang tepat!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
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

  Widget _buildLegendHeader() {
    final List<Map<String, dynamic>> legends = [
      {'letter': 'a', 'color': colYellow},
      {'letter': 'i', 'color': colBlue},
      {'letter': 'u', 'color': colRed},
      {'letter': 'e', 'color': colGreen},
      {'letter': 'o', 'color': colPurple},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: legends.map((legend) {
          final String letter = legend['letter'] as String;
          final Color color = legend['color'] as Color;

          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVocalKeyboard() {
    final List<String> vowels = ['A', 'I', 'U', 'E', 'O'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'PAPAK KETIK HURUF VOKAL',
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: vowels.map((vowel) {
              final Color color = _letterColors[vowel.toLowerCase()]!;

              return GestureDetector(
                onTap: () => _handleKeyboardPress(vowel),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      vowel,
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
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
