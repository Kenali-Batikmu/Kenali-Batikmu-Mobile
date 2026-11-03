import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import 'youtube_webview_config.dart';

/// Pemutar YouTube utama yang berjalan langsung di dalam aplikasi.
///
/// Memuat halaman perantara dari GitHub Pages (referer domain sah), dan
/// otomatis beralih ke halaman tonton mobile YouTube bila halaman perantara
/// belum tersedia. Dengan begitu video tetap dapat diputar tanpa membuka
/// aplikasi YouTube.
class InlineYoutubePlayer extends StatefulWidget {
  final String videoId;
  final String title;
  final VoidCallback? onOpenFullscreen;

  /// Bila true, pemutar mengisi seluruh ruang yang tersedia (mode layar penuh)
  /// dan tidak dibatasi rasio 16:9.
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
  bool _usingFallback = false;

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
            // Hanya tanggapi kegagalan halaman perantara GitHub Pages,
            // bukan kegagalan sumber daya lain di dalam halaman.
            final uri = error.request?.uri;
            if (uri == null) return;
            if (!YoutubeWebViewConfig.hasEmbedPage) return;
            if (!uri.host.contains('github.io')) return;
            _switchToFallback();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) return;
            _switchToFallback();
          },
        ),
      );

    _controller = controller;
    _load();
  }

  /// Beralih ke halaman tonton mobile sekali saja, lalu tampilkan galat
  /// yang bisa diketuk untuk memuat ulang bila cadangan pun gagal.
  Future<void> _switchToFallback() async {
    if (!mounted) return;
    if (!_usingFallback) {
      _usingFallback = true;
      try {
        await YoutubeWebViewConfig.loadMobileWatch(_controller!, widget.videoId);
        return;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    _usingFallback = false;
    try {
      final controller = _controller;
      if (controller == null) return;
      await YoutubeWebViewConfig.load(controller, widget.videoId);
    } catch (_) {
      await _switchToFallback();
    }
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
      onTap: _load,
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
