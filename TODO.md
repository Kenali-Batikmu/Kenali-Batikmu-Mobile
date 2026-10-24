# Rencana Kerja (TODO): Implementasi Arsitektur 100% Offline-First & Sinkronisasi Cloud Supabase

Dokumen ini menjadi panduan kerja terpadu untuk sisi Mobile (Flutter) dan Cloud Backend (Supabase) agar aplikasi berjalan penuh secara **Offline-First (On-Device)** dengan sinkronisasi awan otomatis saat tersambung internet.

---

## 1. Arsitektur Inti: Offline-First Hybrid Cloud Sync

Aplikasi dibagi menjadi dua peran yang terintegrasi:

```
┌──────────────────────────────────────────────────────────┐
│                   APLIKASI MOBILE (HP)                   │
│  - 100% Materi Modul (20 Modul & 3 Pilar Panjang)        │
│  - 100% Bank Kuis (500 Soal: 25 per modul)               │
│  - Mesin Kuis Teori On-Device (Acak 10 Soal & Nilai KKM) │
│  - Kuis Praktikum Modul (Kamera/Galeri & Evaluasi Pola)  │
│  - Scan Kamera & Klasifikasi On-Device (Nol Cache)       │
│  - Database SQLite Lokal (Identik 100% dengan Cloud)     │
└────────────────────────────┬─────────────────────────────┘
                             │
            (Sinkronisasi Non-Blocking Saat Ada Internet)
                             ▼
┌──────────────────────────────────────────────────────────┐
│              CLOUD BACKEND (SUPABASE BaaS)               │
│  - Autentikasi Pengguna & Sesi Akun                      │
│  - PostgreSQL Database (Identik dengan SQLite Lokal)     │
│  - Supabase Storage: Bucket 'avatars' (Foto Profil)      │
│  - Supabase Storage: Bucket 'practices' (Foto Praktikum) │
│  - Cadangan Progres Belajar, Riwayat Kuis, & Pindaian    │
└──────────────────────────────────────────────────────────┘
```

> **Catatan Arsitektur:** Aplikasi tidak lagi memerlukan web service backend terpisah (seperti Flask/FastAPI di Hugging Face/container) karena seluruh fungsi database, otentikasi data, dan media storage ditangani langsung oleh Cloud Supabase secara aman via Row Level Security (RLS) dan anon public key.

---

## 2. Penyelarasan Database (Struktur Identik 100% SQLite & Cloud Supabase)

Database SQLite lokal di HP (`kenali_batikmu.db`) dan Cloud Supabase PostgreSQL membawa struktur tabel relasional yang sama persis:

### 2.1 Skema Tabel (Status: 100% LIVE & Terverifikasi)

* [X] **Tabel `batik_motifs`** (20 Motif Batik Nusantara):
  * Kolom: `id`, `name`, `slug`, `origin_region`, `short_description`, `thumbnail_url`, `ml_class_index`.
  * Status: Terisi 20 motif lengkap di SQLite lokal & Supabase PostgreSQL.
* [X] **Tabel `modules`** (20 Modul Pembelajaran):
  * Kolom: `id`, `motif_id`, `title`, `description`, `cover_image`, `passing_score` (70), `order_no`.
  * Status: Terisi 20 modul lengkap di SQLite lokal & Supabase PostgreSQL.
* [X] **Tabel `module_contents`** (Konten 3 Pilar Materi):
  * Kolom: `id`, `module_id`, `pillar` (`sejarah_filosofi`, `karakteristik`, `galeri`), `title`, `body`, `order_no`.
  * Status: Terisi 60 baris materi narasi panjang di SQLite lokal & Supabase PostgreSQL.
* [X] **Tabel `module_gallery_images`** (Galeri Visual Modul):
  * Kolom: `id`, `module_id`, `image_url`, `caption`, `order_no`.
  * Status: Terisi di SQLite lokal & Supabase PostgreSQL.
