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
import 'package:shared_preferences/shared_preferences.dart';

class DebuggingRowModel {
  final int index;
  final List<String> initialColors;
  final List<String> targetColors;
  final int errorIndex;
  bool isIdentified;
  bool isCorrected;
  bool showError;

  DebuggingRowModel({
    required this.index,
    required this.initialColors,
    required this.targetColors,
    required this.errorIndex,
    this.isIdentified = false,
    this.isCorrected = false,
    this.showError = false,
  });
}

class PatternDebuggingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const PatternDebuggingScreen({super.key, this.levelId = 44});

  @override
  ConsumerState<PatternDebuggingScreen> createState() => _PatternDebuggingScreenState();
}

class _PatternDebuggingScreenState extends ConsumerState<PatternDebuggingScreen>
    with SingleTickerProviderStateMixin {
  // Master colors for visual conversion
  static const Color colBlue = Color(0xFF38BDF8);   // Biru Muda
  static const Color colYellow = Color(0xFFFACC15); // Kuning
  static const Color colPink = Color(0xFFF472B6);   // Pink

  late List<DebuggingRowModel> _rows;
  int? _shakingArrowIndex; // Encodes row*10 + col index to identify shaking arrow
  bool _isSolved = false;

  @visibleForTesting
  List<DebuggingRowModel> get dots => _rows;

  // Proper shake animation controller (prevents main-thread blocking)
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakingArrowIndex = null;
    _isSolved = false;

    // Initialize shake animation (short, finite duration)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _shakingArrowIndex = null;
        });
        _shakeController.reset();
      }
    });

    _initLevel();
    _clearCache();
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.contains('level_44') || key.contains('pattern_debugging') || key.contains('arrow_colors')) {
          await prefs.remove(key);
          debugPrint('PatternDebuggingScreen: Cleared SharedPreferences cache key: $key');
        }
      }
    } catch (e) {
      debugPrint('PatternDebuggingScreen: Error clearing SharedPreferences cache: $e');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _initLevel() {
    const List<String> masterPattern = ['blue', 'blue', 'yellow', 'yellow', 'pink', 'pink'];

    _rows = [
      // Row 1: Blue, Blue, Yellow, Yellow, Pink, [Blue - ERROR]
      DebuggingRowModel(
        index: 0,
        initialColors: ['blue', 'blue', 'yellow', 'yellow', 'pink', 'blue'],
        targetColors: List.from(masterPattern),
        errorIndex: 5,
        isIdentified: true,
        isCorrected: false,
        showError: true,
      ),
      // Row 2: Blue, Blue, [Pink - ERROR], Yellow, Pink, Pink
      DebuggingRowModel(
        index: 1,
        initialColors: ['blue', 'blue', 'pink', 'yellow', 'pink', 'pink'],
        targetColors: List.from(masterPattern),
        errorIndex: 2,
        isIdentified: true,
        isCorrected: false,
        showError: true,
      ),
      // Row 3: Blue, [Yellow - ERROR], Yellow, Yellow, Pink, Pink
      DebuggingRowModel(
        index: 2,
        initialColors: ['blue', 'yellow', 'yellow', 'yellow', 'pink', 'pink'],
        targetColors: List.from(masterPattern),
        errorIndex: 1,
        isIdentified: true,
        isCorrected: false,
        showError: true,
      ),
      // Row 4: Blue, Blue, Yellow, [Pink - ERROR], Pink, Pink
      DebuggingRowModel(
        index: 3,
        initialColors: ['blue', 'blue', 'yellow', 'pink', 'pink', 'pink'],
        targetColors: List.from(masterPattern),
        errorIndex: 3,
        isIdentified: true,
        isCorrected: false,
        showError: true,
      ),
    ];
  }

  Color _getColorFromString(String name) {
    switch (name) {
      case 'blue':
        return colBlue;
      case 'yellow':
        return colYellow;
      case 'pink':
        return colPink;
      default:
        return Colors.grey;
    }
  }

  String _getNextColorInCycle(String currentColor) {
    switch (currentColor) {
      case 'blue':
        return 'yellow';
      case 'yellow':
        return 'pink';
      case 'pink':
        return 'blue';
      default:
        return 'blue';
    }
  }

  void _handleArrowTap(int rowIndex, int colIndex) {
    if (_isSolved) return;

    // Bounds validation to prevent RangeError
    if (rowIndex < 0 || rowIndex >= _rows.length) return;
    if (colIndex < 0 || colIndex >= 6) return;

    final row = _rows[rowIndex];

    // Only allow tapping the error arrow to change its color if it's not yet corrected
    if (colIndex == row.errorIndex) {
      if (row.isCorrected) return;

      final currentColorName = row.initialColors[colIndex];
      final nextColorName = _getNextColorInCycle(currentColorName);

      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        row.initialColors[colIndex] = nextColorName;
      });

      // Run validation automatically after color change
      periksaKecocokanLevel44(row);
    } else {
      // Tapping other correct arrows triggers a shake warning
      _shakeArrow(rowIndex, colIndex);
    }
  }

  void _shakeArrow(int rowIndex, int colIndex) {
    SoundService.playError();
    HapticService.failure();

    if (!mounted) return;
    setState(() {
      _shakingArrowIndex = rowIndex * 10 + colIndex;
    });

    // AnimationController drives the shake; its statusListener
    // (in initState) resets _shakingArrowIndex when complete.
    _shakeController.forward(from: 0.0);
  }

  bool cekBarisCocok(List<String> warnaBaris, List<String> warnaMaster) {
    if (warnaBaris.length != warnaMaster.length) return false;
    for (int i = 0; i < warnaBaris.length; i++) {
      if (warnaBaris[i] != warnaMaster[i]) {
        return false; // Ada yang beda, berarti masih eror
      }
    }
    return true; // Cocok sempurna!
  }

  void gameWin() {
    _onLevelComplete();
  }

  void periksaKecocokanLevel44(DebuggingRowModel row) {
    if (cekBarisCocok(row.initialColors, row.targetColors)) {
      // Correct color cycle selection!
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        row.isCorrected = true;
        row.showError = false;
      });

      // Check level completion
      if (_rows.every((r) => r.isCorrected)) {
        gameWin();
      }
    } else {
      // Keep showing error indicator if still wrong
      setState(() {
        row.showError = true;
      });
    }
  }

  void _onLevelComplete() async {
    if (!mounted) return;
    setState(() {
      _isSolved = true;
    });

    // Clear SharedPreferences keys associated with Level 44 progress
    await _clearCache();

    // 1. Mark complete locally in provider
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    // 2. Sync to cloud database
    try {
      await UserService.updateProgress(widget.levelId);
    } catch (e) {
      debugPrint('Cloud progress update failed for level ${widget.levelId}: $e');
    }

    if (!mounted) return;

    // 3. Show success victory dialog
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: widget.levelId + 1,
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
            _buildMasterPatternHeader(),
            const SizedBox(height: 4),
            // Play Area (Debugging rows)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 4.0),
                  ),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _rows.length,
                    itemBuilder: (context, rowIndex) {
                      if (rowIndex < 0 || rowIndex >= _rows.length) {
                        return const SizedBox.shrink();
                      }
                      final row = _rows[rowIndex];
                      return _buildChallengeRow(row, rowIndex);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildPartsBin(),
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
            onPressed: () async {
              await _clearCache();
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
          Expanded(
            child: Text(
              'Level 44',
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
          const Icon(Icons.bug_report_rounded, color: Colors.indigo, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Temukan warna panah yang salah (ketuk silang), lalu perbaiki!',
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

  Widget _buildMasterPatternHeader() {
    const List<String> masterPattern = ['blue', 'blue', 'yellow', 'yellow', 'pink', 'pink'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.shade100, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'POLA BENAR (PANDUAN MASTER)',
            style: GoogleFonts.fredoka(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final double arrowW = min(constraints.maxWidth / 6.5, 48.0);
              final double arrowH = arrowW * 0.6;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: masterPattern.map((colorName) {
                  return SizedBox(
                    width: arrowW,
                    height: arrowH,
                    child: MasterArrowWidget(color: _getColorFromString(colorName)),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeRow(DebuggingRowModel row, int rowIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: row.isCorrected ? Colors.green.shade200 : const Color(0xFFE2E8F0),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Baris ${rowIndex + 1}',
                style: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              if (row.isCorrected)
                const Icon(Icons.check_circle, color: Colors.green, size: 18)
              else if (row.showError)
                Text(
                  'Perbaiki eror!',
                  style: GoogleFonts.fredoka(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final double arrowW = min(constraints.maxWidth / 6.5, 46.0);
              final double arrowH = arrowW * 0.6;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (colIndex) {
                  // Bounds safety check
                  if (colIndex >= row.initialColors.length) {
                    return const SizedBox.shrink();
                  }

                  final isErrorIndex = colIndex == row.errorIndex;
                  final isShaking = _shakingArrowIndex == (rowIndex * 10 + colIndex);

                  String colorName = row.initialColors[colIndex];
                  if (isErrorIndex && row.isCorrected && colIndex < row.targetColors.length) {
                    colorName = row.targetColors[colIndex]; // show corrected color
                  }
                  Color arrowColor = _getColorFromString(colorName);

                  // Build the base arrow widget
                  final baseArrow = SizedBox(
                     width: arrowW,
                     height: arrowH,
                     child: MasterArrowWidget(
                       color: arrowColor,
                       isXOverlay: isErrorIndex && row.showError && !row.isCorrected,
                       isCorrected: isErrorIndex && row.isCorrected,
                     ),
                  );

                  // Gesture detector for tap identification and cycling
                  final tappableWidget = GestureDetector(
                    onTap: () => _handleArrowTap(rowIndex, colIndex),
                    child: baseArrow,
                  );

                  // Only wrap with AnimatedBuilder for the shaking arrow
                  if (!isShaking) return tappableWidget;

                  return AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      final double shakeX = _shakeAnimation.value *
                          sin(2 * pi * (_shakeController.value * 4));
                      return Transform.translate(
                        offset: Offset(shakeX, 0),
                        child: child,
                      );
                    },
                    child: tappableWidget,
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartsBin() {
    const List<String> colors = ['blue', 'yellow', 'pink'];
    final Map<String, String> colorNames = {
      'blue': 'Biru Muda',
      'yellow': 'Kuning',
      'pink': 'Pink',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(14.0),
      height: 126,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PANDUAN WARNA (KETUK PANAH SILANG UNTUK MENGUBAH WARNA)',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colors.map((colorName) {
                final displayColor = _getColorFromString(colorName);
                return _buildDraggableArrow(displayColor, colorNames[colorName]!);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableArrow(Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 28,
          child: MasterArrowWidget(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class MasterArrowWidget extends StatelessWidget {
  final Color color;
  final bool isXOverlay;
  final bool isCorrected;

  const MasterArrowWidget({
    super.key,
    required this.color,
    this.isXOverlay = false,
    this.isCorrected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrected ? Colors.green : const Color(0xFF334155),
          width: isCorrected ? 3.0 : 2.0,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 20,
          ),
          if (isXOverlay)
            const Icon(
              Icons.close_rounded,
              color: Colors.red,
              size: 20,
            ),
        ],
      ),
    );
  }
}
