import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/core/providers/profile_provider.dart';

// 1. Definisikan Provider menggunakan NotifierProvider
final progressProvider = NotifierProvider<ProgressNotifier, int>(ProgressNotifier.new);

// 2. Notifier untuk mengelola level tertinggi yang dicapai
class ProgressNotifier extends Notifier<int> {
  late Box<dynamic> _box;

  @override
  int build() {
    _box = Hive.box('progress'); 
    final initialLevel = _box.get('highestLevelReached', defaultValue: 1);
    
    print('DEBUG: Data Progress Dimuat. Level Terbuka: $initialLevel');
    return initialLevel as int;
  }

  void saveProgress() {
    _box.put('highestLevelReached', state);
    print('DEBUG: Data Progress Disimpan. Level Terbuka: $state');
  }

  void completeLevel(int levelId) {
    print('DEBUG: Mencoba menyelesaikan Level $levelId. Status saat ini: $state');
    
    if (levelId == state) {
      // Tambahkan 10 bintang ke profil HANYA jika menyelesaikan level baru
      ref.read(profileProvider.notifier).addStars(10);
      
      // Buka level berikutnya
      state = state + 1;
      saveProgress();
      print('DEBUG: Level Berhasil Diupdate! Level Terbuka Sekarang: $state');
    } else if (levelId < state) {
      print('DEBUG: Level ini sudah pernah diselesaikan. Bintang tidak ditambahkan.');
    }
  }

  void updateHighestLevel(int levelId) {
    if (levelId > state) {
      state = levelId;
      saveProgress();
    }
  }

  void resetProgress() {
    state = 1;
    saveProgress();
  }
}