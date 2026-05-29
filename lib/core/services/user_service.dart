import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  /// Automatically updates child level progression in Firebase Firestore users collection.
  /// Standard fields:
  /// - `currentLevel`: levelSelesai + 1 (the next unlocked level)
  /// - `lastCompletedLevel`: levelSelesai
  /// - `updatedAt`: serverTimestamp
  static Future<void> updateProgress(int levelSelesai) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'guest_user';

      debugPrint('UserService: Mengupdate progres untuk levelSelesai=$levelSelesai (uid: $uid)');

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'currentLevel': levelSelesai + 1,
        'lastCompletedLevel': levelSelesai,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('UserService: Berhasil menyimpan progres level ke Firestore (users/$uid)');
    } catch (e) {
      debugPrint('UserService Error: Gagal menyimpan progres level ke Firestore: $e');
      // Gracefully catch the error so the app continues playing without any crashes
    }
  }
}

/// Global callback triggered on any level completion.
/// Calls [UserService.updateProgress] asynchronously with robust error trapping.
Future<void> onLevelComplete(int levelId) async {
  await UserService.updateProgress(levelId);
}
