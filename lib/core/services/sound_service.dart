import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// A lightweight, cross-platform sound service that works on all platforms
/// including web (where audioplayers often fails).
/// Uses SystemSound as a reliable fallback.
class SoundService {
  static Future<void> playSuccess() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('SoundService: Could not play success sound: $e');
    }
  }

  static Future<void> playError() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('SoundService: Could not play error sound: $e');
    }
  }
}
