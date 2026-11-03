import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import 'youtube_webview_config.dart';

/// Pemutar YouTube yang berjalan langsung di dalam aplikasi.
///
/// Memuat iframe YouTube lewat `loadHtmlString` dengan `baseUrl` domain HTTPS
/// netral, sehingga iframe menerima Referer yang sah (penyebab galat 152/153).
/// Bila pemutaran tertanam gagal, pemutar beralih ke halaman tonton mobile
/// YouTube agar video tetap dapat ditonton tanpa meninggalkan aplikasi.
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

  /// Batas waktu memuat halaman sebelum dianggap gagal.
  static const Duration _loadTimeout = Duration(seconds: 15);

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
      ..addJavaScriptChannel(
        YoutubeWebViewConfig.bridgeChannel,
        onMessageReceived: (message) {
          // Dilaporkan dari dalam halaman bila YouTube menolak pemutaran.
          _fallbackToMobileWatch();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true) return;
            // Gagal memuat halaman utama: coba halaman tonton mobile.
            _fallbackToMobileWatch();
          },
        ),
      );

    _controller = controller;
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    _usingMobileWatch = false;

    final controller = _controller;
    if (controller == null) return;

    try {
      await YoutubeWebViewConfig.load(controller, widget.videoId);
    } catch (_) {
      await _fallbackToMobileWatch();
      return;
    }

    // Halaman HTML lokal selalu "selesai" dimuat, sehingga kegagalan pemutaran
    // tidak terdeteksi oleh event navigasi. Pengawas waktu dipakai sebagai
    // jaring pengaman bila halaman tidak pernah selesai dimuat.
    await Future<void>.delayed(_loadTimeout);
    if (!mounted || _hasError || !_isLoading) return;
    await _fallbackToMobileWatch();
  }

  Future<void> _fallbackToMobileWatch() async {
    if (!mounted) return;
    if (_usingMobileWatch) {
      _showError();
      return;
    }
    _usingMobileWatch = true;
    try {
      await YoutubeWebViewConfig.loadMobileWatch(_controller!, widget.videoId);
    } catch (_) {
      _showError();
    }
  }

  void _showError() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
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
