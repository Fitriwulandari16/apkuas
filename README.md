🎮 Cilik Code: Game Edukasi Logika & Algoritma Anak

Cilik Code adalah aplikasi permainan edukasi berbasis Android yang dirancang khusus untuk memperkenalkan konsep logika dasar dan "coding mindset" kepada anak usia dini (Preschool/TK). Aplikasi ini dikembangkan menggunakan Flutter dengan pendekatan visual yang ceria dan interaktif.

🚀 Alur Kerja Aplikasi (Workflow)

Aplikasi ini dirancang dengan alur linear untuk memastikan anak belajar secara bertahap:

Splash Screen & Welcome: Menampilkan identitas Cilik Code sebagai pembuka.

Menu Utama: Halaman penyambutan dengan tombol 'MULAI' untuk masuk ke petualangan.

Peta Petualangan (Adventure Map):

Menggunakan layout unik berbentuk siluet piala/vas.

Progress System: Level 1-96 yang terbuka secara bertahap (Level Locking).

Gameplay (Level 1 - 12+):

Tantangan kognitif mulai dari mencocokkan bentuk, warna, hingga logika kondisional.

Contoh: Mewarnai Balon (Lvl 11) dan Puzzle Completion (Lvl 12).

Success Feedback: Animasi kemenangan (Confetti) sebagai apresiasi bagi anak sebelum lanjut ke level berikutnya.

🛠️ Blueprint Arsitektur Teknis

1. Stack Teknologi

Framework: Flutter (Dart)

State Management: Provider (Sinkronisasi status level).

Penyimpanan: SharedPreferences (Menyimpan progres terakhir).

Target Perangkat: Android (Optimasi untuk layar smartphone seperti V2333).

2. Fitur Unggulan (Technical Highlights)

Custom Grid Mapping: Teknik penyusunan baris dan kolom secara dinamis untuk menciptakan bentuk peta yang tidak kaku.

Interactive Logic: Implementasi Drag & Drop dan Color Picking untuk melatih koordinasi mata dan tangan.

Precision Connection: Penggunaan GlobalKey untuk mendeteksi koordinat titik tengah objek secara akurat pada fitur tarik garis (Matching).

3. Struktur Proyek

lib/providers/: Logika progres level pemain.

lib/screens/: Antarmuka peta dan menu utama Cilik Code.

lib/screens/levels/: Modul tantangan interaktif tiap level.

lib/widgets/: Komponen UI kustom (tombol, painter, dan animasi).

Proyek ini disusun untuk memenuhi tugas UAS Mata Kuliah Mobile Programming.