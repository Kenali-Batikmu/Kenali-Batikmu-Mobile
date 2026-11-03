import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';

/// Pemutar video YouTube di dalam aplikasi berbasis WebView.
/// Dipakai sebagai jalur cadangan ketika pemutar iframe tertanam gagal
/// (mis. galat referer/pemutaran), sehingga video tetap dapat ditonton
/// tanpa meninggalkan aplikasi.
class InAppYoutubePlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const InAppYoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<InAppYoutubePlayerScreen> createState() => _InAppYoutubePlayerScreenState();
}

class _InAppYoutubePlayerScreenState extends State<InAppYoutubePlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
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
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://www.youtube.com/embed/${widget.videoId}'
          '?playsinline=1&rel=0&modestbranding=1',
        ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VIDEO PEMBAHASAN',
              style: AppTheme.satoshi(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.primary,
              ),
            ),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 44,
                      color: isDark ? Colors.white54 : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Video tidak dapat dimuat di dalam aplikasi.',
                      textAlign: TextAlign.center,
                      style: AppTheme.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _controller.reload(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
