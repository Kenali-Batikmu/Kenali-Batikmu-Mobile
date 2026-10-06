# Kenali Batikmu (Mobile App)

Aplikasi edukasi dan pendeteksi motif batik nusantara (20 kelas) berbasis Flutter menggunakan model kecerdasan buatan TensorFlow Lite (`batik_mobilenetv2.tflite`).

---

## ⚡ Panduan Setup Normal (Quick Start)

Untuk menjalankan proyek ini secara normal setelah di-clone, Anda cukup menjalankan langkah-langkah standar berikut:

### 1. Clone Repositori & Buka Folder

```bash
git clone <URL_REPOSITORY>
cd Kenali-Batikmu-Mobile
```

### 2. Pasang Dependensi

Unduh seluruh dependensi Flutter yang terdaftar di `pubspec.yaml`:

```bash
flutter pub get
```

### 3. Hubungkan Perangkat / Nyalakan Emulator

Pastikan perangkat Android atau emulator sudah terhubung dan terbaca oleh Flutter:

```bash
flutter devices
```

### 4. Jalankan Aplikasi

Jalankan aplikasi dalam mode debug:

```bash
flutter run
```

---

## 📋 Prasyarat Sistem (Prerequisites)

Sebelum menjalankan aplikasi, pastikan perangkat pengembang Anda telah memenuhi spesifikasi berikut:

- **Flutter SDK**: Versi `3.3.0` ke atas (Dart SDK `>=3.3.0 <4.0.0`).
- **Java Development Kit (JDK)**: Dianjurkan JDK 17.
- **Android SDK**: Mendukung API Level 34 hingga 36.
- **Android Device / Emulator**: Minimal Android 8.0 Oreo (`minSdk = 26`).
- **Verifikasi Toolchain**: Jalankan `flutter doctor` untuk memastikan tidak ada komponen yang bermasalah.
