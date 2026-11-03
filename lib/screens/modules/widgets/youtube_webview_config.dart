import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Konfigurasi pemutaran YouTube di dalam WebView aplikasi.
///
/// **Mengapa perlu halaman perantara?**
/// YouTube menolak pemutaran tertanam bila halaman tidak memiliki origin yang
/// sah. WebView aplikasi tidak memiliki domain sehingga selalu berakhir dengan:
/// - galat **152** bila origin/referer tidak valid atau `null`,
/// - galat **153** bila referer tidak dikirim sama sekali.
///
/// Karena itu pemutar memuat `docs/player.html` dari CDN statis yang menyajikan
/// berkas dengan `Content-Type: text/html` (origin HTTPS sungguhan), sehingga
/// iframe YouTube menerima referer yang sah dan dapat diputar.
///
/// Bila semua sumber gagal, pemutar beralih ke halaman tonton mobile YouTube
/// agar video tetap dapat ditonton tanpa meninggalkan aplikasi.
class YoutubeWebViewConfig {
  YoutubeWebViewConfig._();

  /// Halaman perantara yang menyajikan `docs/player.html` sebagai HTML.
  /// Gunakan cabang yang masih aktif; perbarui bila nama cabang berubah.
  static const List<String> embedPageTemplates = [
    'https://raw.githack.com/Kenali-Batikmu/Kenali-Batikmu-Mobile/hafizh/docs/player.html?v={id}',
    'https://rawcdn.githack.com/Kenali-Batikmu/Kenali-Batikmu-Mobile/hafizh/docs/player.html?v={id}',
  ];

  /// Cadangan terakhir: halaman tonton mobile resmi YouTube.
  static const String mobileWatchTemplate =
      'https://m.youtube.com/watch?v={id}';

  /// User-Agent peramban Chrome Android asli. UA bawaan WebView mengandung
  /// penanda "wv" yang membuat YouTube menolak pemutaran (galat 152).
  static const String browserUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';

  static int get embedSourceCount => embedPageTemplates.length;

  static Uri embedPageUri(int index, String videoId) => Uri.parse(
        embedPageTemplates[index].replaceAll('{id}', videoId),
      );

  static Uri mobileWatchUri(String videoId) => Uri.parse(
        mobileWatchTemplate.replaceAll('{id}', videoId),
      );

  /// Menyiapkan pengaturan WebView sebelum halaman dimuat.
  static Future<void> prepare(WebViewController controller) async {
    if (kIsWeb) return;
    if (!Platform.isAndroid) return;

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      try {
        // Izinkan pemutaran tanpa gestur tambahan.
        await platform.setMediaPlaybackRequiresUserGesture(false);
      } catch (_) {}
      try {
        final cookieManager = WebViewCookieManager().platform;
        if (cookieManager is AndroidWebViewCookieManager) {
          // Sesi YouTube membutuhkan cookie pihak ketiga.
          await cookieManager.setAcceptThirdPartyCookies(platform, true);
        }
      } catch (_) {}
    }
  }

  /// Memuat halaman perantara ke-[index].
  static Future<void> loadEmbedPage(
    WebViewController controller,
    int index,
    String videoId,
  ) async {
    await prepare(controller);
    await controller.loadRequest(embedPageUri(index, videoId));
  }

  /// Memuat halaman tonton mobile YouTube sebagai cadangan terakhir.
  static Future<void> loadMobileWatch(
    WebViewController controller,
    String videoId,
  ) async {
    await prepare(controller);
    await controller.loadRequest(mobileWatchUri(videoId));
  }
}
