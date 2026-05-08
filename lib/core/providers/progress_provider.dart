import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// 1. Definisikan Provider menggunakan NotifierProvider (Gaya Baru)
final progressProvider = NotifierProvider<ProgressNotifier, int>(() {
  return ProgressNotifier();
});

// 2. Gunakan 'Notifier' bukan lagi 'StateNotifier'
class ProgressNotifier extends Notifier<int> {
  late Box box;

  @override
  int build() {
    // Di Riverpod 3, state awal didefinisikan di dalam fungsi build()
    box = Hive.box('settings'); 
    final initialLevel = box.get('unlockedLevel', defaultValue: 1);
    
    print('DEBUG: Data Progress Dimuat. Level Terbuka: $initialLevel');
    return initialLevel;
  }

  void saveProgress() {
    // Kita tetap bisa menggunakan 'state' untuk mengambil nilai saat ini
    box.put('unlockedLevel', state);
    print('DEBUG: Data Progress Disimpan. Level Terbuka: $state');
  }

  void completeLevel(int levelId) {
    print('DEBUG: Mencoba menyelesaikan Level $levelId. Status saat ini: $state');
    
    if (levelId == state) {
      // Mengupdate state di Notifier baru tetap menggunakan 'state'
      state = state + 1;
      saveProgress();
      print('DEBUG: Level Berhasil Diupdate! Level Terbuka Sekarang: $state');
    } else if (levelId < state) {
      print('DEBUG: Level ini sudah pernah diselesaikan.');
    }
  }

  void resetProgress() {
    state = 1;
    saveProgress();
  }
}