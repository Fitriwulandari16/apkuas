🎮 Petualangan Pintar: Game Edukasi Kognitif Anak

Petualangan Pintar adalah aplikasi permainan edukasi berbasis Android yang dirancang khusus untuk anak usia dini (Preschool/TK). Aplikasi ini dikembangkan menggunakan Flutter dengan fokus pada pelatihan logika, pengenalan bentuk, warna, dan algoritma dasar melalui serangkaian tantangan interaktif.

🚀 Alur Kerja Aplikasi (User Workflow)

Aplikasi ini mengikuti alur linear yang terintegrasi dengan sistem progres untuk memastikan pengalaman belajar yang bertahap:

Splash Screen & Inisialisasi: Memuat data progres pemain dari penyimpanan lokal.

Menu Utama: Gerbang utama untuk memulai petualangan atau melihat statistik pemain.

Adventure Map (Peta Petualangan):

Pemain melihat peta dengan siluet unik (Piala/Vas).

Sistem Level Locking: Pemain hanya bisa mengakses level baru setelah menyelesaikan level sebelumnya.

Gameplay (Level 1 - 11+):

Pemain menyelesaikan tantangan spesifik di setiap level (Matching, Drawing, Coloring).

Sistem validasi mengecek kebenaran jawaban secara real-time.

Level Complete & Feedback:

Animasi kemenangan (Confetti) muncul.

Data progres diperbarui secara otomatis.

Pemain diarahkan kembali ke peta atau lanjut ke level berikutnya.

🛠️ Blueprint Arsitektur Teknis

1. Stack Teknologi

Framework: Flutter (Dart)

Minimum SDK: Android API 21 (Lollipop)

Target SDK: Android API 34

State Management: Provider (untuk sinkronisasi status level di seluruh aplikasi).

Persistence: SharedPreferences (menyimpan level terakhir yang terbuka).

2. Mekanik Utama Level

Fitur

Deskripsi Teknis

Custom Shape Map

Layout peta dinamis menggunakan susunan Row/Column untuk membentuk siluet visual non-grid.

Shape Matching

Mekanik Drag and Drop dengan validasi koordinat target.

Line Connection

Menggunakan CustomPainter dan GlobalKey untuk mendapatkan koordinat presisi dari pusat objek.

Color Picker Logic

Sistem pemilihan warna (palette) sebelum melakukan aksi pada objek target (Level 11).

3. Komponen Visual (UI/UX)

Responsive Scaling: Menggunakan MediaQuery untuk memastikan elemen game muat dalam satu layar tanpa scroll pada berbagai rasio layar HP.

Visual Feedback: Glow effect pada objek aktif dan animasi transisi antar layar yang halus.

📂 Struktur Folder Proyek

lib/
├── main.dart              # Titik masuk aplikasi & konfigurasi tema
├── providers/
│   └── level_provider.dart    # Pengelola status progres dan penyimpanan lokal
├── screens/
│   ├── adventure_map.dart     # Tampilan peta siluet unik
│   └── levels/                # Kumpulan file logika setiap level
│       ├── level_5_shape.dart
│       ├── level_8_flower.dart
│       └── level_11_balloon.dart
└── widgets/
    ├── custom_line_painter.dart # Engine untuk menggambar garis antar objek
    └── game_button.dart         # Komponen tombol global


🔧 Instalasi & Build

Pastikan Flutter SDK sudah terpasang.

Jalankan flutter pub get untuk mengunduh dependencies.

Gunakan perintah flutter run untuk melakukan debug pada perangkat (Disarankan HP Fisik).

Untuk build APK: flutter build apk --release.

Dibuat untuk memenuhi tugas UAS Mata Kuliah Mobile Programming.