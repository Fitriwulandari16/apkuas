import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/services/sound_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';
import 'package:apkuas/core/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

class NaturePatternRow {
  final int index;
  final List<String> sequence; // includes '?' placeholder
  final String answer;
  String? placed;

  NaturePatternRow({
    required this.index,
    required this.sequence,
    required this.answer,
  });

  bool get isSolved => placed != null;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class NaturePatternSequenceScreen extends ConsumerStatefulWidget {
  final int levelId;
  const NaturePatternSequenceScreen({super.key, this.levelId = 48});

  @override
  ConsumerState<NaturePatternSequenceScreen> createState() =>
      _NaturePatternSequenceScreenState();
}

class _NaturePatternSequenceScreenState
    extends ConsumerState<NaturePatternSequenceScreen>
    with SingleTickerProviderStateMixin {
  // Garden bloom animation controller
  late AnimationController _bloomController;

  late List<NaturePatternRow> _rows;

  // Parts Bin items — displayed with emoji + label
  final List<_NatureItem> _binItems = const [
    _NatureItem('🍃', 'Daun Hijau'),
    _NatureItem('🍂', 'Daun Kuning'),
    _NatureItem('🌸', 'Bunga Pink'),
    _NatureItem('💐', 'Bunga Biru'),
    _NatureItem('🍎', 'Apel'),
    _NatureItem('🍊', 'Jeruk'),
    _NatureItem('🍄', 'Jamur'),
    _NatureItem('🌻', 'Bunga Matahari'),
  ];

  @override
  void initState() {
    super.initState();
    _initRows();
    _bloomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void dispose() {
    _bloomController.dispose();
    super.dispose();
  }

  void _initRows() {
    _rows = [
      // Row 1: 🍃 🍂 🍃 🍂 [?] → answer: 🍃
      NaturePatternRow(
        index: 0,
        sequence: ['🍃', '🍂', '🍃', '🍂', '?'],
        answer: '🍃',
      ),
      // Row 2: 🌸 🌸 💐 🌸 🌸 [?] → answer: 💐
      NaturePatternRow(
        index: 1,
        sequence: ['🌸', '🌸', '💐', '🌸', '🌸', '?'],
        answer: '💐',
      ),
      // Row 3: 🍎 🍊 🍎 🍊 [?] → answer: 🍎
      NaturePatternRow(
        index: 2,
        sequence: ['🍎', '🍊', '🍎', '🍊', '?'],
        answer: '🍎',
      ),
      // Row 4: 🍄 🍄 🌻 🍄 🍄 [?] → answer: 🌻
      NaturePatternRow(
        index: 3,
        sequence: ['🍄', '🍄', '🌻', '🍄', '🍄', '?'],
        answer: '🌻',
      ),
    ];
  }

  void _handleDrop(int rowIndex, String droppedEmoji) {
    final row = _rows[rowIndex];
    if (row.isSolved) return;

    if (droppedEmoji == row.answer) {
      SoundService.playSuccess();
      HapticService.success();
      setState(() {
        row.placed = droppedEmoji;
      });

      if (_rows.every((r) => r.isSolved)) {
        _onLevelComplete();
      }
    } else {
      SoundService.playError();
      HapticService.failure();
      // Rejected — item snaps back naturally (Draggable cancels)
    }
  }

  void _onLevelComplete() async {
    // Play bloom animation
    _bloomController.forward();

    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    try {
      await UserService.updateProgress(48);
    } catch (e) {
      debugPrint('Cloud sync failed for level 48: $e');
    }

    if (!mounted) return;

    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 49,
      title: 'Hebat! Kamu Pintar!',
      message: 'Kamu pintar mengenali pola alam!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Soft garden sky gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildInstruction(),
              const SizedBox(height: 6),
              // Pattern rows
              Expanded(
                child: AnimatedBuilder(
                  animation: _bloomController,
                  builder: (context, child) {
                    // Subtle scale pulse on completion
                    final double scale = _bloomController.isAnimating
                        ? 1.0 + (_bloomController.value * 0.015)
                        : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ..._rows.map((row) => _buildPatternRow(row)),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              _buildPartsBin(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CilikTheme.tealTua),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 48 — Pola Alam',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CilikTheme.tealTua,
              ),
            ),
          ),
          // Progress badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_rows.where((r) => r.isSolved).length}/${_rows.length}',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Instruction ─────────────────────────────────────────────────────────

  Widget _buildInstruction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Seret gambar yang benar untuk melengkapi pola!',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pattern Row ─────────────────────────────────────────────────────────

  Widget _buildPatternRow(NaturePatternRow row) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: row.isSolved
            ? Colors.green.shade50.withOpacity(0.95)
            : Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: row.isSolved ? Colors.green.shade400 : Colors.grey.shade200,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: row.isSolved
                ? Colors.green.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row.sequence.map((item) {
          if (item == '?') {
            return _buildDropTarget(row);
          }
          return _buildStaticCell(item);
        }).toList(),
      ),
    );
  }

  Widget _buildStaticCell(String emoji) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _buildDropTarget(NaturePatternRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => !row.isSolved,
        onAcceptWithDetails: (details) => _handleDrop(row.index, details.data),
        builder: (context, candidateData, rejectedData) {
          final bool isHovering = candidateData.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: row.isSolved
                  ? Colors.green.shade100
                  : (isHovering ? Colors.green.shade50 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: row.isSolved
                    ? Colors.green.shade400
                    : (isHovering ? Colors.green : Colors.grey.shade400),
                width: isHovering ? 3 : 2,
                style: row.isSolved ? BorderStyle.solid : BorderStyle.solid,
              ),
              boxShadow: row.isSolved
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: row.isSolved
                  ? Text(row.placed!, style: const TextStyle(fontSize: 28))
                  : Text(
                      isHovering ? '✓' : '?',
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isHovering
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  // ─── Parts Bin ───────────────────────────────────────────────────────────

  Widget _buildPartsBin() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.green.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PILIHAN OBJEK  ✦  SERET KE KOTAK ?',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _binItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = _binItems[i];
                return Draggable<String>(
                  data: item.emoji,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _buildBinChip(item, scale: 1.25, isFeedback: true),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _buildBinChip(item),
                  ),
                  onDragStarted: () => HapticService.light(),
                  child: _buildBinChip(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinChip(
    _NatureItem item, {
    double scale = 1.0,
    bool isFeedback = false,
  }) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.shade200, width: 2),
          boxShadow: isFeedback
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            Text(
              item.label,
              style: GoogleFonts.fredoka(
                fontSize: 8,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper data class ────────────────────────────────────────────────────────

class _NatureItem {
  final String emoji;
  final String label;
  const _NatureItem(this.emoji, this.label);
}
