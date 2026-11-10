/// Konfigurasi Layanan Cloud Supabase (Kenali Batikmu)
/// URL Proyek dan Public Anonymous Key untuk sinkronisasi Database & Storage
class SupabaseConfig {
  /// URL endpoint project Supabase
  static const String url = 'https://hmlwjakttschineizyig.supabase.co';

  /// Anon Key (Public Key) Supabase
  /// Ambil dari Dashboard Supabase: Project Settings -> API -> Project API keys (anon public)
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtbHdqYWt0dHNjaGluZWl6eWlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI4MDI3NjUsImV4cCI6MjEwODM3ODc2NX0.ONhjEpMPTgAMcp5c_lpR8VnBOPWmTlFN1RTXMt_vrEs';

  /// Memeriksa apakah Supabase sudah memiliki API key yang valid
  static bool get isConfigured =>
      anonKey.isNotEmpty && !anonKey.contains('PASTE_YOUR_');
}
