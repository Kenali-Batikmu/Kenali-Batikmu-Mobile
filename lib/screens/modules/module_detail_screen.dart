import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import 'widgets/zoom_image_dialog.dart';
import 'widgets/module_completion_dialog.dart';
import 'widgets/pillar_history_view.dart';
import 'widgets/pillar_character_view.dart';
import 'widgets/pillar_gallery_view.dart';
import 'widgets/pillar_quiz_preview.dart';

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

    // Jika tidak disetting / kosong / hanya whitespace, biarkan controller null (tidak ada border video)
    if (youtubeUrl == null || youtubeUrl.trim().isEmpty) {
      _youtubeController = null;
      return;
    }

    final parsedId = YoutubePlayerController.convertUrlToId(youtubeUrl.trim());
    if (parsedId == null || parsedId.trim().isEmpty) {
      _youtubeController = null;
      return;
    }

    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: parsedId.trim(),
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
        enableJavaScript: true,
        origin: 'https://www.youtube-nocookie.com',
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _youtubeController?.close();
    super.dispose();
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
              clipBehavior: Clip.none,
              onPageChanged: (index) {
                final provider = context.read<AppProvider>();
                if (_activeStep == 0 && index > 0) provider.updatePillarProgress(widget.module.id, 'history');
                if (_activeStep == 1 && index > 1) provider.updatePillarProgress(widget.module.id, 'character');
                if (_activeStep == 2 && index > 2) provider.updatePillarProgress(widget.module.id, 'gallery');

                // Jeda video secara otomatis saat user geser ke tab lain
                if (index != 0) {
                  _youtubeController?.pauseVideo();
                }

                setState(() => _activeStep = index);
              },
              children: [
                _KeepAlivePage(
                  child: SingleChildScrollView(
                    child: PillarHistoryView(
                      module: widget.module,
                      youtubeController: _youtubeController,
                      onZoomImage: () => showZoomImageDialog(context, isDark),
                      isDark: isDark,
                    ),
                  ),
                ),
                _KeepAlivePage(
                  child: SingleChildScrollView(
                    child: PillarCharacterView(
                      module: widget.module,
                      isDark: isDark,
                    ),
                  ),
                ),
                _KeepAlivePage(
                  child: SingleChildScrollView(
                    child: PillarGalleryView(
                      module: widget.module,
                      onZoomImage: () => showZoomImageDialog(context, isDark),
                      isDark: isDark,
                    ),
                  ),
                ),
                _KeepAlivePage(
                  child: SingleChildScrollView(
                    child: PillarQuizPreview(
                      module: module,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Navigation Stepper (Tombol Panah Kiri, Dots Indikator, Tombol Panah Kanan)
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

                // Tombol Kanan
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
                      onPressed: () => showModuleCompletionDialog(context, module),
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
}

/// Widget pembungkus untuk mempertahankan state halaman PageView saat di-swipe,
/// sehingga WebView / YoutubePlayer tidak di-destroy oleh Flutter dan Android Surface tetap utuh.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
