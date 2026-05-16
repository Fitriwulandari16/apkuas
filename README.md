BLUEPRINT STRUKTUR & ALUR KERJA APLIKASI: CILIKCODE

Nama Aplikasi: CilikCode

Tagline: Belajar Coding Jadi Seru!

Target Pengguna: Anak-anak (4-7 Tahun)

Tema Visual: Teal & Earth Tone (User-Friendly & Playful)

1. NAVIGASI UTAMA & ANTARMUKA (UI/UX)

A. Header & Manajemen Profil

Ikon Profil (Pojok Kanan Atas): - Menampilkan avatar kustom anak.

Akses cepat untuk melihat statistik pribadi (Total Bintang & Lencana).

Memungkinkan pergantian nama pengguna untuk personalisasi pengalaman belajar.

Tombol Navigasi Home/Map/Awards: Terletak di bagian bawah (Bottom Navigation Bar) untuk kemudahan akses jempol anak.

B. Menu Utama (Home Screen)

Terdapat tiga akses utama yang membagi fungsi aplikasi:

Mulai Belajar: Pintu masuk langsung ke level yang sedang aktif atau level terbaru yang belum diselesaikan.

Peta Petualangan: Visualisasi perjalanan belajar anak dalam bentuk peta interaktif (Node Level).

Dashboard Orang Tua: Area khusus monitor dengan pengamanan Parental Gate.

2. MODUL PEMBELAJARAN (CORE MODULES)

Aplikasi dibagi menjadi dua kategori besar menggunakan sistem tab di halaman utama:

Kategori 1: Logika Dasar (Computational Thinking)

Berfokus pada penyelesaian masalah terstruktur.

Level 11 (Pattern Recognition): Aktivitas "Gunting & Tempel" digital. Anak menarik potongan bentuk untuk melengkapi pola geometri yang bolong.

Level 12 (Conditional Logic): Misi "Bantu Lebah Pulang". Melatih logika algoritma bersyarat dengan mewarnai jalur hexagon mengikuti pola warna (Biru-Hijau).

Level 13 (Decomposition): Aktivitas "Hubungkan Komposisi". Melatih anak memecah objek kompleks menjadi bagian-bagian penyusunnya melalui sistem penarik garis.

Kategori 2: Kreativitas (Expression)

Berfokus pada kebebasan berekspresi dan koordinasi motorik.

Kanvas Mewarnai Bebas: Fitur menggambar tanpa batasan aturan atau skor.

Sistem Autosave: Setiap karya yang selesai dibuat akan tersimpan secara otomatis ke "Galeri Karyaku".

Ekspor Gambar: Fitur untuk mengunduh hasil karya ke galeri internal perangkat pengguna.

3. FITUR PETA PETUALANGAN (ADVENTURE MAP)

Fitur ini memberikan gambaran visual bagi anak mengenai progres mereka:

Jalur Progres: Garis putus-putus yang menghubungkan satu level ke level berikutnya.

Status Level:

Terkunci (Gembok): Level yang belum bisa diakses.

Terbuka (Bintang Kuning): Level yang sudah selesai dengan skor sempurna.

Aktif (Animasi): Level yang sedang dikerjakan saat ini.

4. DASHBOARD ORANG TUA (ANALYTICS)

Fitur pengawasan bagi wali murid:

Statistik Belajar: Menampilkan grafik durasi penggunaan aplikasi per hari.

Penguasaan Materi: Radar chart atau progress bar yang menunjukkan seberapa paham anak terhadap materi Algorithm, Pattern, dan Logic.

Kontrol Waktu: Pengaturan batas waktu (Screen Time) untuk menjaga kesehatan mata anak.

5. ALUR KERJA SISTEM (SISTEM FLOW)

Inisialisasi: Aplikasi mengecek SharedPreferences untuk memuat level terakhir yang terbuka dan total bintang.

Validasi Gameplay: Sistem mengecek input user di setiap level (misal: warna hexagon di Level 12). Jika sesuai algoritma, lebah bergerak.

Level Up Trigger: Setelah kondisi menang terpenuhi, aplikasi memicu LevelUpOverlay, memberikan bintang, dan memperbarui highestLevelReached.

Simpan Data: Perubahan data (bintang, progres, gambar galeri) disimpan secara lokal untuk memastikan data tetap ada meskipun aplikasi ditutup.

6. TEKNOLOGI YANG DIGUNAKAN

Framework: Flutter (Mobile & Web)

State Management: Provider / Signals (Sinkronisasi Bintang & Level)

Grafik & Animasi: CustomPainter (Jalur Hexagon & Garis) & Rive/Lottie (Animasi Karakter)

Storage: path_provider, shared_preferences, & RepaintBoundary (Simpan Gambar)