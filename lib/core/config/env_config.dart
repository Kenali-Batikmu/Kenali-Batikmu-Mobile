import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pengelola variabel lingkungan aplikasi dari `--dart-define` / `.env`.
/// Prioritas baca:
/// 1. Compile-time `--dart-define` / `--dart-define-from-file=.env`
/// 2. Asset `.env` yang dimuat saat bootstrap aplikasi
class EnvConfig {
  EnvConfig._();

  static const _assetPath = '.env';

  static const Map<String, String> _compileTimeDefines = {
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
    'EMAILJS_SERVICE_ID': String.fromEnvironment('EMAILJS_SERVICE_ID'),
    'EMAILJS_TEMPLATE_ID': String.fromEnvironment('EMAILJS_TEMPLATE_ID'),
    'EMAILJS_PUBLIC_KEY': String.fromEnvironment('EMAILJS_PUBLIC_KEY'),
  };

  static final Map<String, String> _values = {};

  /// Memuat file `.env` dari asset bundle secara non-blocking dan aman.
  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      loadFromString(raw);
    } catch (e) {
      debugPrint(
        'EnvConfig info: File $_assetPath tidak dimuat ($e). Menggunakan dart-define.',
      );
    }
  }

  /// Memuat isi teks `.env` langsung ke memori (dipakai oleh [load] dan unit test).
  static void loadFromString(String content) {
    _values
      ..clear()
      ..addAll(_parse(content));
  }

  /// Mengosongkan nilai `.env` di memori (khusus isolasi pengujian).
  @visibleForTesting
  static void resetForTest() => _values.clear();

  /// Mengambil nilai konfigurasi berdasarkan [key], atau string kosong jika belum diatur.
  static String get(String key) {
    final defined = _compileTimeDefines[key]?.trim() ?? '';
    if (defined.isNotEmpty) return defined;

    return _values[key]?.trim() ?? '';
  }

  /// Memeriksa apakah seluruh [keys] terisi nilai valid (bukan kosong atau placeholder).
  static bool hasAllConfigured(Iterable<String> keys) {
    return keys.every((key) {
      final value = get(key);
      return value.isNotEmpty && !value.contains('YOUR_');
    });
  }

  static Map<String, String> _parse(String content) {
    final result = <String, String>{};
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final normalized =
          line.startsWith('export ') ? line.substring(7).trim() : line;
      final eqIndex = normalized.indexOf('=');
      if (eqIndex <= 0) continue;

      final key = normalized.substring(0, eqIndex).trim();
      var value = normalized.substring(eqIndex + 1).trim();

      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }

      if (key.isNotEmpty) {
        result[key] = value;
      }
    }
    return result;
  }
}

