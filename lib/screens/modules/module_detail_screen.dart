import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import 'theory_quiz_screen.dart';
import 'practice_quiz_screen.dart';

class ModuleDetailScreen extends StatefulWidget {
  final ModuleModel module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  late int _activeStep; 
  late PageController _pageController;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    
    // Tentukan halaman awal (Lanjutkan Belajar) berdasarkan komponen yang belum diselesaikan
    if (!widget.module.historyDone) {
      _activeStep = 0;
    } else if (!widget.module.characterDone) {
      _activeStep = 1;
    } else if (!widget.module.galleryDone) {
      _activeStep = 2;
    } else {
      _activeStep = 3; // Kuis
    }
    
    _pageController = PageController(initialPage: _activeStep);
    _initYoutubePlayer();
  }

  void _initYoutubePlayer() {
    final youtubeUrl = widget.module.content?.sejarahDanFilosofi.youtubeUrl;
    // Menggunakan video Dokumenter Batik Indonesia (UNESCO) yang diizinkan untuk di-embed
    String videoId = 'd5X1d-rX2D8'; 

    if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
      final parsedId = YoutubePlayerController.convertUrlToId(youtubeUrl);
      if (parsedId != null && parsedId.isNotEmpty) {
        videoId = parsedId;
      }
    }

    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _youtubeController?.close();
    super.dispose();
  }

  void _showZoomImageDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppTheme.darkSurface : const Color(0xFF221A14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Detail Motif Batik',
                          style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 320,
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
                        // Gambar aktual bisa ditaruh di sini nantinya dengan Image.asset(...)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCompletionDialog(BuildContext context, ModuleModel module) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE4BA73), Color(0xFFD49B45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Selamat! Modul Tuntas',
                  textAlign: TextAlign.center,
                  style: AppTheme.satoshi(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF2C1810),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kamu telah berhasil mempelajari dan menyelesaikan seluruh evaluasi pada ${module.title}.',
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackground : const Color(0xFFF9F6F0),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorder : const Color(0xFFEFE7DA),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_rounded, size: 13, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Kuis Teori',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${module.quizScore ?? 100}',
                              style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 32, width: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFDCD2C4)),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.brush_rounded, size: 13, color: Color(0xFFE65100)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Kuis Praktik',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${module.practiceScore ?? 100}%',
                              style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFFE65100)),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 32, width: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFDCD2C4)),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF5A3416)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Progres',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '100%',
                              style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF5A3416)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A3416),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Selesai & Kembali ke Modul',
                          style: AppTheme.satoshi(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
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
    final provider = context.watch<AppProvider>();
    final module = provider.modules.firstWhere(
      (m) => m.id == widget.module.id,
      orElse: () => widget.module,
    );
    final isBothQuizzesDone = module.quizDone && module.practiceDone;

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
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                final provider = context.read<AppProvider>();
                if (_activeStep == 0 && index > 0) provider.updatePillarProgress(widget.module.id, 'history');
                if (_activeStep == 1 && index > 1) provider.updatePillarProgress(widget.module.id, 'character');
                if (_activeStep == 2 && index > 2) provider.updatePillarProgress(widget.module.id, 'gallery');
                
                setState(() => _activeStep = index);
              },
              children: [
                SingleChildScrollView(child: _buildPage4TeoriFilosofi(context, isDark)),
                SingleChildScrollView(child: _buildPage5Karakteristik(context, isDark)),
                SingleChildScrollView(child: _buildPage6Galeri(context, isDark)),
                SingleChildScrollView(child: _buildPage7KuisModul(context, isDark, module)),
              ],
            ),
          ),
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
                        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),

                // Dots Indikator 4 Halaman (Teori, Karakteristik, Galeri, Kuis)
                Row(
                  children: List.generate(4, (index) {
                    final isActive = index == _activeStep;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      },
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

                // Tombol Kanan (Panah Lanjut di Halaman 0,1,2 | Sembunyi jika Kuis belum tuntas | Centang jika Kuis sudah tuntas)
                if (_activeStep < 3)
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
                        if (_activeStep == 0) provider.updatePillarProgress(widget.module.id, 'history');
                        if (_activeStep == 1) provider.updatePillarProgress(widget.module.id, 'character');
                        if (_activeStep == 2) provider.updatePillarProgress(widget.module.id, 'gallery');

                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  )
                else if (isBothQuizzesDone)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE4BA73), Color(0xFFD49B45)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                      tooltip: 'Selesaikan Modul',
                      onPressed: () => _showCompletionDialog(context, module),
                    ),
                  )
                else
                  const SizedBox(width: 50, height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Halaman 1: Teori & Filosofi Sesuai PDF Page 4
  Widget _buildPage4TeoriFilosofi(BuildContext context, bool isDark) {
    final content = widget.module.content;
    if (content == null) return const Center(child: CircularProgressIndicator());
    final sejarah = content.sejarahDanFilosofi;

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
                  child: widget.module.coverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(widget.module.coverImage!, fit: BoxFit.cover),
                        )
                      : Center(child: Icon(Icons.waves, size: 90, color: Colors.white.withValues(alpha: 0.18))),
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
              'MODUL ${widget.module.orderNo} • TEORI & FILOSOFI',
              style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.module.title,
            style: AppTheme.satoshi(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${content.origin} • Estimasi Baca ${content.estimatedTime}',
            style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          if (_youtubeController != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: YoutubePlayer(
                controller: _youtubeController!,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Section Hakikat & Simbol Ombak Laut Selatan
          Text(
            'Hakikat & Simbol',
            style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            sejarah.deskripsiUtama,
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
            body: sejarah.asalDaerah,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // ExpansionCard: Makna Filosofis Simbolik
          _buildExpansionCard(
            title: 'Makna Filosofis Simbolik',
            icon: Icons.psychology,
            body: sejarah.maknaFilosofis,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // ExpansionCard: Penggunaan Tradisional & Pakem
          _buildExpansionCard(
            title: 'Penggunaan Tradisional & Pakem',
            icon: Icons.verified_user_outlined,
            body: sejarah.penggunaan,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Halaman 2: Karakteristik Sesuai PDF Page 5
  Widget _buildPage5Karakteristik(BuildContext context, bool isDark) {
    final content = widget.module.content;
    if (content == null) return const Center(child: CircularProgressIndicator());
    final charData = content.karakteristik;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Karakteristik ${widget.module.title}',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            charData.deskripsi,
            style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 20),

          Text(
            'Struktur & Ornamen Visual',
            style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Text-only List: Struktur Utama
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(charData.strukturUtama.badge, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(charData.strukturUtama.title, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(charData.strukturUtama.desc, style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Text-only List: Ornamen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(charData.ornamen.badge, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(charData.ornamen.title, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(charData.ornamen.desc, style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Text-only List: Warna
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(charData.warna.badge, style: const TextStyle(color: AppTheme.primaryDark, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(charData.warna.title, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(charData.warna.desc, style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pakem Anatomi Visual
          Row(
            children: [
              Container(width: 4, height: 18, color: const Color(0xFF5A3416)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${charData.pakemList.length} Pakem Anatomi Visual', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...charData.pakemList.map((pakem) => _buildPakemItem(pakem.title, pakem.desc, isDark)),
        ],
      ),
    );
  }

  // Halaman 3: Galeri Motif Sesuai PDF Page 6
  Widget _buildPage6Galeri(BuildContext context, bool isDark) {
    final content = widget.module.content;
    if (content == null) return const Center(child: CircularProgressIndicator());
    final galeriList = content.galeri;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galeri ${widget.module.title}',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Dokumentasi visual karya sentana dalem keraton dan pengrajin batik tulis.',
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: galeriList.isNotEmpty && galeriList[0].imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(galeriList[0].imageUrl, fit: BoxFit.cover, color: Colors.black.withValues(alpha: 0.2), colorBlendMode: BlendMode.darken),
                          )
                        : const SizedBox(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library, size: 54, color: AppTheme.accentGold),
                        const SizedBox(height: 8),
                        Text('Arsip Kain Batik Tulis', style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Ketuk untuk perbesar detail', style: AppTheme.inter(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Grid Foto Dokumentasi Proses Membatik
          GridView.builder(
            itemCount: galeriList.length > 1 ? galeriList.length - 1 : 0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final galeri = galeriList[index + 1];
              return _buildGaleriItem(galeri.caption, galeri.imageUrl, isDark);
            },
          ),
        ],
      ),
    );
  }

  // Halaman 4: Kuis Modul Sesuai PDF Page 7
  Widget _buildPage7KuisModul(BuildContext context, bool isDark, ModuleModel module) {
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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B341B), Color(0xFF7E4A25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -15,
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 96,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'Evaluasi Modul',
                            style: AppTheme.satoshi(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
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
                      'Uji pemahaman dan hasil karyamu di sini untuk menyelesaikan modul dan melihat sejauh mana kamu mengenali motif batik ini.',
                      style: AppTheme.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card 1: Kuis Teori
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: module.quizDone
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : (isDark ? AppTheme.darkBorder : const Color(0xFFF0EAE1)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: module.quizDone
                      ? AppTheme.primary.withValues(alpha: 0.05)
                      : AppTheme.primary.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: module.quizDone
                            ? AppTheme.primary.withValues(alpha: 0.12)
                            : (isDark ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.accentGold.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 24,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Kuis Teori',
                              style: AppTheme.satoshi(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF2C1810),
                              ),
                              maxLines: 2,
                            ),
                          ),
                          if (module.quizDone) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 13, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Nilai: ${module.quizScore ?? 100}',
                                    style: AppTheme.satoshi(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppTheme.secondaryLight : AppTheme.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Uji wawasan mendalam mengenai pakem, sejarah, dan makna ornamen.',
                  style: AppTheme.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TheoryQuizScreen(module: module)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: module.quizDone ? Colors.transparent : AppTheme.primary,
                    foregroundColor: module.quizDone ? AppTheme.primary : Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: module.quizDone ? AppTheme.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        module.quizDone ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                        size: 18,
                        color: module.quizDone
                            ? (isDark ? AppTheme.secondaryLight : AppTheme.primary)
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        module.quizDone ? 'Kerjakan Ulang' : 'Mulai Kuis',
                        style: AppTheme.satoshi(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: module.quizDone
                              ? (isDark ? AppTheme.secondaryLight : AppTheme.primary)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card 2: Kuis Praktik
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: module.practiceDone
                    ? const Color(0xFFF57C00).withValues(alpha: 0.4)
                    : (isDark ? AppTheme.darkBorder : const Color(0xFFF0EAE1)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: module.practiceDone
                      ? const Color(0xFFF57C00).withValues(alpha: 0.05)
                      : AppTheme.primary.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: module.practiceDone
                            ? const Color(0xFFF57C00).withValues(alpha: 0.12)
                            : (isDark ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.accentGold.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.brush_rounded,
                        size: 24,
                        color: module.practiceDone ? const Color(0xFFF57C00) : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Kuis Praktik',
                              style: AppTheme.satoshi(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF2C1810),
                              ),
                              maxLines: 2,
                            ),
                          ),
                          if (module.practiceDone) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF57C00).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFF57C00).withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 13, color: Color(0xFFF57C00)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Akurasi: ${module.practiceScore ?? 100}%',
                                    style: AppTheme.satoshi(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE65100),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Gambarlah motif batik ini, lalu pindai hasil karyamu untuk melihat seberapa mirip dengan aslinya.',
                  style: AppTheme.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PracticeQuizScreen(module: module)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: module.practiceDone ? Colors.transparent : AppTheme.primary,
                    foregroundColor: module.practiceDone ? const Color(0xFFF57C00) : Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: module.practiceDone ? const Color(0xFFF57C00) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        module.practiceDone ? Icons.refresh_rounded : Icons.camera_alt_outlined,
                        size: 18,
                        color: module.practiceDone
                            ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100))
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        module.practiceDone ? 'Pindai Ulang' : 'Mulai Praktik',
                        style: AppTheme.satoshi(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                          color: module.practiceDone
                              ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100))
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: AppTheme.inter(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPakemItem(String title, String desc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.transparent),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryDark)),
                const SizedBox(height: 6),
                Text(desc, style: AppTheme.inter(fontSize: 12, height: 1.5, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaleriItem(String label, String imageUrl, bool isDark) {
    return GestureDetector(
      onTap: () => _showZoomImageDialog(context, isDark),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2B231D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(imageUrl, fit: BoxFit.cover, color: Colors.black.withValues(alpha: 0.3), colorBlendMode: BlendMode.darken),
                    )
                  : const Center(child: Icon(Icons.image, size: 38, color: Colors.white70)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
