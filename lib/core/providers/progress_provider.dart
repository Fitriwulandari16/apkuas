import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final progressProvider = StateNotifierProvider<ProgressNotifier, int>((ref) {
  return ProgressNotifier();
});

class ProgressNotifier extends StateNotifier<int> {
  ProgressNotifier() : super(1) {
    _loadProgress();
  }

  void _loadProgress() {
    final box = Hive.box('progress');
    state = box.get('unlockedLevel', defaultValue: 1);
  }

  void completeLevel(int levelId) {
    // If user completes the current highest unlocked level, unlock the next one
    if (levelId == state) {
      state = state + 1;
      final box = Hive.box('progress');
      box.put('unlockedLevel', state);
    }
  }

  void resetProgress() {
    state = 1;
    final box = Hive.box('progress');
    box.put('unlockedLevel', 1);
  }
}
