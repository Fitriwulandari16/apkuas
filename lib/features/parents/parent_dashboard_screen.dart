import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/providers/profile_provider.dart';
import 'package:apkuas/core/providers/progress_provider.dart';
import 'package:apkuas/core/services/parent_tracker_service.dart';

// ─── Data Model untuk semua async dashboard ────────────────────────────────

/// Menyimpan semua data yang dibutuhkan dashboard dalam satu objek
/// agar FutureBuilder hanya perlu satu kali build.
class _DashboardData {
  final List<double> weeklyRelative; // 0.0–1.0 untuk tinggi batang grafik
  final List<double> weeklyMinutes;  // menit aktual setiap hari
  final double totalWeekMinutes;     // total menit minggu ini

  const _DashboardData({
    required this.weeklyRelative,
    required this.weeklyMinutes,
    required this.totalWeekMinutes,
  });

  /// Format total jam minggu ini menjadi teks yang ramah dibaca.
  /// Contoh: "2.5 Jam", "45 Menit", "< 1 Menit"
  String get totalWeekFormatted {
    if (totalWeekMinutes < 1) return '< 1 Mnt';
    if (totalWeekMinutes < 60) {
      return '${totalWeekMinutes.toStringAsFixed(0)} Mnt';
    }
    final jam = (totalWeekMinutes / 60);
    return '${jam.toStringAsFixed(1)} Jam';
  }
}

// ─── Provider untuk data async dashboard ───────────────────────────────────

/// FutureProvider yang mengambil semua data tracker sekaligus.
/// Dengan autoDispose, data akan di-refresh setiap kali halaman dibuka.
final dashboardDataProvider = FutureProvider.autoDispose<_DashboardData>((ref) async {
  final relative = await ParentTrackerService.getWeeklyRelative();
  final minutes  = await ParentTrackerService.getWeeklyMinutes();
  final total    = minutes.fold<double>(0.0, (sum, m) => sum + m);
  return _DashboardData(
    weeklyRelative: relative,
    weeklyMinutes: minutes,
    totalWeekMinutes: total,
  );
});

