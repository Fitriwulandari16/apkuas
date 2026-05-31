BLUEPRINT STRUKTUR & ALUR KERJA APLIKASI: CILIKCODE
●	Nama Aplikasi: CilikCode
●	Tagline: Belajar Coding Jadi Seru!
●	Target Pengguna: Anak-anak Usia Dini / PAUD (4-7 Tahun)
●	Tema Visual: Teal & Earth Tone (User-Friendly, Warm, & Playful)

1. NAVIGASI UTAMA & ANTARMUKA (UI/UX)

A. Header & Manajemen Profil

●	Ikon Profil (Pojok Kanan Atas) Menampilkan avatar kustom anak yang lucu dan interaktif. Menyediakan akses cepat untuk melihat statistik pribadi seperti akumulasi total bintang yang dikumpulkan serta lencana penghargaan (badges) yang telah dicapai. Di bagian ini, orang tua atau anak juga dapat mengganti nama pengguna untuk personalisasi pengalaman belajar.

●	Tombol Navigasi Home/Map/Awards Terletak di bagian bawah layar (Bottom Navigation Bar). Desain tombol dibuat berukuran besar dengan jarak yang cukup lebar agar mudah dijangkau oleh jempol anak kecil tanpa salah pencet.

B. Menu Utama (Home Screen)

Terdapat tiga akses utama yang membagi fungsi aplikasi secara terarah:

1.	Mulai Belajar Pintu masuk utama berupa tombol pemicu cepat (Quick Play) yang akan langsung mengarahkan anak ke level yang sedang aktif saat ini (Current Level) atau melanjutkan level terakhir yang belum diselesaikan.

2.	Peta Petualangan Visualisasi perjalanan belajar anak dalam bentuk peta interaktif berkelok-kelok (Node Level) untuk melihat perkembangan belajar secara visual.

3.	Dashboard Orang Tua Area khusus pemantauan progres anak yang dilindungi oleh pengaman berupa gerbang matematika sederhana (Parental Gate) agar tidak bisa diakses secara tidak sengaja oleh anak-anak.

2. MODUL PEMBELAJARAN (CORE MODULES)

Aplikasi dibagi menjadi dua kategori besar menggunakan sistem tab interaktif di halaman utama:

Kategori 1: Logika Dasar (Computational Thinking)

Berfokus pada penyelesaian masalah terstruktur dan pengenalan pola berpikir logis komputer:

●	Level 11 (Pattern Recognition): Aktivitas "Gunting & Tempel" digital. Anak menarik potongan bentuk geometri untuk melengkapi pola visual yang bolong secara logis.

●	Level 12 (Conditional Logic): Misi "Bantu Lebah Pulang". Melatih logika algoritma bersyarat dengan mewarnai jalur hexagon mengikuti pola warna (Biru-Hijau).

●	Level 13 (Decomposition): Aktivitas "Hubungkan Komposisi". Melatih anak memecah objek kompleks menjadi bagian-bagian penyusunnya melalui sistem penarik garis.

●	Level 30 (Complex Conditional Pattern): Aktivitas "Pola Garis Lingkaran". Melatih anak menggambar dua pola garis (silang, tambah, vertikal, horizontal) berdasarkan kode warna lingkaran sebelum divalidasi.

●	Level 31 (Dual Attribute Matching): Aktivitas "Pencocokan Atribut Ganda". Anak menarik garis untuk menghubungkan bentuk geometri di kolom kiri ke kolom kanan berdasarkan kesamaan warna sekaligus bentuk yang identik.

●	Level 32 (Geometric Conditional Coloring): Aktivitas "Pewarnaan Geometri Roket". Anak mewarnai bidang-bidang geometri kosong pada roket besar menggunakan warna yang diinstruksikan oleh aturan legenda.

●	Level 33 (Algorithms: Loop): Misi "Ular Pola". Anak melatih logika perulangan dengan melanjutkan pewarnaan tubuh ular yang meliuk sesuai urutan pola warna awal (Kuning-Hijau-Oranye).

●	Level 34 (Sorting & Filtering): Aktivitas "Penyaringan Grid Huruf". Anak menyortir kumpulan huruf 'u' dan 'n' pada grid 5x5 dengan mewarnai masing-masing kotak sesuai kategori kodenya.

●	Level 35 (Abstraction): Aktivitas "Abstraksi Numerik Lingkaran". Anak mewarnai kuadran dalam lingkaran 3x3 berdasarkan simbol angka (1, 2, 3, atau 4) yang memetakan warna tertentu (Oranye, Hijau, Merah, Biru).

Kategori 2: Kreativitas (Expression)

Berfokus pada kebebasan berekspresi, istirahat dari tantangan logika, dan melatih koordinasi motorik halus:

●	Kanvas Mewarnai Bebas: Fitur menggambar dan mewarnai tanpa batasan aturan main, waktu, ataupun penilaian skor.

●	Sistem Autosave: Setiap karya mewarnai bebas yang selesai dibuat oleh anak akan langsung disimpan secara otomatis ke dalam album digital bernama "Galeri Karyaku".

●	Ekspor Gambar: Fitur khusus untuk mengunduh hasil gambar anak dari album galeri aplikasi langsung ke dalam penyimpanan internal galeri perangkat pengguna.

