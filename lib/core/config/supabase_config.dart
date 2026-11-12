import 'env_config.dart';

/// Konfigurasi Layanan Cloud Supabase (Kenali Batikmu)
/// URL Proyek dan Public Anonymous Key dibaca dari `.env` atau `--dart-define-from-file=.env`
class SupabaseConfig {
  /// URL endpoint project Supabase
  static String get url => EnvConfig.get('SUPABASE_URL');

  /// Anon Key (Public Key) Supabase
  /// Ambil dari Dashboard Supabase: Project Settings -> API -> Project API keys (anon public)
  static String get anonKey => EnvConfig.get('SUPABASE_ANON_KEY');

  /// Memeriksa apakah Supabase sudah memiliki URL dan API key yang valid
  static bool get isConfigured =>
      EnvConfig.hasAllConfigured(const ['SUPABASE_URL', 'SUPABASE_ANON_KEY']);
}
