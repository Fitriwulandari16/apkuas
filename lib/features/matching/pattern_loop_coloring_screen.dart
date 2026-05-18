import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class PatternLoopColoringScreen extends ConsumerStatefulWidget {
  final int levelId;
  const PatternLoopColoringScreen({super.key, this.levelId = 16});

  @override
  ConsumerState<PatternLoopColoringScreen> createState() => _PatternLoopColoringScreenState();
}

class _RowData {
  final List<Color> example; // 4 warna di 2x2 grid: TopLeft, TopRight, BottomLeft, BottomRight
  List<Color?> target;       // 4 warna pilihan anak
  bool isCompleted;

  _RowData({required this.example})
      : target = List.filled(4, null),
        isCompleted = false;
}

class _PatternLoopColoringScreenState extends ConsumerState<PatternLoopColoringScreen> {
  // 4 Warna Palette Utama
  static const Color colOrange = Color(0xFFE76F51);
  static const Color colBlue = Color(0xFF4A90E2);
  static const Color colGreen = Color(0xFF58B368);
  static const Color colYellow = Color(0xFFF5A623);

  final List<Color> _palette = [colOrange, colBlue, colGreen, colYellow];
  Color _selectedColor = colOrange; // Warna default terpilih

  late List<_RowData> _rows;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    _rows = [
      // Baris 1: Orange, Blue, Green, Yellow
      _RowData(example: [colOrange, colBlue, colGreen, colYellow]),
      // Baris 2: Blue, Green, Yellow, Orange
      _RowData(example: [colBlue, colGreen, colYellow, colOrange]),
      // Baris 3: Green, Yellow, Orange, Blue
      _RowData(example: [colGreen, colYellow, colOrange, colBlue]),
      // Baris 4: Yellow, Orange, Blue, Green
      _RowData(example: [colYellow, colOrange, colBlue, colGreen]),
    ];
  }

  void _onCellTapped(int rowIndex, int cellIndex) {
    final row = _rows[rowIndex];
    if (row.isCompleted) return;

    HapticService.light();
    setState(() {
      row.target[cellIndex] = _selectedColor;
    });

    _validateRow(rowIndex);
  }

  void _validateRow(int rowIndex) {
    final row = _rows[rowIndex];
    
    // Cek apakah 4 kotak sudah sama persis
    bool isMatch = true;
    for (int i = 0; i < 4; i++) {
      if (row.target[i] == null || row.target[i]!.value != row.example[i].value) {
        isMatch = false;
        break;
      }
    }

    if (isMatch && !row.isCompleted) {
      HapticService.success();
      // TODO: Play Sound 'Ting!'
      setState(() {
        row.isCompleted = true;
      });

      // Cek kemenangan akhir (semua baris beres)
      bool allCompleted = _rows.every((r) => r.isCompleted);
      if (allCompleted) {
        _onLevelComplete();
      }
    }
  }

  void _onLevelComplete() {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);
    
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 17,
      title: 'Hebat Pola Terpecahkan!',
      message: 'Kamu berhasil mewarnai semua pola dengan benar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            
            // Grid Tantangan (Scrollable agar muat di semua aspek rasio)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                itemCount: _rows.length,
                separatorBuilder: (context, index) => _buildDashedDivider(),
                itemBuilder: (context, index) {
                  return _buildChallengeRow(index);
                },
              ),
            ),
            
            // Palette Warna di bagian bawah
            _buildPaletteBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 16',
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.color_lens_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Lihat polanya, lalu warnai kotak yang kosong!',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeRow(int rowIndex) {
    final row = _rows[rowIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Sisi Kiri (Contoh)
          Column(
            children: [
              Text(
                'Contoh',
                style: GoogleFonts.fredoka(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildGrid2x2(
                colors: row.example,
                isInteractive: false,
                rowIndex: rowIndex,
              ),
            ],
          ),
          
          // Arrow Penunjuk
          Icon(
            Icons.arrow_forward_rounded,
            size: 32,
            color: Colors.blueGrey.shade200,
          ),
          
          // Sisi Kanan (Target / Interaktif)
          Column(
            children: [
              Text(
                'Warnai di Sini',
                style: GoogleFonts.fredoka(
                  color: row.isCompleted ? Colors.green : Colors.blue.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  _buildGrid2x2(
                    colors: row.target,
                    isInteractive: true,
                    rowIndex: rowIndex,
                  ),
                  if (row.isCompleted)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, val, child) {
                        return Transform.scale(
                          scale: val * 1.2,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid2x2({
    required List<Color?> colors,
    required bool isInteractive,
    required int rowIndex,
  }) {
    return Container(
      width: 130,
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInteractive ? Colors.blueGrey.shade100 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildCell(colors[0], isInteractive, rowIndex, 0),
                const SizedBox(width: 4),
                _buildCell(colors[1], isInteractive, rowIndex, 1),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                _buildCell(colors[2], isInteractive, rowIndex, 2),
                const SizedBox(width: 4),
                _buildCell(colors[3], isInteractive, rowIndex, 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(Color? color, bool isInteractive, int rowIndex, int cellIndex) {
    return Expanded(
      child: GestureDetector(
        onTap: isInteractive ? () => _onCellTapped(rowIndex, cellIndex) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
            boxShadow: color != null
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(20, (index) {
          return Container(
            width: 8,
            height: 2,
            color: Colors.blueGrey.shade100,
          );
        }),
      ),
    );
  }

  Widget _buildPaletteBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _palette.map((color) {
          final isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () {
              HapticService.light();
              setState(() {
                _selectedColor = color;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 65 : 55,
              height: isSelected ? 65 : 55,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 28,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
