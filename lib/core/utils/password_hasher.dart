import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  // Hash password dengan salt sesuai OWASP M10
  static String hashPassword(String password, {String salt = "kenali_batikmu_salt_2026"}) {
    final bytes = utf8.encode("$salt$password");
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verify(String password, String storedHash, {String salt = "kenali_batikmu_salt_2026"}) {
    return hashPassword(password, salt: salt) == storedHash;
  }
}
