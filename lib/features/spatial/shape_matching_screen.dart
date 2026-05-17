import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apkuas/core/services/haptic_service.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/utils/celebration_utils.dart';

class ShapeMatchingScreen extends ConsumerStatefulWidget {
  final int levelId;
  const ShapeMatchingScreen({super.key, this.levelId = 5});

  @override
  ConsumerState<ShapeMatchingScreen> createState() => _ShapeMatchingScreenState();
}

class _ShapeMatchingScreenState extends ConsumerState<ShapeMatchingScreen> {
  final List<IconData> shapes = [Icons.square, Icons.circle, Icons.change_history];
  final List<String> names = ['Kotak', 'Lingkaran', 'Segitiga'];
  final List<Color> colors = [Colors.blue, Colors.red, Colors.green];

  late List<int> itemOrder;
  Map<int, bool> matched = {};

  @override
  void initState() {
    super.initState();
    itemOrder = [0, 1, 2]..shuffle();
  }

  void _checkWin() {
    if (matched.length == shapes.length) {
      ref.read(progressProvider.notifier).completeLevel(widget.levelId);
      CelebrationUtils.showCelebrationAndLevelUp(
        context: context,
        nextLevelId: 6,
        title: 'LUAR BIASA! 🌟',
        message: 'Level 5 Selesai! Kamu sudah menguasai semua bentuk!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find the next shape to be dragged
    int? nextIndex;
    for (int idx in itemOrder) {
      if (!matched.containsKey(idx)) {
        nextIndex = idx;
        break;
      }
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFE3F2FD),
          appBar: AppBar(
            backgroundColor: Colors.transparent, 
            elevation: 0, 
            centerTitle: true,
            title: const Text('Cocokkan Bentuk', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.blue),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Pasangkan Bentuk ke Rumahnya!', 
                textAlign: TextAlign.center, 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 60),

              // Target Area (Rumah Bentuk)
              Center(
                child: SizedBox(
                  width: 250,
                  child: Column(
                    children: List.generate(shapes.length, (index) {
                      bool isMatched = matched.containsKey(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: DragTarget<int>(
                          onWillAccept: (data) => data == index && !isMatched,
                          onAccept: (data) {
                            setState(() {
                              matched[index] = true;
                              HapticService.success();
                              _checkWin();
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return SizedBox(
                              height: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // The "Rumah" (Target Box)
                                  Container(
                                    width: 120, // Adjusted to fit in 250 with text
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: isMatched 
                                          ? colors[index].withOpacity(0.2) 
                                          : Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isMatched ? colors[index] : Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        shapes[index], 
                                        color: isMatched ? colors[index] : Colors.grey.withOpacity(0.3), 
                                        size: 45,
                                      ),
                                    ),
                                  ),
                                  // The Label
                                  Text(
                                    names[index], 
                                    style: TextStyle(
                                      fontSize: 20, 
                                      fontWeight: FontWeight.bold, 
                                      color: isMatched ? colors[index] : Colors.blue.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const Spacer(),

              // Draggable Object (At the bottom)
              if (nextIndex != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Center(
                    child: Draggable<int>(
                      data: nextIndex,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Icon(shapes[nextIndex], color: colors[nextIndex], size: 80),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: Icon(shapes[nextIndex], color: colors[nextIndex], size: 60),
                      ),
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: colors[nextIndex].withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                        child: Icon(shapes[nextIndex], color: colors[nextIndex], size: 60),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