* [X] **Tabel `quiz_questions`** (500 Butir Bank Soal: 25 per Modul):
  * Kolom: `id`, `module_id`, `question_number`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`.
  * Status: Terisi 500 butir soal lengkap di SQLite lokal & Supabase PostgreSQL.
* [X] **Tabel `users`** (Data Pengguna & Profil):
  * Kolom: `id`, `name`, `email`, `phone`, `password_hash`, `profile_image_path`, `created_at`, `updated_at`.
  * Status: Terintegrasi SQLite lokal & Supabase PostgreSQL.
* [X] **Tabel `user_module_progress`** (Capaian & Progres Belajar Modul):
  * Kolom: `id`, `user_id`, `module_id`, `status`, `progress_percent`, `history_done`, `character_done`, `gallery_done`, `quiz_done`, `practice_done`, `completed_at`, `last_accessed_at`.
  * Status: Terintegrasi SQLite lokal (UPSERT) & Supabase PostgreSQL (`onConflict: user_id,module_id`).
* [X] **Tabel `quiz_attempts`** (Riwayat Pengerjaan Kuis Teori):
  * Kolom: `id`, `user_id`, `module_id`, `score`, `passed`, `attempted_at`.
  * Status: Tersimpan otomatis saat kuis teori dikumpulkan.
* [X] **Tabel `scans`** (Riwayat Pindaian Kamera & Kuis Praktikum):
  * Kolom: `id`, `user_id`, `scan_type` (`kuismu` / `universal`), `module_id`, `image_path`, `confidence`, `fit_score`, `passed`, `inference_time_ms`, `created_at`.
  * Status: Tersimpan otomatis saat praktikum modul atau universal scan dilakukan.

---

## 3. Supabase Cloud Storage (Status: 100% LIVE & Terverifikasi)

* [X] **Bucket `avatars` (Public Bucket)**:
  * Digunakan untuk menyimpan foto profil pengguna hasil jepretan kamera atau galeri.
  * Kebijakan RLS (Row Level Security): Public Read & Authenticated/Anon Insert/Update.
  * URL publik file otomatis disimpan ke kolom `profile_image_path` di tabel `users`.
* [X] **Bucket `practices` (Public Bucket)**:
  * Digunakan untuk menyimpan foto bukti pengerjaan kuis praktikum modul batik.
  * Kebijakan RLS (Row Level Security): Public Read & Insert.
  * URL publik file otomatis dicatat pada kolom `image_path` di tabel `scans` (`scan_type: 'kuismu'`).

---

## 4. Roadmap Pengerjaan Sisi Mobile (`Kenali-Batikmu-Mobile`)

### Fase 1: Seeding SQLite Lokal Mandiri (SELESAI 100%)

* [X] Tanamkan dataset 20 motif batik ke seeder lokal mobile (`assets/database/kenali_batikmu.db`).
* [X] Tanamkan 20 modul belajar dengan materi narasi 3 pilar panjang ke seeder lokal mobile.
* [X] Tanamkan 500 bank butir soal kuis (25 soal per modul lengkap dengan opsi A-D, kunci jawaban, dan pembahasan) ke seeder lokal mobile.
* [X] Uji migrasi database lokal: saat aplikasi di-install pertama kali, database langsung siap 100% tanpa menembak server (lulus unit test & widget test).

### Fase 2: Alur Autentikasi Pengguna & Profil Akun (SELESAI 100%)

* [X] **Form Login Bersih**: Default credential dummy pada form login telah dikosongkan agar pengguna masuk dengan akun riil.
* [X] **Registrasi & Login**: Menyimpan data nama, email, dan salted SHA-256 hash kata sandi ke SQLite lokal dan sinkronisasi ke Supabase Cloud `users`.
* [X] **Perbaikan Bug Nama Profil**: Nama saat register dipastikan tersimpan konsisten di database lokal SQLite dan session provider, tidak lagi tertukar atau kembali ke default.
* [X] **Penyimpanan Foto Profil Pengguna**:
  * Pengguna dapat memilih foto dari kamera atau galeri perangkat.
  * Foto disimpan ke direktori lokal perangkat untuk akses offline instan.
  * Foto otomatis diunggah ke Supabase Storage bucket `avatars` secara asinkron.
  * URL publik atau path foto profil disimpan ke tabel `users` (kolom `profile_image_path`) baik di SQLite lokal maupun Cloud Supabase.
  * Foto profil tetap tersimpan dan termuat sempurna setelah aplikasi dibuka ulang atau login kembali.

### Fase 3: Mesin Kuis Teori & Progress Belajar On-Device (SELESAI 100%)

* [X] **Layar Detail Modul (`module_detail_screen.dart`)**:
  * Menampilkan materi 3 pilar langsung dari tabel SQLite `module_contents`.
  * Mencatat status selesai membaca per pilar ke `user_module_progress` lokal dan cloud.
* [X] **Layar Kuis Teori Modul (`theory_quiz_screen.dart`)**:
  * **Pengacak Soal**: Memilih 10 soal acak dari bank 25 soal per modul di SQLite lokal.
  * **Penilaian Instan**: Skor = `(Jawaban Benar / Total Soal) * 100`. KKM >= 70.
  * **Koreksi & Pembahasan**: Kunci jawaban dan penjelasan langsung ditampilkan dari SQLite lokal.
  * **Persistensi Data**:
    * Hasil kuis disimpan ke SQLite lokal tabel `quiz_attempts`.
    * Status kelulusan dan skor kuis diperbarui di `user_module_progress`.
    * Data otomatis disinkronkan ke Cloud Supabase tabel `quiz_attempts` dan `user_module_progress` tanpa memblokir antarmuka pengguna.

### Fase 4: Kuis Praktikum Modul & Penyimpanan Karya (SELESAI 100%)

* [X] **Layar Kuis Praktikum (`practice_quiz_screen.dart`)**:
  * Pengguna mengambil foto karya batik melalui kamera aktif atau mengunggah gambar dari galeri perangkat.
  * Analisis kemiripan karya dilakukan dan nilai kecocokan dihitung (skor >= 70% dinyatakan lulus).
* [X] **Penyimpanan Foto & Sinkronisasi Cloud Praktikum**:
  * Path berkas foto diteruskan ke `AppProvider.savePracticeResult(moduleId, fitScore, passed, imagePath: path)`.
  * Berkas disimpan di SQLite lokal tabel `scans` dan progres di `user_module_progress`.
  * Jika terhubung internet, foto diunggah ke Supabase Storage bucket `practices`.
  * Record pindaian praktikum dicatat di Supabase tabel `scans` (`scan_type: 'kuismu'`, `fit_score`, `image_path`).
  * Status praktikum (`practice_done: true`) disinkronkan ke Supabase `user_module_progress`.
  * Hasil praktikum otomatis masuk ke riwayat pindaian aplikasi.

### Fase 5: Universal Scan Kamera On-Device (Tahap Berikutnya)

* [ ] **Layar Universal Scan (`universal_scan_screen.dart`)**:
  * Klasifikasi 20 motif batik secara offline menggunakan model TensorFlow Lite lokal.
  * Menampilkan skor keyakinan deteksi dan rekomendasi modul terkait.
* [ ] **Manajemen Cache Nol Sampah (Zero-Storage Leak)**:
  * Berkas jepretan kamera universal scan disimpan sementara di direktori cache.
  * Saat pengguna menutup bottom sheet hasil pemindaian atau berpindah layar, berkas foto sementara langsung dihapus otomatis dari memori perangkat (0 bytes sampah cache).

### Fase 6: Pengujian Bebas Internet (100% Airplane Mode Testing)

* [ ] Aktifkan Mode Pesawat (Airplane Mode) pada perangkat atau emulator.
* [ ] Verifikasi buka seluruh 20 modul, baca materi 3 pilar, dan buka gambar galeri secara offline tanpa loading.
* [ ] Kerjakan kuis teori: 10 soal acak tampil, nilai dihitung, pembahasan muncul, dan capaian tersimpan offline.
* [ ] Kerjakan kuis praktikum: ambil gambar karya, evaluasi skor, dan cek tersimpannya progres modul.
* [ ] Buka profil: nama dan foto profil tetap tampil offline.
* [ ] Matikan Mode Pesawat (nyalakan internet kembali): pastikan data progres, riwayat kuis, dan pindaian otomatis tersinkronisasi ke Cloud Supabase di latar belakang tanpa pesan error yang mengganggu.

---

## 5. Batasan & Larangan Kritis (Non-Negotiables)

1. **Dilarang Menghalangi Pengguna dengan Dialog Error Jaringan**: Saat pengguna sedang offline, tidak boleh ada popup "Koneksi terputus" atau "Gagal menghubungi server" saat membuka modul, mengerjakan kuis, atau melihat profil.
2. **Dilarang Menyimpan Sampah Foto Universal Scan**: Foto dari kamera universal scan tidak boleh menumpuk di memori ponsel. Begitu hasil ditutup, berkas sementara wajib dihapus.
3. **Integritas Penilaian Kuis**: Kuis teori wajib menggunakan perumusan skor adil: `(Benar / 10) * 100`, batas kelulusan minimal 70 (minimal 7 benar dari 10 soal acak).
4. **Keamanan Kredensial**: Tidak ada kredensial kata sandi yang disimpan dalam bentuk plain-text di SQLite maupun cloud. Wajib menggunakan salted SHA-256 hash.
