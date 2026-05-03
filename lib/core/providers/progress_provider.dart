import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final progressProvider = StateNotifierProvider<ProgressNotifier, int>((ref) {
  return ProgressNotifier();
});

class ProgressNotifier extends StateNotifier<int> {
  ProgressNotifier() : super(1) {
    loadProgress();
  }

  void loadProgress() {
    try {
      final box = Hive.box('progress');
      state = box.get('unlockedLevel', defaultValue: 1);
      print('DEBUG: Data Progress Dimuat. Level Terbuka: $state');
    } catch (e) {
      print('DEBUG: Gagal memuat progress: $e');
    }
  }

  void saveProgress() {
    try {
      final box = Hive.box('progress');
      box.put('unlockedLevel', state);
      print('DEBUG: Data Progress Disimpan. Level Terbuka: $state');
    } catch (e) {
      print('DEBUG: Gagal menyimpan progress: $e');
    }
  }

  void completeLevel(int levelId) {
    print('DEBUG: Mencoba menyelesaikan Level $levelId. Status saat ini: $state');
    if (levelId == state) {
      state = state + 1;
      saveProgress();
      print('DEBUG: Level Berhasil Diupdate! Level Terbuka Sekarang: $state');
    } else if (levelId < state) {
      print('DEBUG: Level $levelId sudah pernah diselesaikan sebelumnya.');
    } else {
      print('DEBUG: Level $levelId tidak bisa diselesaikan sekarang (belum giliran).');
    }
  }

  void resetProgress() {
    state = 1;
    saveProgress();
  }
}