3. FITUR PETA PETUALANGAN (98-LEVEL ADVENTURE MAP)

Fitur ini memberikan gambaran visual terstruktur bagi anak mengenai sejauh mana progres petualangan belajar yang telah mereka tempuh. Peta didesain berupa jalur berkelok-kelok yang menarik dan ramah anak:

●	Jalur Progres Berupa visualisasi garis putus-putus tebal berwarna cerah yang menghubungkan satu ikon node level ke level berikutnya secara runtut dari Level 1 hingga Level 98.

●	Ikon Node Level Terbuka (Warna Hijau) Menunjukkan level-level yang sudah berhasil diselesaikan dengan baik oleh anak. Ikon berwarna hijau ini tetap dapat diketuk kembali jika anak ingin mengulang permainan atau melatih kemampuan ingatan mereka.

●	Ikon Node Level Aktif (Warna Kuning) Menunjukkan titik petualangan anak saat ini yang sedang aktif dikerjakan. Ikon berwarna kuning ini diberikan animasi denyut lembut (pulse animation) untuk memusatkan perhatian anak bahwa level tersebut adalah tantangan selanjutnya yang harus dibuka.

●	Ikon Node Level Terkunci (Warna Abu-abu) Menunjukkan level-level masa depan yang belum bisa diakses oleh anak. Ikon berwarna abu-abu ini memiliki mode non-aktif (disabled gesture) sehingga tidak merespons sentuhan agar anak tetap fokus menyelesaikan level aktif saat ini secara berurutan.

4. DASHBOARD ORANG TUA (ANALYTICS)

Fitur khusus berbasis pengawasan cerdas bagi wali murid untuk melihat tumbuh kembang anak dalam proses bermain:

●	Statistik Belajar: Menampilkan bagan atau grafik durasi penggunaan aplikasi secara berkala (harian dan mingguan) guna membantu orang tua memantau aktivitas screen-time anak.

●	Penguasaan Materi: Progress bar visual yang merepresentasikan tingkat pemahaman anak terhadap pilar-pilar utama Computational Thinking (Algorithm, Pattern Recognition, Decomposition, dan Abstraction).

●	Kontrol Waktu: Pengaturan batas waktu bermain harian (Daily Screen-Time Limit) yang dapat dipasang oleh orang tua. Jika batas waktu habis, aplikasi akan menampilkan karakter edukasi yang mengajak anak untuk beristirahat.

5. ALUR KERJA SISTEM (SYSTEM FLOW)

1.	Inisialisasi & Sync: Saat aplikasi pertama kali dijalankan (startup), sistem secara asinkron memproses login pengguna dan melakukan pencocokan data progress. Sistem akan menarik data dari Cloud Firestore untuk memuat progress level terakhir yang terbuka, total bintang, serta lencana profil. Jika tidak ada jaringan internet, aplikasi otomatis merujuk ke database lokal (SharedPreferences) sebagai sistem cadangan darurat (fallback).

2.	Validasi Gameplay: Sistem memproses setiap input sentuhan atau geseran jari pengguna secara real-time pada setiap level yang dimainkan (misalnya mendeteksi arah garis ganda pada Level 30 atau memeriksa kesesuaian filter warna huruf pada Level 34).

3.	Level Up & Cloud Save Trigger: Sesaat setelah kondisi kemenangan pada level terpenuhi (misal: Level 32 terwarnai sempurna), sistem akan memicu animasi dialog kemenangan (LevelUpOverlay) dan memberikan tambahan bintang. Di saat yang bersamaan, fungsi UserService.updateProgress() dieksekusi di latar belakang untuk mengirimkan pembaruan status currentLevel (levelSelesai + 1) langsung menuju Cloud Firestore secara permanen.

4.	Sinkronisasi Multi-Platform: Setiap kali progress disimpan ke Firestore, peta petualangan pada platform Android maupun Web Browser (Localhost Chrome) akan langsung ter-render ulang secara otomatis. Node yang baru diselesaikan akan berubah menjadi warna Hijau, dan node berikutnya akan aktif menjadi warna Kuning.

6. TEKNOLOGI YANG DIGUNAKAN

●	Framework Utama: Flutter SDK (Multi-platform: Mobile Android & Web Browser).

●	State Management: Provider / Signals (Sinkronisasi Bintang, Level, dan data profil secara real-time ke seluruh widget).

●	Database & Cloud Storage: Firebase Firestore (Penyimpanan database NoSQL cloud untuk melacak data progress pengguna lintas platform secara gigih/persistent) dan Firebase Auth (Otentikasi anonim atau terdaftar bagi pengguna).

●	Konfigurasi Platform: File firebase_options.dart terpadu untuk merangkum SHA-1 Fingerprint (Android) serta Browser API Key (Web Browser Chrome).

●	Grafik & Animasi UI: CustomPainter (Menggambar jalur peta berkelok, logika penarik garis titik matching, grid geometri, serta kuadran warna) dan Rive/Lottie (Membawa animasi karakter interaktif penuntun anak).

●	Storage Lokal & Ekspor: path_provider, shared_preferences (untuk enkripsi cadangan offline data anak), & RepaintBoundary (untuk menangkap canvas dan mengekspor hasil gambar mewarnai bebas anak ke galeri lokal).

