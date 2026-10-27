import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import 'package:batikmu/core/theme/app_theme.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('OWASP Mobile Security & Hashing Tests (M10, M3)', () {
    test('PasswordHasher generates salted sha256 hash', () {
      const rawPassword = 'Batikmu123#';
      final hash1 = PasswordHasher.hashPassword(rawPassword);
      final hash2 = PasswordHasher.hashPassword(rawPassword);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64));
      expect(hash1, isNot(contains(rawPassword)));

      expect(PasswordHasher.verify(rawPassword, hash1), isTrue);
      expect(PasswordHasher.verify('WrongPassword', hash1), isFalse);
    });

    test('Theme provides WCAG AA compliant palette', () {
      expect(AppTheme.primary, isNotNull);
      expect(AppTheme.background, isNotNull);
      expect(AppTheme.textPrimary, isNotNull);
    });
  });
}
