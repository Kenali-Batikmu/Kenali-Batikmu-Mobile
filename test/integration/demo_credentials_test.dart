import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('Kredensial akun bawaan (regresi login gagal)', () {
    test('akun demo bawaan dapat diverifikasi dengan kata sandi terdokumentasi',
        () async {
      // Pulihkan database ke kondisi bawaan agar test tidak bergantung urutan
      await DatabaseHelper.instance.migrateFresh();
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);

      final demo = await DatabaseHelper.instance.getUserByEmail('sekar@batikmu.id');
      expect(demo, isNotNull, reason: 'akun demo tidak ditemukan di database');

      final hash = demo!['password_hash'] as String?;
      expect(hash, isNotNull);
      expect(PasswordHasher.verify('Batikmu123#', hash!), isTrue,
          reason: 'kata sandi akun demo harus valid');
      expect(PasswordHasher.verify('kata-sandi-salah', hash), isFalse);
    });

    test('hash tersimpan selalu memakai format ber-versi dan bersalt acak', () async {
      await DatabaseHelper.instance.migrateFresh();
      final db = await DatabaseHelper.instance.database;
      final users = await db!.query('users');
      expect(users, isNotEmpty);

      for (final user in users) {
        final hash = (user['password_hash'] as String?) ?? '';
        expect(hash.startsWith('scrypt\$'), isTrue,
            reason: 'hash ${user['email']} belum memakai format scrypt ber-versi');
        expect(hash.split('\$').length, equals(6));
        expect(PasswordHasher.needsRehash(hash), isFalse);
      }
    });
  });
}
