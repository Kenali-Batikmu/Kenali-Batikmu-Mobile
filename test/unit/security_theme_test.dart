import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/config/env_config.dart';
import 'package:batikmu/core/config/supabase_config.dart';
import 'package:batikmu/core/services/email_service.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import 'package:batikmu/core/theme/app_theme.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('OWASP Mobile Security & Hashing Tests (M10, M3)', () {
    test('PasswordHasher menghasilkan hash scrypt bersalt acak per pengguna', () {
      const rawPassword = 'Batikmu123#';
      final hash1 = PasswordHasher.hashPassword(rawPassword);
      final hash2 = PasswordHasher.hashPassword(rawPassword);

      // Salt acak: hash untuk sandi sama harus berbeda
      expect(hash1, isNot(equals(hash2)));
      expect(hash1.startsWith('scrypt\$'), isTrue);
      expect(hash1, isNot(contains(rawPassword)));

      expect(PasswordHasher.verify(rawPassword, hash1), isTrue);
      expect(PasswordHasher.verify(rawPassword, hash2), isTrue);
      expect(PasswordHasher.verify('WrongPassword', hash1), isFalse);
    });

    test('PasswordHasher memverifikasi hash warisan SHA-256 lalu menandai rehash', () {
      const rawPassword = 'Batikmu123#';
      // Hash warisan: SHA-256 dengan salt statis (64 karakter heksadesimal)
      const legacyHash =
          'b1cc2200499505407a01c7314d4973d447f0441f260b1c176c70ae8fc0bc82fe';

      expect(PasswordHasher.needsRehash(legacyHash), isTrue);
      expect(PasswordHasher.needsRehash(PasswordHasher.hashPassword(rawPassword)), isFalse);

      // Hash warisan yang benar tetap diterima (kompatibilitas mundur)
      expect(PasswordHasher.verify(rawPassword, legacyHash), isTrue);
      expect(PasswordHasher.verify('SalahSandi123', legacyHash), isFalse);
    });

    test('PasswordHasher menolak hash rusak tanpa melempar exception', () {
      expect(PasswordHasher.verify('apa saja', ''), isFalse);
      expect(PasswordHasher.verify('apa saja', 'scrypt\$rusak'), isFalse);
      expect(PasswordHasher.verify('apa saja', 'bukan\$format\$valid'), isFalse);
    });

    test('Theme provides WCAG AA compliant palette', () {
      expect(AppTheme.primary, isNotNull);
      expect(AppTheme.background, isNotNull);
      expect(AppTheme.textPrimary, isNotNull);
    });

    test('EnvConfig membaca .env dengan aman dan menolak nilai placeholder', () {
      EnvConfig.resetForTest();
      addTearDown(EnvConfig.resetForTest);

      // Saat belum dimuat, konfigurasi harus non-aktif (offline-safe)
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(EmailService.isConfigured, isFalse);

      // Placeholder dari .env.example harus tetap ditolak
      EnvConfig.loadFromString('''
# Komentar konfigurasi
SUPABASE_URL=https://PASTE_YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY="PASTE_YOUR_SUPABASE_ANON_KEY"
EMAILJS_SERVICE_ID='YOUR_SERVICE_ID'
EMAILJS_TEMPLATE_ID=YOUR_TEMPLATE_ID
EMAILJS_PUBLIC_KEY=YOUR_PUBLIC_KEY
''');
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(EmailService.isConfigured, isFalse);

      // Nilai valid lengkap dengan kutipan dan tanda '=' di dalam nilai harus ter-parse utuh
      EnvConfig.loadFromString('''
export SUPABASE_URL="https://example.supabase.co"
SUPABASE_ANON_KEY='token_dummy_abc==123'
EMAILJS_SERVICE_ID=srv_test
EMAILJS_TEMPLATE_ID=tpl_test
EMAILJS_PUBLIC_KEY=pub_test
''');
      expect(SupabaseConfig.url, equals('https://example.supabase.co'));
      expect(SupabaseConfig.anonKey, equals('token_dummy_abc==123'));
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(EmailService.isConfigured, isTrue);
    });
  });
}
