import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Konfigurasi pemutaran YouTube di dalam WebView aplikasi.
///
/// **Penyebab galat yang sudah diuji langsung ke endpoint YouTube:**
/// - `origin`/`Referer` = `https://www.youtube.com` → **152-4**
///   (YouTube menolak origin yang mengacu ke dirinya sendiri)
/// - `Referer` tidak dikirim sama sekali → **153**
/// - `origin`/`Referer` domain HTTPS lain (contoh: `example.com`) → **OK**
///   dengan `playableInEmbed=true`
///
/// Karena itu halaman pemutar dimuat dengan `loadHtmlString` dan `baseUrl`
/// berupa domain HTTPS netral (`example.com`, domain yang memang dicadangkan
/// untuk contoh/dokumentasi). Dengan begitu iframe memperoleh Referer yang sah
/// tanpa memerlukan hosting tambahan.
class YoutubeWebViewConfig {
  YoutubeWebViewConfig._();

  /// Origin netral untuk base URL sekaligus Referer iframe.
  static const String origin = 'https://example.com';

  /// User-Agent peramban Chrome Android asli. UA bawaan WebView mengandung
  /// penanda "wv" yang membuat YouTube menolak pemutaran (galat 152).
  static const String browserUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';

  /// Nama kanal JavaScript yang melaporkan kegagalan pemutaran ke Flutter.
  static const String bridgeChannel = 'BatikmuYoutube';

  /// Cadangan terakhir bila pemutaran tertanam tetap gagal: halaman tonton
  /// mobile YouTube (tetap di dalam aplikasi).
  static Uri mobileWatchUri(String videoId) =>
      Uri.parse('https://m.youtube.com/watch?v=$videoId');

  static String buildPlayerHtml(String videoId) {
    final embedUrl = 'https://www.youtube.com/embed/$videoId'
        '?playsinline=1&rel=0&modestbranding=1&fs=1&origin=$origin';
    return '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport"
        content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    html, body { margin: 0; padding: 0; height: 100%; background: #000; overflow: hidden; }
    iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
  </style>
</head>
<body>
  <iframe
    src="$embedUrl"
    title="Video pembahasan motif batik"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowfullscreen
    referrerpolicy="origin">
  </iframe>
  <script>
    // YouTube mengirim pesan 'onError' (mis. galat 101/150) lewat postMessage.
    // Pesan itu diteruskan ke Flutter agar pemutar dapat beralih ke cadangan.
    (function () {
      var reported = false;
      function report(reason) {
        if (reported) return;
        reported = true;
        try {
          if (window.$bridgeChannel && window.$bridgeChannel.postMessage) {
            window.$bridgeChannel.postMessage(reason);
          }
        } catch (e) {}
      }
      window.addEventListener('message', function (event) {
        var data = event.data;
        if (typeof data !== 'string') return;
        if (data.indexOf('onError') !== -1) report('playback-error');
      });
      // Jaring pengaman: bila iframe tetap kosong setelah 10 detik.
      setTimeout(function () {
        var frame = document.querySelector('iframe');
        if (!frame || !frame.src || frame.src.indexOf('about:blank') === 0) {
          report('not-loaded');
        }
      }, 10000);
    })();
  </script>
</body>
</html>
''';
  }

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

  /// Memuat pemutar YouTube untuk [videoId] langsung di dalam aplikasi.
  static Future<void> load(WebViewController controller, String videoId) async {
    await prepare(controller);
    await controller.loadHtmlString(
      buildPlayerHtml(videoId),
      baseUrl: origin,
    );
  }

  /// Memuat halaman tonton mobile YouTube sebagai cadangan.
  static Future<void> loadMobileWatch(
    WebViewController controller,
    String videoId,
  ) async {
    await prepare(controller);
    await controller.loadRequest(mobileWatchUri(videoId));
  }
}
