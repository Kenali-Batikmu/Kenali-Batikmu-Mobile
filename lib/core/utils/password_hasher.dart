import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Pengelola hash kata sandi dengan format ber-versi dan salt acak per pengguna.
///
/// Format aktif: `scrypt$N$r$p$<salt base64>$<hash base64>`
/// Format lama (warisan) tetap dapat diverifikasi agar pengguna lama tidak
/// terkunci, lalu di-upgrade otomatis saat login berhasil (rehash-on-login).
class PasswordHasher {
  PasswordHasher._();

  static const int _scryptN = 16384;
  static const int _scryptR = 8;
  static const int _scryptP = 1;
  static const int _saltLength = 16;
  static const int _keyLength = 32;
  static const String _scryptPrefix = 'scrypt';
  static const String _legacySalt = 'kenali_batikmu_salt_2026';

  /// Membuat hash kata sandi baru dengan salt acak.
  static String hashPassword(String password) {
    final salt = _generateSalt(_saltLength);
    return _scryptHash(password, salt, _scryptN, _scryptR, _scryptP);
  }

  /// Memverifikasi kata sandi terhadap hash tersimpan (multi-format).
  static bool verify(String password, String storedHash) {
    if (storedHash.isEmpty) return false;
    if (storedHash.startsWith('$_scryptPrefix\$')) {
      return _verifyScrypt(password, storedHash);
    }
    // Format warisan: SHA-256 dengan salt statis (64 karakter heksadesimal).
    return _constantTimeEquals(_legacySha256(password), storedHash.toLowerCase());
  }

  /// Menandai apakah hash perlu ditingkatkan ke format/parameter terbaru.
  static bool needsRehash(String storedHash) {
    if (!storedHash.startsWith('$_scryptPrefix\$')) return true;
    final parts = storedHash.split('\$');
    if (parts.length != 6) return true;
    final n = int.tryParse(parts[1]) ?? 0;
    final r = int.tryParse(parts[2]) ?? 0;
    final p = int.tryParse(parts[3]) ?? 0;
    return n < _scryptN || r < _scryptR || p < _scryptP;
  }

  static bool _verifyScrypt(String password, String storedHash) {
    final parts = storedHash.split('\$');
    if (parts.length != 6) return false;
    final n = int.tryParse(parts[1]);
    final r = int.tryParse(parts[2]);
    final p = int.tryParse(parts[3]);
    if (n == null || r == null || p == null) return false;
    if (n < 2 || (n & (n - 1)) != 0) return false;

    try {
      final salt = base64Decode(parts[4]);
      final expected = base64Decode(parts[5]);
      final actual = _scryptBytes(password, salt, n, r, p, expected.length);
      return _constantTimeEqualsBytes(actual, expected);
    } catch (_) {
      return false;
    }
  }

  static String _scryptHash(String password, Uint8List salt, int n, int r, int p) {
    final derived = _scryptBytes(password, salt, n, r, p, _keyLength);
    return '$_scryptPrefix\$$n\$$r\$$p\$'
        '${base64Encode(salt)}\$${base64Encode(derived)}';
  }

  static Uint8List _scryptBytes(
    String password,
    Uint8List salt,
    int n,
    int r,
    int p,
    int keyLength,
  ) {
    final scrypt = Scrypt()..init(ScryptParameters(n, r, p, keyLength, salt));
    final output = Uint8List(keyLength);
    scrypt.deriveKey(Uint8List.fromList(utf8.encode(password)), 0, output, 0);
    return output;
  }

  static Uint8List _generateSalt(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static String _legacySha256(String password) {
    return sha256.convert(utf8.encode('$_legacySalt$password')).toString();
  }

  static bool _constantTimeEquals(String a, String b) {
    return _constantTimeEqualsBytes(
      Uint8List.fromList(utf8.encode(a)),
      Uint8List.fromList(utf8.encode(b)),
    );
  }

  static bool _constantTimeEqualsBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
