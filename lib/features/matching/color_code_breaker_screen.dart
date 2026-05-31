import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeBreakerRow {
  final int index;
  final List<int> correctNumbers;
  final List<Color> bubbleColors;
  List<int?> currentNumbers;
  bool isSolved;

  CodeBreakerRow({
    required this.index,
    required this.correctNumbers,
    required this.bubbleColors,
    List<int?>? currentNumbers,
    this.isSolved = false,
  }) : currentNumbers = currentNumbers ?? [null, null, null, null];
}

class ColorCodeBreakerScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ColorCodeBreakerScreen({super.key, this.levelId = 41});

  @override
  ConsumerState<ColorCodeBreakerScreen> createState() => _ColorCodeBreakerScreenState();
}

class _ColorCodeBreakerScreenState extends ConsumerState<ColorCodeBreakerScreen> {
  // 4 main glossy bubble colors from reference key
  static const Color colMint = Color(0xFF4FD1C5);   // 1 = Hijau Muda/Toska
  static const Color colOrange = Color(0xFFFB923C); // 2 = Oranye
  static const Color colIndigo = Color(0xFF818CF8); // 3 = Ungu/Biru Tua
  static const Color colYellow = Color(0xFFFDE047); // 4 = Kuning

  late List<CodeBreakerRow> _challenges;
  int? _selectedRowIndex;
  int? _shakingRowIndex;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    // 6 rows matching exactly page 21 workbook challenges
    _challenges = [
      // Row 1: Orange, Green, Purple, Yellow -> 2, 1, 3, 4
      CodeBreakerRow(
        index: 0,
        bubbleColors: [colOrange, colMint, colIndigo, colYellow],
        correctNumbers: [2, 1, 3, 4],
      ),
      // Row 2: Yellow, Purple, Orange, Green -> 4, 3, 2, 1
      CodeBreakerRow(
        index: 1,
        bubbleColors: [colYellow, colIndigo, colOrange, colMint],
        correctNumbers: [4, 3, 2, 1],
      ),
      // Row 3: Orange, Green, Purple, Green -> 2, 1, 3, 1
      CodeBreakerRow(
        index: 2,
        bubbleColors: [colOrange, colMint, colIndigo, colMint],
        correctNumbers: [2, 1, 3, 1],
      ),
      // Row 4: Purple, Yellow, Purple, Yellow -> 3, 4, 3, 4
      CodeBreakerRow(
        index: 3,
        bubbleColors: [colIndigo, colYellow, colIndigo, colYellow],
        correctNumbers: [3, 4, 3, 4],
      ),
      // Row 5: Yellow, Yellow, Green, Purple -> 4, 4, 1, 3
      CodeBreakerRow(
        index: 4,
        bubbleColors: [colYellow, colYellow, colMint, colIndigo],
        correctNumbers: [4, 4, 1, 3],
      ),
      // Row 6: Green, Orange, Orange, Yellow -> 1, 2, 2, 4
      CodeBreakerRow(
        index: 5,
        bubbleColors: [colMint, colOrange, colOrange, colYellow],
        correctNumbers: [1, 2, 2, 4],
      ),
    ];

