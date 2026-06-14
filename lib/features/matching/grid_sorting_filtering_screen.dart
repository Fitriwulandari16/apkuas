import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:apkuas/core/utils/level_resolver.dart';
import 'package:google_fonts/google_fonts.dart';

class GridCell {
  final int index;
  final String letter;
  Color? currentColor;
  bool isCorrect;

  GridCell({
    required this.index,
    required this.letter,
    this.currentColor,
    this.isCorrect = false,
  });
}

class GridSortingFilteringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const GridSortingFilteringScreen({super.key, this.levelId = 34});

  @override
  ConsumerState<GridSortingFilteringScreen> createState() => _GridSortingFilteringScreenState();
}

class _GridSortingFilteringScreenState extends ConsumerState<GridSortingFilteringScreen> {
  static const Color colGreen = Color(0xFF4CAF50);  // Green for 'u'
  static const Color colYellow = Color(0xFFFDD835); // Yellow for 'n'

  Color? _selectedColor;
  late List<GridCell> _cells;

  // For shake effect on incorrect taps
  int? _shakingIndex;

  @override
  void initState() {
    super.initState();
    _initGrid();
  }

  void _initGrid() {
    // 5x5 grid layout matching the textbook image:
    // Row 1: u, n, n, u, n
    // Row 2: n, u, n, u, n
    // Row 3: u, n, u, n, u
    // Row 4: n, u, n, u, n
    // Row 5: u, n, u, n, u
    final List<String> letters = [
      'u', 'n', 'n', 'u', 'n',
      'n', 'u', 'n', 'u', 'n',
      'u', 'n', 'u', 'n', 'u',
      'n', 'u', 'n', 'u', 'n',
      'u', 'n', 'u', 'n', 'u',
    ];

    _cells = List.generate(letters.length, (i) {
      return GridCell(
        index: i,
        letter: letters[i],
      );
    });
  }

  Color _getRequiredColor(String letter) {
    return letter == 'u' ? colGreen : colYellow;
  }

  void _handleCellTap(int index) {
    final cell = _cells[index];
    if (cell.isCorrect) return; // Already correctly solved

    if (_selectedColor == null) {
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih warna Hijau atau Kuning di bawah terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final targetColor = _getRequiredColor(cell.letter);

    if (_selectedColor == targetColor) {
      // Correct color filled!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        cell.currentColor = _selectedColor;
        cell.isCorrect = true;
      });

      // Check level completion
      if (_cells.every((c) => c.isCorrect)) {
        _onLevelComplete();
      }
    } else {
      // Wrong color chosen for this letter
      _shakeCell(index);
    }
  }

  void _shakeCell(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _shakingIndex = null;
      });
    }
  }

  void _onLevelComplete() async {
    // 1. Catat penyelesaian level di Riverpod provider lokal
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync progress ke Hive/Firebase dengan levelId dinamis (bukan hardcoded)
    try {
      await UserService.updateProgress(widget.levelId);
    } catch (e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    }

    if (!mounted) return;

    // 3. Tampilkan dialog kemenangan standar → lanjut ke level berikutnya
    //    Level 34 BUKAN level terakhir (game berlanjut sampai Level 50).
    //    _showFinalVictoryDialog() yang lama sudah dihapus karena salah.
    _showNextLevelDialog();
  }

  /// Dialog kemenangan standar: menampilkan confetti dan navigasi ke level berikutnya.
  /// Digunakan untuk semua level yang BUKAN level terakhir (Level 50).
  void _showNextLevelDialog() {
    final int nextLevel = widget.levelId + 1;
    // Batas aman: tidak boleh melampaui level 50
    final bool isActuallyLastLevel = widget.levelId >= 50;

    // Siapkan ConfettiController untuk hujan warna-warni
    final confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    confettiController.play();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'LevelWin',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        final curvedValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Stack(
            children: [
              // ── Hujan Confetti ──────────────────────────────────────────
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirection: pi / 2, // ke bawah
                  maxBlastForce: 6,
                  minBlastForce: 2,
                  emissionFrequency: 0.06,
                  numberOfParticles: 30,
                  gravity: 0.25,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                    Colors.yellow,
                  ],
                ),
              ),
              // ── Dialog Card ─────────────────────────────────────────────
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: isActuallyLastLevel
                          ? const Color(0xFFFFD54F)
                          : CilikTheme.tealTua,
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ikon bintang
                        Icon(
                          isActuallyLastLevel
                              ? Icons.emoji_events_rounded
                              : Icons.star_rounded,
                          color: const Color(0xFFFFD54F),
                          size: 90,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isActuallyLastLevel
                              ? 'HORE! KAMU LULUS!'
                              : 'LEVEL ${widget.levelId} SELESAI! 🎉',
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: CilikTheme.tealTua,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isActuallyLastLevel
                              ? 'Kamu sudah menyelesaikan semua level!'
                              : 'Siap untuk Level $nextLevel?',
                          style: GoogleFonts.fredoka(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // ── Tombol Aksi ─────────────────────────────────
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActuallyLastLevel
                                ? const Color(0xFFFFD54F)
                                : CilikTheme.tealTua,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            confettiController.stop();
                            confettiController.dispose();
                            Navigator.pop(dialogContext); // tutup dialog
                            if (isActuallyLastLevel) {
                              // Kembali ke peta untuk level terakhir
                              Navigator.pop(context);
                            } else {
                              // Ganti halaman saat ini dengan level berikutnya
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LevelResolver.buildLevel(nextLevel),
                                ),
                              );
                            }
                          },
                          child: Text(
                            isActuallyLastLevel ? 'SELESAI' : 'LANJUT ▶',
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkillRow(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ],
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
            _buildLegendCode(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _cells.length,
                    itemBuilder: (context, index) {
                      final cell = _cells[index];
                      final isShaking = _shakingIndex == index;
                      final double shakeX = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

                      return Transform.translate(
                        offset: Offset(shakeX, 0),
                        child: GestureDetector(
                          onTap: () => _handleCellTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: cell.currentColor ?? const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cell.isCorrect 
                                    ? cell.currentColor!.withOpacity(0.8) 
                                    : const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                              boxShadow: [
                                if (cell.isCorrect)
                                  BoxShadow(
                                    color: cell.currentColor!.withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                cell.letter,
                                style: GoogleFonts.fredoka(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: cell.isCorrect ? Colors.white : Colors.black87,
                                ),
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
            _buildPalette(),
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
              'Level 34',
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

  Widget _buildLegendCode() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Duck cartoon emoji indicator
          const Text('🦆', style: TextStyle(fontSize: 34)),
          _buildLegendItem('u', colGreen, 'Hijau'),
          Container(height: 24, width: 2, color: Colors.grey.shade200),
          _buildLegendItem('n', colYellow, 'Kuning'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String letter, Color color, String colorName) {
    return Row(
      children: [
        Text(
          letter,
          style: GoogleFonts.fredoka(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: const Center(
            child: Icon(Icons.check, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildPalette() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [colGreen, colYellow].map((color) {
          final isSelected = _selectedColor == color;
          String colorText = color == colGreen ? 'Hijau' : 'Kuning';

          return GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() {
                _selectedColor = color;
              });
            },
            child: AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
                        width: isSelected ? 3.5 : 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.format_paint_rounded,
                        color: isSelected && color == colYellow ? Colors.black87 : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    colorText,
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color == colYellow ? Colors.orange : color,
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
