import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  final bool isPrivacy;

  const TermsAndPrivacyScreen({super.key, this.isPrivacy = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text(
          isPrivacy ? 'Kebijakan Privasi' : 'Syarat & Ketentuan',
          style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppTheme.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPrivacy
                    ? 'Kebijakan Privasi Pengguna Kenali Batikmu'
                    : 'Syarat & Ketentuan Penggunaan Aplikasi',
                style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Terakhir Diperbarui: 2 Oktober 2026\nVersi 1.0 — Sesuai Standar OWASP Mobile M6 (Kontrol Privasi)',
                style: AppTheme.inter(fontSize: 12, color: AppTheme.textMuted),
              ),
              const Divider(height: 28, color: AppTheme.border),
              if (isPrivacy) ...[
                _buildSection(
                  '1. Privasi & Pemrosesan Gambar On-Device',
                  'Sesuai prinsip utama arsitektur Kenali Batikmu dan NFR-SEC-06, seluruh foto yang Anda ambil melalui kamera atau unggah dari galeri untuk Scan Batikmu maupun Scan Kuismu diproses secara on-device di perangkat ponsel Anda. Foto tersebut TIDAK diunggah atau disimpan di server eksternal kami.',
                ),
                _buildSection(
                  '2. Pengumpulan Data Pengguna',
                  'Data yang kami simpan meliputi nama lengkap, alamat email yang dienkripsi, serta riwayat progres modul pembelajaran dan skor kuis untuk kebutuhan personalisasi edukasi Anda.',
                ),
                _buildSection(
                  '3. Keamanan Data (OWASP M9 & M10)',
                  'Sesi akun diamankan dengan penyimpanan terlindungi, dan kata sandi dienkripsi dengan algoritma hashing salt berstandar industri modern.',
                ),
              ] else ...[
                _buildSection(
                  '1. Ruang Lingkup Layanan',
                  'Aplikasi Kenali Batikmu adalah platform edukasi interaktif untuk mengenalkan ragam motif batik nusantara, filosofi budaya keraton dan pesisiran, serta sarana belajar mandiri menggambar motif.',
                ),
                _buildSection(
                  '2. Akun dan Keamanan Kredensial',
                  'Pengguna bertanggung jawab menjaga kerahasiaan kata sandi akun masing-masing. Sistem menerapkan batasan percobaan masuk untuk mencegah upaya akses tanpa izin.',
                ),
                _buildSection(
                  '3. Hak Cipta dan Warisan Budaya',
                  'Seluruh materi sejarah, narasi filosofi, serta dokumentasi visual motif batik dilindungi sebagai warisan budaya bangsa untuk tujuan edukasi nirlaba.',
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Saya Mengerti'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body, style: AppTheme.inter(fontSize: 13, height: 1.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
