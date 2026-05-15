import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apkuas/core/theme/cilik_theme.dart';
import 'package:apkuas/core/providers/profile_provider.dart';
import 'package:apkuas/core/providers/progress_provider.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  bool _limitEnabled = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final highestLevel = ref.watch(progressProvider);

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
          style: GoogleFonts.fredoka(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {},
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
            _buildQuickSummary(profile.totalStars, highestLevel),
            const SizedBox(height: 32),
            _buildWeeklyActivity(),
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

  Widget _buildProfileSection(ProfileState profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE0F2F1),
            child: Text(profile.avatarIcon, style: const TextStyle(fontSize: 35)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Profil Anak', style: TextStyle(color: Colors.grey)),
            ],
          ),
          const Spacer(),
          const Chip(
            label: Text('AKTIF', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            backgroundColor: Color(0xFFE8F5E9),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary(int stars, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ringkasan Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSummaryCard('Total Bintang', stars.toString(), Icons.stars_rounded, Colors.orange),
            const SizedBox(width: 12),
            _buildSummaryCard('Level Terakhir', 'Lv. $level', Icons.flag_rounded, Colors.blue),
            const SizedBox(width: 12),
            _buildSummaryCard('Waktu Belajar', '2.5 Jam', Icons.timer_rounded, Colors.teal),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyActivity() {
    final List<double> heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.3, 0.8];
    final List<String> days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Aktivitas Mingguan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: 110 * heights[i],
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [CilikTheme.tealTua, CilikTheme.tealTua.withOpacity(0.6)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(days[i], style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analisis Materi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildMasteryItem('Pengenalan Pola', 0.85, Colors.purple),
        _buildMasteryItem('Logika & Algoritma', 0.65, Colors.orange),
        _buildMasteryItem('Dekomposisi', 0.40, Colors.blue),
      ],
    );
  }

  Widget _buildMasteryItem(String label, double progress, Color color) {
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
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
          const Text('Kontrol Orang Tua', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batas Waktu Harian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('30 Menit / Hari', style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
              Switch(
                value: _limitEnabled,
                activeColor: Colors.tealAccent,
                onChanged: (v) => setState(() => _limitEnabled = v),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notifikasi Aktivitas', style: TextStyle(color: Colors.white)),
              Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
