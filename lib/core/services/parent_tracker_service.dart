import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk mencatat dan mengambil data durasi bermain anak.
///
/// Data disimpan secara lokal ke Hive Box bernama [_boxName].
/// Setiap key merepresentasikan satu hari dalam format 'yyyy-MM-dd',
/// dan value-nya adalah total durasi bermain dalam satuan DETIK (int).
///
/// Contoh isi box:
/// {
///   '2026-06-10': 1800,   // 30 menit
///   '2026-06-14': 3600,   // 60 menit
/// }
class ParentTrackerService {
  // ─── Konstanta ─────────────────────────────────────────────────────────────

  static const String _boxName = 'parentDashboardBox';

  /// [_sessionStart] menyimpan waktu saat sesi bermain dimulai.
  /// Null berarti tidak ada sesi yang sedang berjalan.
  static DateTime? _sessionStart;

  // ─── Format Key ────────────────────────────────────────────────────────────

  /// Mengubah [DateTime] menjadi string key Hive dalam format 'yyyy-MM-dd'.
  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Mengambil key untuk hari ini.
  static String get _todayKey => _dateKey(DateTime.now());

  // ─── Timer Sesi Bermain ────────────────────────────────────────────────────

  /// Memulai pencatatan waktu sesi bermain.
  ///
  /// Panggil fungsi ini saat:
  /// - Anak membuka aplikasi (di `initState` halaman utama / level manapun).
  /// - Anak masuk ke dalam sebuah level.
  ///
  /// Jika sesi sebelumnya belum dihentikan (misalnya karena crash),
  /// fungsi ini akan mengabaikannya dan memulai sesi baru dari sekarang.
  static void startSession() {
    if (_sessionStart != null) {
      // Sesi sebelumnya masih berjalan, stop dulu secara paksa agar tidak
      // kehilangan data, lalu mulai sesi baru.
      debugPrint(
        'ParentTrackerService: Sesi sebelumnya masih aktif. '
        'Menghentikan paksa dan memulai sesi baru.',
      );
      _stopAndSave(overrideStart: _sessionStart);
    }

    _sessionStart = DateTime.now();
    debugPrint(
      'ParentTrackerService: ▶ Sesi dimulai pada $_sessionStart',
    );
  }

  /// Menghentikan sesi bermain dan menyimpan durasinya ke Hive.
  ///
  /// Panggil fungsi ini saat:
  /// - Anak menutup aplikasi (di `dispose` atau `AppLifecycleState.paused`).
  /// - Anak keluar dari sebuah level (navigasi pop).
  ///
  /// Fungsi ini aman dipanggil berkali-kali; jika tidak ada sesi aktif,
  /// fungsi ini tidak akan melakukan apa pun.
  static Future<void> stopSession() async {
    if (_sessionStart == null) {
      debugPrint(
        'ParentTrackerService: stopSession() dipanggil tetapi tidak ada sesi aktif. Skip.',
      );
      return;
    }
    await _stopAndSave(overrideStart: _sessionStart);
    _sessionStart = null;
  }

  /// Inti logika: menghitung durasi dan menyimpannya ke Hive.
  static Future<void> _stopAndSave({required DateTime? overrideStart}) async {
    if (overrideStart == null) return;

    final now = DateTime.now();
    final durationSeconds = now.difference(overrideStart).inSeconds;

    // Abaikan sesi yang terlalu singkat (< 5 detik), kemungkinan besar
    // adalah false-positive dari lifecycle event.
    if (durationSeconds < 5) {
      debugPrint(
        'ParentTrackerService: Durasi sesi terlalu singkat ($durationSeconds detik). Diabaikan.',
      );
      return;
    }

    try {
      final box = await Hive.openBox<int>(_boxName);
      final existingSeconds = box.get(_todayKey, defaultValue: 0)!;
      final newTotal = existingSeconds + durationSeconds;
      await box.put(_todayKey, newTotal);

      final totalMinutes = (newTotal / 60).toStringAsFixed(1);
      debugPrint(
        'ParentTrackerService: ⏹ Sesi selesai. '
        'Durasi sesi: ${durationSeconds}s. '
        'Total hari ini ($todayReadable): ${totalMinutes} menit.',
      );
    } catch (e) {
      debugPrint('ParentTrackerService Error: Gagal menyimpan sesi ke Hive: $e');
    }
  }

