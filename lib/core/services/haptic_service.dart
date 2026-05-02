import 'package:vibration/vibration.dart';

class HapticService {
  static Future<void> success() async {
    if (await Vibration.hasVibrator() ?? false) {
      if (await Vibration.hasCustomVibrationsSupport() ?? false) {
        Vibration.vibrate(
          pattern: [0, 50, 100, 50],
          intensities: [0, 128, 0, 255],
        );
      } else {
        Vibration.vibrate(duration: 500);
      }
    }
  }

  static Future<void> failure() async {
    if (await Vibration.hasVibrator() ?? false) {
      if (await Vibration.hasAmplitudeControl() ?? false) {
        Vibration.vibrate(duration: 200, amplitude: 255);
      } else {
        Vibration.vibrate(duration: 200);
      }
    }
  }

  static Future<void> light() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 20);
    }
  }
}
