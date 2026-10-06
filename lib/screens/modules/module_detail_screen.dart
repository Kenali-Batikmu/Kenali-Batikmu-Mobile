import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import 'theory_quiz_screen.dart';
import 'practice_quiz_screen.dart';

class ModuleDetailScreen extends StatefulWidget {
  final ModuleModel module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  int _activeStep = 0; // 0: Teori & Filosofi, 1: Karakteristik, 2: Galeri, 3: Kuis Modul

  // Audio Player State Simulation
  bool _isPlayingAudio = false;
  int _audioCurrentSeconds = 42; // Mulai di 00:42 dari 03:45
  final int _audioTotalSeconds = 225; // 3 menit 45 detik
  Timer? _audioTimer;

  @override
  void dispose() {
    _audioTimer?.cancel();
    super.dispose();
  }

  void _toggleAudio() {
    setState(() {
      _isPlayingAudio = !_isPlayingAudio;
    });

    if (_isPlayingAudio) {
      _audioTimer?.cancel();
      _audioTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_audioCurrentSeconds < _audioTotalSeconds) {
            _audioCurrentSeconds++;
          } else {
            _audioCurrentSeconds = 0;
            _isPlayingAudio = false;
            timer.cancel();
          }
        });
      });
    } else {
      _audioTimer?.cancel();
    }
  }

  String _formatAudioTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showZoomImageDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppTheme.darkSurface : const Color(0xFF221A14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Pakem Motif Parang Kusumo',
                      style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF382516),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.waves, size: 160, color: Colors.white.withValues(alpha: 0.2)),
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Kemiringan 45° • Ornamen Mlinjon & Lidah Api',
                            style: AppTheme.satoshi(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tampak resolusi tinggi canting mori primissima keraton dengan pewarnaan alami kayu soga jambal murni.',
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: const Color(0xFF261A12),
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Tutup Tampilan', style: AppTheme.satoshi(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          color: isDark ? Colors.white : AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'KENALI BATIKMU',
              style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.primary),
            ),
            Text(
              'Detail Modul',
              style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_activeStep == 0) _buildPage4TeoriFilosofi(context, isDark),
            if (_activeStep == 1) _buildPage5Karakteristik(context, isDark),
            if (_activeStep == 2) _buildPage6Galeri(context, isDark),
            if (_activeStep == 3) _buildPage7KuisModul(context, isDark),

            // Bottom Navigation Stepper Sesuai PDF (Tombol Panah Kiri, Dots Indikator, Tombol Panah Kanan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Kiri
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      onPressed: () {
                        if (_activeStep > 0) {
                          setState(() => _activeStep--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),

                  // Dots Indikator 4 Halaman (Teori, Karakteristik, Galeri, Kuis) Sesuai PDF
                  Row(
                    children: List.generate(4, (index) {
                      final isActive = index == _activeStep;
                      return GestureDetector(
                        onTap: () => setState(() => _activeStep = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.accentGold : (isDark ? AppTheme.darkBorder : AppTheme.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Tombol Kanan (Cokelat Tua)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5A3416),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed: () {
                        if (_activeStep < 3) {
                          setState(() => _activeStep++);
                        } else {
                          // Jika sudah di step terakhir, buka kuis teori
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TheoryQuizScreen(module: widget.module),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Halaman 1: Teori & Filosofi Sesuai PDF Page 4
  Widget _buildPage4TeoriFilosofi(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Motif dengan Badge 'Motif Klasik Larangan' dan 'Perbesar Detail'
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF382516),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Icon(Icons.waves, size: 90, color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: AppTheme.accentGold, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Motif Klasik Larangan',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => _showZoomImageDialog(context, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Perbesar Detail',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Badge Modul & Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'MODUL 3 DARI 8 • TEORI & FILOSOFI',
              style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Motif Parang Kusumo',
            style: AppTheme.satoshi(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Batik Klasik Surakarta & Yogyakarta • Estimasi Baca 8 Menit',
            style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Narasi Filosofi Suara (Interactive Audio Player) Sesuai PDF Page 4
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleAudio,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A3416),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5A3416).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isPlayingAudio ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Narasi Filosofi Suara',
                            style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Dikisahkan oleh Abdi Dalem Keraton',
                            style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _isPlayingAudio
                          ? '${_formatAudioTime(_audioCurrentSeconds)} / ${_formatAudioTime(_audioTotalSeconds)}'
                          : '3:45',
                      style: AppTheme.satoshi(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold,
                      ),
                    ),
                  ],
                ),
                if (_isPlayingAudio) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _audioCurrentSeconds / _audioTotalSeconds,
                      backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Hakikat & Simbol Ombak Laut Selatan
          Text(
            'Hakikat & Simbol Ombak Laut Selatan',
            style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Motif Parang Kusumo memancarkan ritme visual diagonal yang merepresentasikan deburan ombak Samudra Hindia yang tiada henti menghantam tebing karang terjal. Garis meliuk tanpa putus mencerminkan laku prihatin, kesinambungan budi pekerti luhur, dan ketabahan batin manusia Jawa dalam mengarungi pasang surut gelombang kehidupan tanpa pernah kehilangan kehormatan martabatnya.',
            style: AppTheme.inter(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // ExpansionCard: Asal Daerah & Sejarah
          _buildExpansionCard(
            title: 'Asal Daerah & Sejarah',
            icon: Icons.history_edu,
            body: 'Diciptakan pada era Panembahan Senopati (pendiri Kesultanan Mataram Islam) saat melakukan semedi meditasi di pesisir tebing Parangtritis. Gerak dinamis air laut yang tak kenal menyerah mengilhami terciptanya garis diagonal sakral ini.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // ExpansionCard: Makna Filosofis Simbolik
          _buildExpansionCard(
            title: 'Makna Filosofis Simbolik',
            icon: Icons.psychology,
            body: 'Berasal dari kata Parang (batu karang/lereng terjal) dan Kusumo (bunga bangsawan). Motif ini memuat amanah luhur bahwa keturunan ningrat sejati wajib mengharumkan nama bangsa laksana bunga mekar dengan ketegaran jiwa sekeras batu karang.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // ExpansionCard: Penggunaan Tradisional & Pakem
          _buildExpansionCard(
            title: 'Penggunaan Tradisional & Pakem',
            icon: Icons.verified_user_outlined,
            body: 'Tergolong sebagai batik larangan sakral (awisan dalem). Dahulu kala hanya boleh dikenakan keluarga sentana dalem keraton pada upacara tukar cincin pernikahan adat dan pisowanan agung menghadap Sri Sultan atau Sunan.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Halaman 2: Karakteristik Sesuai PDF Page 5
  Widget _buildPage5Karakteristik(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Karakteristik Motif Parang\nKusumo',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Kenali struktur anatomi visual dan ornamen pakem yang membedakan Parang Kusumo dari ragam parang lainnya dalam tradisi keraton Mataram.',
            style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GALERI DETAIL CANTING & WARNA',
                style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppTheme.primary),
              ),
              Text(
                '3 Titik Pengamatan',
                style: AppTheme.inter(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card Jejak Lilin Malam Alami
          GestureDetector(
            onTap: () => _showZoomImageDialog(context, isDark),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF382516),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: Icon(Icons.architecture, size: 80, color: Colors.white.withValues(alpha: 0.15)),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('• Struktur Utama • 45° Lereng', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jejak Lilin Malam Alami', style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Tetesan canting membentuk kontur lereng ombak tanpa henti', style: AppTheme.inter(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2 Grid Bawah: Ornamen Mlinjon & Warna Khas Sogan
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Isen-Isen Halus', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Text('Ornamen Mlinjon & Lidah Api', style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Tekstur belah ketupat mini pengisi ruang kosong motif.', style: AppTheme.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Pewarna Alami', style: TextStyle(color: AppTheme.primaryDark, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Text('Warna Khas Sogan', style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Paduan soga tua, oker kuning, dan krem mori murni.', style: AppTheme.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Pakem Anatomi Visual Sesuai PDF
          Row(
            children: [
              Container(width: 4, height: 18, color: const Color(0xFF5A3416)),
              const SizedBox(width: 8),
              Text('4 Pakem Anatomi Visual', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildPakemItem('1. Sudut Kemiringan 45°', 'Garis lereng sejajar membentang miring 45 derajat tanpa terputus, melambangkan kontinuitas tekad ksatria Jawa.', isDark),
          _buildPakemItem('2. Ornamen Mlinjon & Lidah Api', 'Lekukan menyerupai lidah api berulang yang diselingi belah ketupat mikro, memberi keseimbangan ritme dinamis.', isDark),
          _buildPakemItem('3. Tiga Warna Sakral Sogan', 'Didominasi warna cokelat soga tua (soga jambal), kuning oker keemasan (kayu tegeran), dan dasar putih gading mori prima.', isDark),
          _buildPakemItem('4. Dimensi Khusus Ningrat', 'Ukuran lidah parang berkisar 3-4 cm, dikhususkan bagi bangsawan dan keturunan keraton Mataram.', isDark),
        ],
      ),
    );
  }

  // Halaman 3: Galeri Motif Sesuai PDF Page 6
  Widget _buildPage6Galeri(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galeri Motif Parang Kusumo',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Dokumentasi visual kain mori prima karya sentana dalem keraton dan pengrajin batik tulis.',
            style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),

          // Banner Hero Galeri
          GestureDetector(
            onTap: () => _showZoomImageDialog(context, isDark),
            child: Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF382516),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library, size: 54, color: AppTheme.accentGold),
                    const SizedBox(height: 8),
                    Text('Arsip Kain Batik Tulis Parang Kusumo', style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Ketuk untuk perbesar detail', style: AppTheme.inter(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4 Grid Foto Dokumentasi Proses Membatik Sesuai PDF Page 6
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildGaleriItem('Proses Mencanting', Icons.brush, isDark),
              _buildGaleriItem('Kain Sogan Klasik', Icons.texture, isDark),
              _buildGaleriItem('Jejak Lilin Lereng', Icons.waves, isDark),
              _buildGaleriItem('Detail Isen Canting', Icons.grain, isDark),
            ],
          ),
        ],
      ),
    );
  }

  // Halaman 4: Kuis Modul Sesuai PDF Page 7
  Widget _buildPage7KuisModul(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kuis Modul',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Hero Banner: Selamat mengerjakan!
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6E4324),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat\nmengerjakan!',
                  style: AppTheme.satoshi(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selesaikan materi hari ini untuk meningkatkan keahlian canting dan membuka lencana baru.',
                  style: AppTheme.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card 1: 45 Menit - Teori (Nilai Teori: 80% / 100%) Sesuai PDF
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text('45 Menit', style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nilai Teori: 80%',
                        style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Kuis Pemahaman Teori & Filosofi', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Uji wawasan mengenai pakem, sejarah, dan makna ornamen lereng Parang Kusumo.', style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TheoryQuizScreen(module: widget.module),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3416),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Mulai Kuis Teori', style: AppTheme.satoshi(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Praktik (Belum Dilakukan / Penilaian Kamera) Sesuai PDF
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text('Praktikum', style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.module.practiceDone ? 'Selesai: 70%' : 'Belum Dilakukan',
                        style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Kuis Praktik: Scan Kain Batikmu', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Gunakan kamera AI untuk mencocokkan goresan canting dan ornamen karyamu dengan pakem daerah.', style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PracticeQuizScreen(module: widget.module),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3416),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Mulai Kuis Praktik', style: AppTheme.satoshi(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionCard({
    required String title,
    required IconData icon,
    required String body,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.primary, size: 22),
        title: Text(title, style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
            child: Text(body, style: AppTheme.inter(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPakemItem(String title, String desc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 4),
          Text(desc, style: AppTheme.inter(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildGaleriItem(String label, IconData icon, bool isDark) {
    return GestureDetector(
      onTap: () => _showZoomImageDialog(context, isDark),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2B231D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: Colors.white70),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