  // ─── Getter Data ───────────────────────────────────────────────────────────

  /// Mengambil total durasi bermain hari ini, dikembalikan dalam satuan
  /// **menit** (double, dibulatkan ke 1 desimal).
  ///
  /// Kembalikan 0.0 jika belum ada data untuk hari ini.
  static Future<double> getTodayMinutes() async {
    try {
      final box = await Hive.openBox<int>(_boxName);
      final seconds = box.get(_todayKey, defaultValue: 0)!;
      return double.parse((seconds / 60).toStringAsFixed(1));
    } catch (e) {
      debugPrint('ParentTrackerService Error: Gagal membaca data hari ini: $e');
      return 0.0;
    }
  }

  /// Mengambil total durasi bermain hari ini dalam format String yang
  /// ramah dibaca, contoh: `"45 Menit"`, `"1 Jam 20 Menit"`, atau `"< 1 Menit"`.
  static Future<String> getTodayFormatted() async {
    final totalMinutes = (await getTodayMinutes()).round();
    if (totalMinutes < 1) return '< 1 Menit';
    if (totalMinutes < 60) return '$totalMinutes Menit';
    final jam = totalMinutes ~/ 60;
    final menit = totalMinutes % 60;
    if (menit == 0) return '$jam Jam';
    return '$jam Jam $menit Menit';
  }

  /// Mengambil data durasi bermain untuk **7 hari terakhir** (Senin s.d. Minggu
  /// dari minggu berjalan, atau 7 hari ke belakang dari hari ini).
  ///
  /// Nilai yang dikembalikan adalah [List<double>] berisi **menit** bermain
  /// untuk setiap hari. Indeks 0 = hari Senin minggu ini, indeks 6 = Minggu.
  ///
  /// Cocok langsung digunakan sebagai sumber data grafik batang mingguan.
  ///
  /// Contoh output: `[30.0, 0.0, 45.5, 90.0, 20.0, 0.0, 15.0]`
  static Future<List<double>> getWeeklyMinutes() async {
    try {
      final box = await Hive.openBox<int>(_boxName);
      final today = DateTime.now();

      // Cari hari Senin dari minggu berjalan (weekday: 1=Sen, 7=Min)
      final monday = today.subtract(Duration(days: today.weekday - 1));

      final List<double> result = [];

      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final key = _dateKey(day);
        final seconds = box.get(key, defaultValue: 0)!;
        final minutes = double.parse((seconds / 60).toStringAsFixed(1));
        result.add(minutes);
      }

      debugPrint('ParentTrackerService: Data mingguan diambil: $result');
      return result;
    } catch (e) {
      debugPrint('ParentTrackerService Error: Gagal membaca data mingguan: $e');
      // Kembalikan list kosong (7 hari = 0 semua) jika error
      return List<double>.filled(7, 0.0);
    }
  }

  /// Mengambil data 7 hari terakhir sebagai nilai **relatif (0.0 – 1.0)**
  /// yang siap dipakai langsung sebagai tinggi batang pada grafik.
  ///
  /// Nilai 1.0 = hari dengan durasi tertinggi dalam minggu tersebut.
  /// Jika seluruh minggu kosong (semua 0), kembalikan list berisi 0 semua.
  static Future<List<double>> getWeeklyRelative() async {
    final raw = await getWeeklyMinutes();
    final maxVal = raw.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return List<double>.filled(7, 0.0);
    return raw.map((v) => v / maxVal).toList();
  }

  // ─── Utilitas ──────────────────────────────────────────────────────────────

  /// Alias readable untuk key hari ini, digunakan di log.
  static String get todayReadable => _todayKey;

  /// Menghapus seluruh data durasi (berguna untuk tombol "Reset Data" di
  /// pengaturan orang tua).
  static Future<void> clearAllData() async {
    try {
      final box = await Hive.openBox<int>(_boxName);
      await box.clear();
      debugPrint('ParentTrackerService: Seluruh data durasi telah dihapus.');
    } catch (e) {
      debugPrint('ParentTrackerService Error: Gagal menghapus data: $e');
    }
  }

  /// Mengembalikan apakah ada sesi bermain yang sedang aktif saat ini.
  static bool get isSessionActive => _sessionStart != null;
}
