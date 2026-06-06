import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserService {
  static const String _boxName = 'userProgressBox';
  static const String _levelKey = 'highestLevel';

  /// Memperbarui progres level anak secara lokal di memori HP menggunakan Hive.
  /// Data disimpan secara independen di setiap perangkat sehingga tidak akan bercampur antar-user.
  static Future<void> updateProgress(int levelSelesai) async {
    try {
      debugPrint('UserService: Mengupdate progres lokal untuk levelSelesai=$levelSelesai');

      // Buka Hive Box untuk penyimpanan lokal
      var box = await Hive.openBox(_boxName);
      
      // Ambil level tertinggi yang pernah dicapai sebelumnya (Default Level 1)
      int currentSavedLevel = box.get(_levelKey, defaultValue: 1);
      
      // Hitung level berikutnya yang terbuka
      int nextLevel = levelSelesai + 1;

      // Logika validasi: Hanya update jika level baru lebih tinggi dari yang tersimpan
      if (nextLevel > currentSavedLevel) {
        await box.put(_levelKey, nextLevel);
        await box.put('lastCompletedLevel', levelSelesai);
        await box.put('updatedAt', DateTime.now().toIso8601String());
        debugPrint('UserService: Berhasil menyimpan progres ke Hive Lokal. Level Terbuka Selanjutnya: $nextLevel');
      } else {
        debugPrint('UserService: Level yang diselesaikan tidak lebih tinggi dari progres saat ini ($currentSavedLevel). Skip update.');
      }
    } catch (e) {
      debugPrint('UserService Error: Gagal menyimpan progres level ke Hive: $e');
    }
  }

  /// Mengambil data level terakhir yang terbuka untuk memuat peta petualangan (Map Screen)
  static Future<int> getProgress() async {
    try {
      var box = await Hive.openBox(_boxName);
      return box.get(_levelKey, defaultValue: 1);
    } catch (e) {
      debugPrint('UserService Error: Gagal mengambil progres dari Hive: $e');
      return 1; // Kembalikan ke level 1 sebagai pengaman jika error
    }
  }
}

/// Global callback triggered on any level completion.
Future<void> onLevelComplete(int levelId) async {
  await UserService.updateProgress(levelId);
}