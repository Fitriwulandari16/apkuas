import 'package:hive_flutter/hive_flutter.dart';

class GalleryService {
  static const String _boxName = 'gallery';
  static const String _keyName = 'imagePaths';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static List<String> getSavedImages() {
    final box = Hive.box(_boxName);
    return List<String>.from(box.get(_keyName, defaultValue: <String>[]));
  }

  static Future<void> saveImagePath(String path) async {
    final box = Hive.box(_boxName);
    final currentPaths = getSavedImages();
    currentPaths.insert(0, path); // Newest first
    await box.put(_keyName, currentPaths);
  }

  static Future<void> deleteImage(String path) async {
    final box = Hive.box(_boxName);
    final currentPaths = getSavedImages();
    currentPaths.remove(path);
    await box.put(_keyName, currentPaths);
  }
}
