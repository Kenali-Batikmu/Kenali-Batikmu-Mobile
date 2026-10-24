/// Konfigurasi Layanan Cloud Supabase (Kenali Batikmu)
/// URL Proyek dan Public Anonymous Key untuk sinkronisasi Database & Storage
class SupabaseConfig {
  /// URL endpoint project Supabase
  static const String url = 'https://hmlwjakttschineizyig.supabase.co';

  /// Anon Key (Public Key) Supabase
  /// Ambil dari Dashboard Supabase: Project Settings -> API -> Project API keys (anon public)
  static const String anonKey = 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE';

  /// Memeriksa apakah Supabase sudah memiliki API key yang valid
  static bool get isConfigured =>
      anonKey.isNotEmpty && !anonKey.contains('PASTE_YOUR_');
}