    // Automatically select the first unsolved row
    _selectedRowIndex = 0;
  }

  void _handleRowTap(int index) {
    final row = _challenges[index];
    if (row.isSolved) return;

    HapticService.light();
    setState(() {
      _selectedRowIndex = index;
    });
  }

  void _handleNumberPress(int number) {
    if (_selectedRowIndex == null) {
      HapticService.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pilih baris gelembung di atas terlebih dahulu!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigoAccent,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final rowIndex = _selectedRowIndex!;
    final row = _challenges[rowIndex];

    // Find the first empty slot in the selected row
    final emptyIndex = row.currentNumbers.indexOf(null);
    if (emptyIndex == -1) return; // already full

    HapticService.light();
    setState(() {
      row.currentNumbers[emptyIndex] = number;
    });

    // Check if we just filled the 4th slot
    if (!row.currentNumbers.contains(null)) {
      _validateRow(rowIndex);
    }
  }

  void _validateRow(int index) async {
    final row = _challenges[index];
    
    // Compare inputs with answers
    bool isCorrect = true;
    for (int i = 0; i < 4; i++) {
      if (row.currentNumbers[i] != row.correctNumbers[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      // Row Solved!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        row.isSolved = true;
        // Auto-select the next unsolved row
        _selectedRowIndex = _challenges.indexWhere((r) => !r.isSolved);
        if (_selectedRowIndex == -1) {
          _selectedRowIndex = null; // all solved
        }
      });

      // Check level completion
      if (_challenges.every((r) => r.isSolved)) {
        _onLevelComplete();
      }
    } else {
      // Incorrect code input
      _shakeRow(index);
    }
  }

  void _shakeRow(int index) async {
    SoundService.playError();
    HapticService.failure();

    setState(() {
      _shakingRowIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _shakingRowIndex = null;
        _challenges[index].currentNumbers = [null, null, null, null]; // reset row input on failure
      });
    }
  }

  void _onLevelComplete() async {
    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(41);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 41: $e');
    }

    if (!mounted) return;

    // 3. Show success victory dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'CodeBreakerSuccess',
      transitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scaleValue = Curves.elasticOut.transform(anim1.value);
        return Transform.scale(
          scale: scaleValue,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.amber, width: 6),
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
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 110,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LUAR BIASA!',
                      style: GoogleFonts.fredoka(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CilikTheme.tealTua,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Luar Biasa! Kamu ahli dalam memecahkan kode warna!',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        // Return back to Adventure Map
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context); // close level 41 screen
                      },
                      child: Text(
                        'SELESAI',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
            const SizedBox(height: 8),
            // Play Area (6 rows of challenge list)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _challenges.length,
                    itemBuilder: (context, idx) {
                      final row = _challenges[idx];
                      final isSelected = _selectedRowIndex == idx;
                      final isShaking = _shakingRowIndex == idx;
                      final double shakeX = isShaking ? 6.0 * sin(2 * pi * DateTime.now().millisecond / 100) : 0.0;

                      return Transform.translate(
                        offset: Offset(shakeX, 0),
                        child: GestureDetector(
                          onTap: () => _handleRowTap(idx),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.indigo.shade300 
                                    : (row.isSolved ? Colors.green.withOpacity(0.2) : Colors.transparent),
                                width: 2.0,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Sisi Kiri: 4 colored glossy bubbles
                                Row(
                                  children: row.bubbleColors.map((color) => _buildGlossyBubble(color)).toList(),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 18),
                                const Spacer(),
                                // Sisi Kanan: 4 large number inputs
                                Row(
                                  children: List.generate(4, (slotIdx) {
                                    final numberVal = row.currentNumbers[slotIdx];
                                    final isSlotFocused = isSelected && row.currentNumbers.indexOf(null) == slotIdx;

                                    return _buildNumberInputBox(numberVal, row.isSolved, isSlotFocused);
                                  }),
                                ),
                                const SizedBox(width: 8),
                                // Solved checkmark
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: row.isSolved ? const Color(0xFF4CAF50) : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: row.isSolved 
                                        ? null 
                                        : Border.all(color: Colors.grey.shade300, width: 2.0),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: row.isSolved ? Colors.white : Colors.transparent,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildNumberPad(),
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
              'Level 41',
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
          const Icon(Icons.password_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Ketikkan angka sesuai warna gelembung di sebelah kiri!',
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
      {'num': 1, 'color': colMint},
      {'num': 2, 'color': colOrange},
      {'num': 3, 'color': colIndigo},
      {'num': 4, 'color': colYellow},
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
          final int numVal = legend['num'] as int;
          final Color color = legend['color'] as Color;

          return Row(
            children: [
              _buildGlossyBubble(color, size: 36),
              const SizedBox(width: 8),
              Text(
                '=',
                style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$numVal',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlossyBubble(Color color, {double size = 40}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.55), color],
            center: const Alignment(-0.35, -0.35),
            radius: 0.85,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // White premium gloss reflection overlay
            Positioned(
              top: size * 0.12,
              left: size * 0.12,
              child: Container(
                width: size * 0.32,
                height: size * 0.18,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(size * 0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInputBox(int? value, bool isSolved, bool isFocused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isSolved ? const Color(0xFFE2F0D9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused 
              ? Colors.indigo 
              : (isSolved ? const Color(0xFF4CAF50) : Colors.grey.shade300),
          width: isFocused ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: Colors.indigo.withOpacity(0.2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Center(
        child: Text(
          value != null ? '$value' : '',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isSolved ? const Color(0xFF385723) : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    final List<int> numbers = [1, 2, 3, 4];

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
            'PAPAK KETIK ANGKA',
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: numbers.map((numVal) {
              // Retrieve matching bubble color for key styling consistency
              final Color color = numVal == 1
                  ? colMint
                  : (numVal == 2 ? colOrange : (numVal == 3 ? colIndigo : colYellow));

              return GestureDetector(
                onTap: () => _handleNumberPress(numVal),
                child: Container(
                  width: 56,
                  height: 56,
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
                      '$numVal',
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color.withOpacity(0.95),
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
