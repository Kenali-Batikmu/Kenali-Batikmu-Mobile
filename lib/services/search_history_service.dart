import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan riwayat pencarian modul (maks 5 ID) di shared_preferences.
class SearchHistoryService {
  static const String _key = 'search_history_module_ids';
  static const int _maxItems = 5;

  /// Ambil daftar ID modul riwayat (terbaru di depan).
  static Future<List<int>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
  }

  /// Tambahkan ID modul ke riwayat. Jika sudah ada, pindahkan ke atas.
  static Future<void> addToHistory(int moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key)?.toList() ?? [];
    final idStr = moduleId.toString();

    // Hapus duplikat
    list.remove(idStr);
    // Sisipkan di depan
    list.insert(0, idStr);
    // Batasi maksimal
    if (list.length > _maxItems) {
      list.removeRange(_maxItems, list.length);
    }

    await prefs.setStringList(_key, list);
  }

  /// Hapus satu item dari riwayat.
  static Future<void> removeFromHistory(int moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key)?.toList() ?? [];
    list.remove(moduleId.toString());
    await prefs.setStringList(_key, list);
  }

  /// Kosongkan seluruh riwayat.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
