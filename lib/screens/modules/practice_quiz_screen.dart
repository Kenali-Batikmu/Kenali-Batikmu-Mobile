import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';

class PracticeQuizScreen extends StatefulWidget {
  final ModuleModel module;

  const PracticeQuizScreen({super.key, required this.module});

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  bool _isAnalyzing = false;
  bool _hasResult = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_hasResult) {
      return _buildHasilPenilaianView(context, isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: isDark ? Colors.white : AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('KENALI BATIKMU', style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.primary)),
            Text('Detail Modul - Kuis Praktikum', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Frame Kamera Viewfinder Sesuai PDF Page 10
              Container(
                height: 480,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B231D),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Stack(
                  children: [
                    // Background Mock Kamera Tekstur Batik
                    Positioned.fill(
                      child: Center(
                        child: Icon(Icons.waves, size: 180, color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),

                    // Top Bar Kamera: Grid icon, Pill Instruksi, Flash icon
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                            child: const Icon(Icons.grid_on, color: Colors.white, size: 18),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text('Arahkan kamera ke kain batikmu', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                            child: const Icon(Icons.flash_on, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),

                    // Kotak Fokus Kuning Emas dengan Titik-titik Analisis Sesuai PDF Page 10
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.accentGold, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 60,
                              left: 60,
                              child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle)),
                            ),
                            Positioned(
                              top: 100,
                              right: 60,
                              child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle)),
                            ),
                            Positioned(
                              bottom: 60,
                              left: 80,
                              child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Bar Kamera: Galeri Thumbnail, Tombol Shutter Lingkaran Putih, Switch Camera
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white70),
                            ),
                            child: const Icon(Icons.photo_library, color: Colors.white, size: 22),
                          ),
                          GestureDetector(
                            onTap: _isAnalyzing
                                ? null
                                : () async {
                                    setState(() => _isAnalyzing = true);
                                    await Future.delayed(const Duration(milliseconds: 700));
                                    setState(() {
                                      _isAnalyzing = false;
                                      _hasResult = true;
                                    });
                                  },
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                              child: Center(
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Kirim untuk Dinilai Sesuai PDF Page 10
              ElevatedButton(
                onPressed: _isAnalyzing
                    ? null
                    : () async {
                        final provider = Provider.of<AppProvider>(context, listen: false);
                        setState(() => _isAnalyzing = true);
                        await Future.delayed(const Duration(milliseconds: 800));
                        if (!mounted) return;
                        provider.savePracticeResult(widget.module.id, 0.70, true);
                        setState(() {
                          _isAnalyzing = false;
                          _hasResult = true;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A3416),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isAnalyzing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Menilai...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 16),
                          SizedBox(width: 8),
                          Text('Kirim untuk Dinilai'),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Kembali ke Halaman Kuis',
                    style: AppTheme.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Layar Hasil Penilaian Sesuai PDF Page 11
  Widget _buildHasilPenilaianView(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: isDark ? Colors.white : AppTheme.textPrimary,
          onPressed: () => setState(() => _hasResult = false),
        ),
        title: Column(
          children: [
            Text('KENALI BATIKMU', style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.primary)),
            Text('Hasil Penilaian', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Foto Karyamu & Info Waktu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF382516),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 18),
                          Text('Foto\nKaryamu', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.draw, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text('KUIS PRAKTIK MODUL 2', style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Diambil pada 14.32 WIB', style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(() => _hasResult = false),
                          child: const Row(
                            children: [
                              Icon(Icons.replay, size: 14, color: AppTheme.primaryDark),
                              SizedBox(width: 4),
                              Text('Ambil Ulang', style: TextStyle(color: AppTheme.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Card Kecocokan Asal Daerah Sesuai PDF Page 11
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.radar, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kecocokan Asal Daerah', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Berdasarkan ornamen, canting, & isen', style: AppTheme.inter(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 20),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Peringkat 1: Sumatra 70% (Paling Cocok)
                  _buildDaerahItem('S', 'Sumatra', 70, isTop: true, badge: 'Paling Cocok'),
                  const SizedBox(height: 14),

                  // Peringkat 2: Jawa 60%
                  _buildDaerahItem('J', 'Jawa', 60),
                  const SizedBox(height: 14),

                  // Peringkat 3: Malang 40%
                  _buildDaerahItem('M', 'Malang', 40),
                  const SizedBox(height: 18),

                  Text(
                    'ⓘ  Persentase menunjukkan kemiripan pola, warna, dan komposisi karyamu dengan ciri khas tiap daerah.',
                    style: AppTheme.inter(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Ketentuan Penilaian Sesuai PDF Page 11
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rule, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Ketentuan Penilaian', style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildKetentuanBullet('≥ 70%: Sangat Mirip', const Color(0xFFD49B45)),
                  const SizedBox(height: 6),
                  _buildKetentuanBullet('50% – 69%: Cukup Mirip', const Color(0xFF5A3416)),
                  const SizedBox(height: 6),
                  _buildKetentuanBullet('< 50%: Perlu Dilatih', const Color(0xFF8A827B)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Coba Lagi & Kembali ke Beranda
            ElevatedButton.icon(
              onPressed: () => setState(() => _hasResult = false),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A3416),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),

            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.home_outlined, size: 16, color: AppTheme.textSecondary),
                label: Text('Kembali ke Beranda', style: AppTheme.inter(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaerahItem(String letter, String name, int percent, {bool isTop = false, String? badge}) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isTop ? const Color(0xFFF7E6D2) : const Color(0xFFEBE6E1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(letter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5A3416))),
              ),
            ),
            const SizedBox(width: 10),
            Text(name, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFCECDA), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: AppTheme.accentGold),
                    const SizedBox(width: 4),
                    Text(badge, style: const TextStyle(color: Color(0xFF7A4B29), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Text('$percent%', style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF5A3416))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0EBE1),
            valueColor: AlwaysStoppedAnimation<Color>(isTop ? AppTheme.accentGold : const Color(0xFF5A3416)),
          ),
        ),
      ],
    );
  }

  Widget _buildKetentuanBullet(String text, Color dotColor) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
