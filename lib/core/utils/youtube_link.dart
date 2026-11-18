/// Utilitas untuk mengambil ID video dari berbagai bentuk tautan YouTube.
///
/// Contoh yang didukung:
/// - `https://www.youtube.com/watch?v=VIDEOID`
/// - `https://youtu.be/VIDEOID`
/// - `https://www.youtube.com/embed/VIDEOID`
/// - `https://www.youtube.com/shorts/VIDEOID`
/// - `https://m.youtube.com/watch?v=VIDEOID&t=30s`
class YoutubeLink {
  YoutubeLink._();

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Mengembalikan ID video (11 karakter) atau `null` bila tautan tidak valid.
  static String? extractVideoId(String? url) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) return null;

    // ID mentah (bukan URL) juga diterima.
    if (_idPattern.hasMatch(raw)) return raw;

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (!host.contains('youtube.com') && !host.contains('youtu.be')) {
      return null;
    }

    final fromQuery = uri.queryParameters['v'];
    if (fromQuery != null && _idPattern.hasMatch(fromQuery)) return fromQuery;

    for (final segment in uri.pathSegments) {
      if (_idPattern.hasMatch(segment)) return segment;
    }

    return null;
  }

  /// Tautan tonton standar untuk ID tertentu.
  static Uri watchUri(String videoId) =>
      Uri.parse('https://www.youtube.com/watch?v=$videoId');
}
