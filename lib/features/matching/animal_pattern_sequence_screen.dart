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

class AnimalPatternRow {
  final int index;
  final List<String> sequence; // emoji sequence shown to child (includes '?')
  final String answer;         // correct emoji answer

  AnimalPatternRow({
    required this.index,
    required this.sequence,
    required this.answer,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AnimalPatternSequenceScreen extends ConsumerStatefulWidget {
  final int levelId;
  const AnimalPatternSequenceScreen({super.key, this.levelId = 28});

  @override
  ConsumerState<AnimalPatternSequenceScreen> createState() =>
      _AnimalPatternSequenceScreenState();
}

class _AnimalPatternSequenceScreenState
    extends ConsumerState<AnimalPatternSequenceScreen> {

  // Answers placed by the child keyed by row index
  final Map<int, String?> _placedAnswers = {0: null, 1: null, 2: null, 3: null};

  // 4 pattern rows matching the workbook
  final List<AnimalPatternRow> _rows = [
    AnimalPatternRow(
      index: 0,
      sequence: ['🐘', '🦒', '🐘', '🦒', '?'],
      answer: '🐘',
    ),
    AnimalPatternRow(
      index: 1,
      sequence: ['🦁', '🦓', '🦁', '🦓', '?'],
      answer: '🦁',
    ),
    AnimalPatternRow(
      index: 2,
      sequence: ['🐒', '🐒', '🐍', '🐒', '🐒', '?'],
      answer: '🐍',
    ),
    AnimalPatternRow(
      index: 3,
      sequence: ['🐯', '🦅', '🦅', '🐯', '🦅', '?'],
      answer: '🦅',
    ),
  ];

  // All unique animals used as draggable options in the Parts Bin
  final List<String> _allAnimals = ['🐘', '🦒', '🦁', '🦓', '🐒', '🐍', '🐯', '🦅'];

  void _handleDrop(int rowIndex, String droppedEmoji) {
    final correctAnswer = _rows[rowIndex].answer;

    if (droppedEmoji == correctAnswer) {
      SoundService.playSuccess();
      HapticService.success();

      setState(() {
        _placedAnswers[rowIndex] = droppedEmoji;
      });

      // Check level complete
      if (_placedAnswers.values.every((a) => a != null)) {
        _onLevelComplete();
      }
    } else {
      SoundService.playError();
      HapticService.failure();
    }
  }

  void _onLevelComplete() async {
    ref.read(progressProvider.notifier).completeLevel(widget.levelId);

    try {
      await UserService.updateProgress(28);
    } catch (e) {
      debugPrint('Cloud progress update failed for level 28: $e');
    }

    if (!mounted) return;
    CelebrationUtils.showCelebrationAndLevelUp(
      context: context,
      nextLevelId: 29,
      title: 'Pintar Sekali!',
      message: 'Kamu berhasil melengkapi semua pola hewan dengan benar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Soft mint green background
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildInstruction(),
            const SizedBox(height: 8),
            // Pattern challenge rows
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ..._rows.map((row) => _buildPatternRow(row)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Parts Bin
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
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Level 28',
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets_rounded, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Seret hewan yang tepat untuk melengkapi pola!',
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

  Widget _buildPatternRow(AnimalPatternRow row) {
    final placed = _placedAnswers[row.index];
    final isSolved = placed != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSolved
            ? const Color(0xFFDCFCE7)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSolved ? Colors.green.shade300 : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sequence items
          ...row.sequence.map((item) {
            if (item == '?') {
              // Drop target slot
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) => !isSolved,
                  onAcceptWithDetails: (details) =>
                      _handleDrop(row.index, details.data),
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isSolved
                            ? Colors.green.shade100
                            : (isHovering
                                ? Colors.green.shade50
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSolved
                              ? Colors.green
                              : (isHovering
                                  ? Colors.green
                                  : Colors.grey.shade400),
                          width: isHovering ? 3 : 2,
                          style: isSolved
                              ? BorderStyle.none
                              : BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: isSolved
                            ? Text(placed, style: const TextStyle(fontSize: 30))
                            : Text(
                                isHovering ? '✓' : '?',
                                style: GoogleFonts.fredoka(
                                  fontSize: 24,
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
            } else {
              // Regular emoji cell
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 48,
                  height: 48,
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
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildPartsBin() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PILIHAN HEWAN (SERET KE KOTAK TANDA ?)',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _allAnimals.length,
              itemBuilder: (context, index) {
                final emoji = _allAnimals[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Draggable<String>(
                    data: emoji,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _buildAnimalChip(emoji),
                    ),
                    onDragStarted: () => HapticService.light(),
                    child: _buildAnimalChip(emoji),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalChip(String emoji) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}