// ─── Screen ────────────────────────────────────────────────────────────────

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState
    extends ConsumerState<ParentDashboardScreen> {
  bool _limitEnabled = true;

  // ─── Settings Dialog ─────────────────────────────────────────────────────

  /// Menampilkan dialog Kontrol Orang Tua dengan opsi Reset Progress.
  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ParentSettingsDialog(
        onResetProgress: () => _handleResetProgress(ctx),
      ),
    );
  }

  /// Menjalankan reset: menghapus data progress Hive dan me-refresh provider.
  Future<void> _handleResetProgress(BuildContext dialogCtx) async {
    Navigator.of(dialogCtx).pop(); // Tutup dialog terlebih dahulu

    // Tunjukkan loading singkat agar terasa responsif
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mereset progress...'),
        duration: Duration(seconds: 1),
      ),
    );

    // 1. Reset level & bintang via Riverpod
    ref.read(progressProvider.notifier).resetProgress();

    // 2. Reset bintang langsung ke Hive (ProfileNotifier belum punya
    //    resetStars(), kita tulis langsung ke box yang sama)
    try {
      final settingsBox = Hive.box('settings');
      await settingsBox.put('totalStars', 0);
      // Invalidate provider agar UI ter-refresh
      ref.invalidate(profileProvider);
    } catch (e) {
      debugPrint('ParentDashboard: Gagal reset bintang: $e');
    }

    // 3. Hapus semua data durasi tracker
    await ParentTrackerService.clearAllData();

    // 4. Refresh dashboard data
    ref.invalidate(dashboardDataProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Progress anak berhasil direset ke Level 1!'),
        backgroundColor: Colors.teal.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile      = ref.watch(profileProvider);
    final highestLevel = ref.watch(progressProvider);
    final asyncData    = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dashboard Orang Tua',
          style: GoogleFonts.fredoka(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan Orang Tua',
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(profile),
            const SizedBox(height: 24),
            // Quick Summary membutuhkan data async (waktu belajar)
            asyncData.when(
              loading: () => _buildQuickSummary(
                stars: profile.totalStars,
                level: highestLevel,
                weekLabel: '...',
              ),
              error: (_, __) => _buildQuickSummary(
                stars: profile.totalStars,
                level: highestLevel,
                weekLabel: '–',
              ),
              data: (data) => _buildQuickSummary(
                stars: profile.totalStars,
                level: highestLevel,
                weekLabel: data.totalWeekFormatted,
              ),
            ),
            const SizedBox(height: 32),
            // Grafik mingguan real-time
            asyncData.when(
              loading: () => _buildWeeklyActivity(
                relative: List<double>.filled(7, 0.0),
                minutes: List<double>.filled(7, 0.0),
                isLoading: true,
              ),
              error: (_, __) => _buildWeeklyActivity(
                relative: List<double>.filled(7, 0.0),
                minutes: List<double>.filled(7, 0.0),
              ),
              data: (data) => _buildWeeklyActivity(
                relative: data.weeklyRelative,
                minutes: data.weeklyMinutes,
              ),
            ),
            const SizedBox(height: 32),
            _buildMaterialAnalysis(),
            const SizedBox(height: 32),
            _buildParentControls(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Widget Builders ─────────────────────────────────────────────────────

  Widget _buildProfileSection(ProfileState profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE0F2F1),
            child: Text(profile.avatarIcon,
                style: const TextStyle(fontSize: 35)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Profil Anak',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
          const Spacer(),
          const Chip(
            label: Text('AKTIF',
                style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            backgroundColor: Color(0xFFE8F5E9),
          ),
        ],
      ),
    );
  }

  /// [weekLabel] = teks waktu belajar minggu ini, misal "2.5 Jam" atau "..."
  Widget _buildQuickSummary({
    required int stars,
    required int level,
    required String weekLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ringkasan Cepat',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSummaryCard(
              title: 'Total Bintang',
              value: stars.toString(),
              icon: Icons.stars_rounded,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              title: 'Level Terakhir',
              value: 'Lv. $level',
              icon: Icons.flag_rounded,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              title: 'Waktu Minggu Ini',
              value: weekLabel,
              icon: Icons.timer_rounded,
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// Grafik batang mingguan yang menggunakan data real dari Hive.
  ///
  /// [relative] = List<double> nilai 0.0–1.0 untuk tinggi batang.
  /// [minutes]  = List<double> menit aktual untuk tooltip label.
  /// [isLoading] = tampilkan shimmer indicator jika sedang memuat.
  Widget _buildWeeklyActivity({
    required List<double> relative,
    required List<double> minutes,
    bool isLoading = false,
  }) {
    // Hari dimulai Senin (sesuai getWeeklyRelative)
    const List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // Indeks hari ini dalam minggu (0 = Senin, 6 = Minggu)
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aktivitas Mingguan',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.teal,
                  ),
                )
              else
                Text(
                  'Minggu Ini',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == todayIndex;
                // Tinggi batang minimal 4 px agar batang kosong tetap terlihat
                final barHeight = (110 * relative[i]).clamp(4.0, 110.0);
                final isEmpty   = relative[i] == 0.0;

                // Format label menit untuk setiap batang
                String minLabel = '';
                if (!isEmpty) {
                  final m = minutes[i];
                  if (m < 1) {
                    minLabel = '< 1m';
                  } else if (m < 60) {
                    minLabel = '${m.toStringAsFixed(0)}m';
                  } else {
                    minLabel = '${(m / 60).toStringAsFixed(1)}j';
                  }
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Label menit di atas batang
                        if (!isEmpty)
                          Text(
                            minLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: isToday
                                  ? CilikTheme.tealTua
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Batang diagram
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          height: isEmpty ? 4 : barHeight,
                          decoration: BoxDecoration(
                            gradient: isEmpty
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isToday
                                        ? [
                                            CilikTheme.tealTua,
                                            CilikTheme.tealTua
                                                .withOpacity(0.7),
                                          ]
                                        : [
                                            CilikTheme.tealTua
                                                .withOpacity(0.7),
                                            CilikTheme.tealTua
                                                .withOpacity(0.4),
                                          ],
                                  ),
                            color: isEmpty
                                ? Colors.grey.shade200
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            // Highlight hari ini dengan border
                            border: isToday
                                ? Border.all(
                                    color: CilikTheme.tealTua,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Label hari
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 11,
                            color: isToday
                                ? CilikTheme.tealTua
                                : Colors.grey,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // Keterangan bawah grafik
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: CilikTheme.tealTua,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Hari ini disorot dengan border',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analisis Materi',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildMasteryItem('Pengenalan Pola', 0.85, Colors.purple),
        _buildMasteryItem('Logika & Algoritma', 0.65, Colors.orange),
        _buildMasteryItem('Dekomposisi', 0.40, Colors.blue),
      ],
    );
  }

  Widget _buildMasteryItem(
      String label, double progress, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toInt()}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kontrol Orang Tua',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batas Waktu Harian',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                  Text('30 Menit / Hari',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12)),
                ],
              ),
              Switch(
                value: _limitEnabled,
                activeColor: Colors.tealAccent,
                onChanged: (v) =>
                    setState(() => _limitEnabled = v),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          // Baris Notifikasi
          GestureDetector(
            onTap: () {/* TODO: Notifikasi Aktivitas */},
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifikasi Aktivitas',
                    style: TextStyle(color: Colors.white)),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.white24, size: 16),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 32),
          // Baris Reset Progress — shortcut dari panel bawah
          GestureDetector(
            onTap: _showSettingsDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reset Progress Anak',
                  style: TextStyle(
                      color: Colors.red.shade300,
                      fontWeight: FontWeight.w600),
                ),
                Icon(Icons.restart_alt_rounded,
                    color: Colors.red.shade300, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Pengaturan Orang Tua ───────────────────────────────────────────

class _ParentSettingsDialog extends StatelessWidget {
  final VoidCallback onResetProgress;

  const _ParentSettingsDialog({required this.onResetProgress});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_outlined,
                size: 22, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          const Text('Pengaturan',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          // ── Tombol Reset Progress ──────────────────────────────
          _SettingsActionTile(
            icon: Icons.delete_sweep_outlined,
            iconColor: Colors.red.shade400,
            title: 'Reset Progress Anak',
            subtitle:
                'Hapus semua level & bintang, kembali ke awal.',
            onTap: () {
              // Konfirmasi dua langkah sebelum reset
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('Yakin ingin reset?'),
                  content: const Text(
                    'Semua progress level, bintang, dan data waktu bermain '
                    'akan dihapus permanen dan tidak bisa dikembalikan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade600),
                      onPressed: () {
                        Navigator.pop(ctx); // Tutup konfirmasi
                        onResetProgress();  // Eksekusi reset
                      },
                      child: const Text('Ya, Reset Sekarang'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

/// Satu baris item aksi di dalam dialog settings.
class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: iconColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: iconColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
