import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import 'youtube_webview_config.dart';

/// Pemutar YouTube yang berjalan langsung di dalam aplikasi.
///
/// Urutan sumber yang dicoba:
/// 1. halaman perantara `docs/player.html` (origin HTTPS sah → embed diterima),
/// 2. cermin CDN kedua bila yang pertama gagal,
/// 3. halaman tonton mobile YouTube sebagai cadangan terakhir.
///
/// Jadi video tetap dapat diputar tanpa membuka aplikasi YouTube.
class InlineYoutubePlayer extends StatefulWidget {
  final String videoId;
  final String title;
  final VoidCallback? onOpenFullscreen;

  /// Bila true, pemutar mengisi seluruh ruang tersedia (mode layar penuh).
  final bool fill;

  const InlineYoutubePlayer({
    super.key,
    required this.videoId,
    required this.title,
    this.onOpenFullscreen,
    this.fill = false,
  });

  @override
  State<InlineYoutubePlayer> createState() => _InlineYoutubePlayerState();
}

class _InlineYoutubePlayerState extends State<InlineYoutubePlayer> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _usingMobileWatch = false;
  int _sourceIndex = 0;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(YoutubeWebViewConfig.browserUserAgent)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onHttpError: (error) {
            final uri = error.request?.uri;
            if (uri == null) return;
            // Hanya kegagalan memuat halaman perantara yang ditindaklanjuti.
            if (!uri.host.contains('githack.com')) return;
            _advanceSource();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) return;
            final failingUrl = error.url ?? '';
            // Kegagalan sumber daya di dalam halaman embed diabaikan;
            // yang ditangani hanya kegagalan navigasi halaman perantara.
            if (failingUrl.contains('githack.com')) {
              _advanceSource();
              return;
            }
            if (_usingMobileWatch) {
              _showError();
            }
          },
        ),
      );

    _controller = controller;
    _loadCurrentSource();
  }

  /// Pindah ke sumber berikutnya, lalu ke halaman tonton mobile, lalu galat.
  Future<void> _advanceSource() async {
    if (!mounted) return;

    if (!_usingMobileWatch &&
        _sourceIndex + 1 < YoutubeWebViewConfig.embedSourceCount) {
      _sourceIndex++;
      await _loadCurrentSource();
      return;
    }

    if (!_usingMobileWatch) {
      _usingMobileWatch = true;
      try {
        await YoutubeWebViewConfig.loadMobileWatch(
          _controller!,
          widget.videoId,
        );
        return;
      } catch (_) {}
    }

    _showError();
  }

  void _showError() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  Future<void> _loadCurrentSource() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final controller = _controller;
      if (controller == null) return;
      await YoutubeWebViewConfig.loadEmbedPage(
        controller,
        _sourceIndex,
        widget.videoId,
      );
    } catch (_) {
      await _advanceSource();
    }
  }

  /// Memuat ulang dari sumber pertama (dipakai tombol coba lagi).
  Future<void> _retry() async {
    _sourceIndex = 0;
    _usingMobileWatch = false;
    await _loadCurrentSource();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final player = ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          if (_hasError)
            _buildErrorState(isDark)
          else if (_controller != null)
            WebViewWidget(controller: _controller!),

          if (_isLoading && !_hasError)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.accentGold,
                  ),
                ),
              ),
            ),

          if (!_hasError && !_isLoading)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onOpenFullscreen,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Layar penuh',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.fill) return player;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(aspectRatio: 16 / 9, child: player),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return GestureDetector(
      onTap: _retry,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://img.youtube.com/vi/${widget.videoId}/hqdefault.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => ColoredBox(
              color: isDark ? AppTheme.darkSurface : const Color(0xFF2B2020),
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 34),
                const SizedBox(height: 6),
                Text(
                  'Ketuk untuk memuat ulang video',
                  style: AppTheme.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
