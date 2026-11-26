import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/utils/youtube_link.dart';

void main() {
  group('QC Unit Tests: YoutubeLink (Parsing & OWASP URL Validation)', () {
    test('mengekstrak video ID 11 karakter dari seluruh format tautan resmi YouTube', () {
      const expectedId = 'dQw4w9WgXcQ';

      expect(
        YoutubeLink.extractVideoId('https://www.youtube.com/watch?v=$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeLink.extractVideoId('https://youtu.be/$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeLink.extractVideoId('https://www.youtube.com/embed/$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeLink.extractVideoId('https://www.youtube.com/shorts/$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeLink.extractVideoId('https://m.youtube.com/watch?v=$expectedId&t=45s'),
        equals(expectedId),
      );
      expect(
        YoutubeLink.extractVideoId('  $expectedId  '),
        equals(expectedId),
      );
    });

    test('menolak input kosong, null, ID cacat, dan domain non-YouTube', () {
      expect(YoutubeLink.extractVideoId(null), isNull);
      expect(YoutubeLink.extractVideoId(''), isNull);
      expect(YoutubeLink.extractVideoId('   '), isNull);
      expect(YoutubeLink.extractVideoId('short123'), isNull);
      expect(YoutubeLink.extractVideoId('https://vimeo.com/12345678901'), isNull);
      expect(YoutubeLink.extractVideoId('https://example.com/watch?v=dQw4w9WgXcQ'), isNull);
    });

    test('[OWASP Security] menolak domain spoofing dan skema berbahaya (open-redirect / XSS)', () {
      // Standar industri OWASP: validasi host wajib exact match atau subdomain sah,
      // tidak boleh memakai substring .contains("youtube.com") yang mudah dipalsukan.
      expect(
        YoutubeLink.extractVideoId('https://evil-youtube.com/watch?v=dQw4w9WgXcQ'),
        isNull,
        reason: 'Domain spoofing evil-youtube.com harus ditolak',
      );
      expect(
        YoutubeLink.extractVideoId('https://youtube.com.attacker.org/watch?v=dQw4w9WgXcQ'),
        isNull,
        reason: 'Subdomain attacker yang menyelipkan youtube.com harus ditolak',
      );
      expect(
        YoutubeLink.extractVideoId('javascript:alert(1)//youtube.com/dQw4w9WgXcQ'),
        isNull,
        reason: 'Skema javascript: harus ditolak',
      );
    });

    test('watchUri menghasilkan tautan HTTPS kanonik yang valid', () {
      final uri = YoutubeLink.watchUri('dQw4w9WgXcQ');
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('www.youtube.com'));
      expect(uri.path, equals('/watch'));
      expect(uri.queryParameters['v'], equals('dQw4w9WgXcQ'));
    });
  });
}
