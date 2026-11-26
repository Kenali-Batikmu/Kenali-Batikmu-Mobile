import 'dart:async';
import 'package:flutter/foundation.dart';

/// Controller reusable untuk logika "Load More on Scroll" (batch pagination).
///
/// Mengatur jumlah item yang ditampilkan dari list sumber secara bertahap per batch.
/// Memory-safe: hanya menambah [_displayCount], tidak meng-copy data.
///
/// ### Alur batch loading (batchSize = 4, total = 20):
/// ```
/// Awal buka: 4 modul
/// Scroll ke bawah -> Ikon load berputar (4 detik) -> Bertambah 4 (jadi 8 modul)
/// Scroll ke bawah -> Ikon load berputar (4 detik) -> Bertambah 4 (jadi 12 modul)
/// Scroll ke bawah -> Ikon load berputar (4 detik) -> Bertambah 4 (jadi 16 modul)
/// Scroll ke bawah -> Ikon load berputar (4 detik) -> Bertambah 4 (jadi 20 modul -> Selesai)
/// ```
class LoadMoreController<T> extends ChangeNotifier {
  /// Jumlah item per batch yang di-load. Default: 4.
  final int batchSize;

  /// Durasi delay loading sebelum modul baru muncul (3 detik, sesuai rentang 3-5 detik).
  final Duration loadingDelay;

  List<T> _source = [];
  int _displayCount = 0;
  bool _isLoading = false;
  bool _allLoaded = false;

  LoadMoreController({
    this.batchSize = 4,
    this.loadingDelay = const Duration(seconds: 3),
  });

  // ─── Getters ──────────────────────────────────────────────────────────

  /// Item yang saat ini ditampilkan (slice dari source).
  List<T> get displayedItems =>
      _source.isEmpty ? [] : _source.sublist(0, _displayCount.clamp(0, _source.length));

  /// Sedang dalam proses loading batch berikutnya.
  bool get isLoading => _isLoading;

  /// Semua item dari source telah ditampilkan.
  bool get allLoaded => _allLoaded;

  /// Total item dari sumber data.
  int get totalCount => _source.length;

  /// Jumlah item yang saat ini ditampilkan.
  int get displayCount => _displayCount;

  // ─── Operasi ──────────────────────────────────────────────────────────

  /// Set sumber data baru dan reset tampilan ke batch pertama (4 modul).
  void setSource(List<T> source) {
    _source = source;

    if (_source.length <= batchSize) {
      _displayCount = _source.length;
      _allLoaded = true;
    } else {
      _displayCount = batchSize;
      _allLoaded = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Memuat batch berikutnya dengan jeda waktu loading (ikon load).
  ///
  /// Guard: jika sudah loading atau semua sudah tampil, langsung return.
  Future<void> loadNextBatch() async {
    if (_isLoading || _allLoaded) return;

    _isLoading = true;
    notifyListeners();

    // Jeda waktu loading agar ikon load berputar selama 4 detik
    await Future.delayed(loadingDelay);

    final newCount = (_displayCount + batchSize).clamp(0, _source.length);
    _displayCount = newCount;
    _allLoaded = _displayCount >= _source.length;
    _isLoading = false;

    notifyListeners();
  }

  /// Reset kembali ke batch pertama (misal setelah filter pencarian berubah).
  void reset() {
    if (_source.length <= batchSize) {
      _displayCount = _source.length;
      _allLoaded = true;
    } else {
      _displayCount = batchSize;
      _allLoaded = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _source = [];
    super.dispose();
  }
}
