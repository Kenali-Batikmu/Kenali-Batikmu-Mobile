import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Konfigurasi pemutaran YouTube di dalam WebView aplikasi.
///
/// Mengapa memakai halaman perantara (GitHub Pages)?
/// YouTube menolak pemutaran tertanam bila halaman tidak memiliki origin yang
/// sah. WebView aplikasi tidak punya domain, sehingga selalu berakhir dengan:
/// - galat **152** bila referer diisi `youtube.com`/kosong-tidak-valid,
/// - galat **153** bila referer tidak dikirim sama sekali.
///
/// Dengan memuat `player.html` dari GitHub Pages, iframe YouTube mendapat
/// referer domain HTTPS sungguhan sehingga pemutaran diterima.
///
/// Bila halaman perantara belum tersedia (404 / gagal dimuat), pemutar otomatis
/// beralih ke halaman tonton mobile YouTube agar video tetap bisa diputar
/// tanpa meninggalkan aplikasi.
class YoutubeWebViewConfig {
  YoutubeWebViewConfig._();

  /// Alamat halaman perantara di GitHub Pages.
  /// Kosongkan string ini untuk langsung memakai halaman tonton mobile.
  static const String embedPageUrl =
      'https://kenali-batikmu.github.io/Kenali-Batikmu-Mobile/player.html';

  /// Cadangan: halaman tonton mobile resmi YouTube.
  static const String mobileWatchUrl = 'https://m.youtube.com/watch';

  /// User-Agent peramban Chrome Android asli. UA bawaan WebView mengandung
  /// penanda "wv" yang membuat YouTube menolak pemutaran (galat 152).
  static const String browserUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';

  static bool get hasEmbedPage => embedPageUrl.trim().isNotEmpty;

  static Uri embedPageUri(String videoId) =>
      Uri.parse('$embedPageUrl?v=$videoId');

  static Uri mobileWatchUri(String videoId) =>
      Uri.parse('$mobileWatchUrl?v=$videoId');

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

  /// Memuat pemutar utama (halaman perantara bila tersedia).
  static Future<void> load(WebViewController controller, String videoId) async {
    await prepare(controller);
    final uri = hasEmbedPage ? embedPageUri(videoId) : mobileWatchUri(videoId);
    await controller.loadRequest(uri);
  }

  /// Memuat cadangan halaman tonton mobile.
  static Future<void> loadMobileWatch(
    WebViewController controller,
    String videoId,
  ) async {
    await controller.loadRequest(mobileWatchUri(videoId));
  }
}
