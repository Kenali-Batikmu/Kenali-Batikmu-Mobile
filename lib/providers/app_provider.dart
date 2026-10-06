import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../models/app_models.dart';

class AppProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  List<ModuleModel> _modules = [];
  List<BatikMotifModel> _motifs = [];
  List<ScanHistoryModel> _scanHistories = [];
  bool _isDarkMode = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ModuleModel> get modules => _modules;
  List<BatikMotifModel> get motifs => _motifs;
  List<ScanHistoryModel> get scanHistories => _scanHistories;
  bool get isDarkMode => _isDarkMode;

  // Stats kalkulasi dinamis sesuai PDF Page 3 & Page 12
  int get completedModulesCount => _modules.where((m) => m.progressPercent >= 100).length;
  int get totalModulesCount => _modules.length;
  int get overallProgressPercent => totalModulesCount > 0 ? ((completedModulesCount / totalModulesCount) * 100).round() : 0;
  int get scannedMotifsCount => _scanHistories.length;

  AppProvider() {
    _initInMemoryDefaultData();
    initApp();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
    _saveThemePref(value);
  }

  Future<void> _saveThemePref(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', value);
    } catch (_) {}
  }

  void _initInMemoryDefaultData() {
    // 1. Akun Default Sekar Ayu Kinanti (@sekar_artisan) Sesuai PDF Page 12, 13, 14
    _currentUser = UserModel(
      id: 1,
      name: 'Sekar Ayu Kinanti',
      email: 'sekar@batikmu.id',
      createdAt: '2026-03-01T08:00:00Z',
    );

    // 2. Daftar 6 Motif Utama Sesuai PDF Page 2 & Skema Database
    _motifs = [
      BatikMotifModel(
        id: 1,
        name: 'Cecek Hasan',
        slug: 'cecek-hasan',
        originRegion: 'Pekalongan',
        shortDescription: 'Ornamen isen halus berupa titik-titik melingkar membentuk geometri harmonis.',
        mlClassIndex: 0,
      ),
      BatikMotifModel(
        id: 2,
        name: 'Parang Rusak',
        slug: 'parang-rusak',
        originRegion: 'Yogyakarta & Surakarta',
        shortDescription: 'Pakem keraton agung melambangkan ombak samudera dan perjuangan batin.',
        mlClassIndex: 1,
      ),
      BatikMotifModel(
        id: 3,
        name: 'Truntum',
        slug: 'truntum',
        originRegion: 'Surakarta',
        shortDescription: 'Bintang kasih sayang abadi, lambang cinta tulus yang senantiasa bersemi.',
        mlClassIndex: 2,
      ),
      BatikMotifModel(
        id: 4,
        name: 'Parang Kusumo',
        slug: 'parang-kusumo',
        originRegion: 'Surakarta & Yogyakarta',
        shortDescription: 'Batik larangan keraton bermakna ksatria dengan keharuman budi pekerti bunga.',
        mlClassIndex: 3,
      ),
      BatikMotifModel(
        id: 5,
        name: 'Kawung',
        slug: 'kawung',
        originRegion: 'Yogyakarta',
        shortDescription: 'Empat bulatan lonjong melambangkan kesucian hati dan harmoni semesta.',
        mlClassIndex: 4,
      ),
      BatikMotifModel(
        id: 6,
        name: 'Mega Mendung',
        slug: 'mega-mendung',
        originRegion: 'Cirebon',
        shortDescription: 'Gradasi lapisan awan membawa keteduhan, kesabaran, dan kelapangan dada.',
        mlClassIndex: 5,
      ),
    ];

    // 3. 11 Modul Belajar (6 Selesai = 55% Progress Sesuai PDF Page 3 & 12)
    _modules = [
      ModuleModel(
        id: 1,
        motifId: 2,
        title: 'Sejarah & Filosofi Ragam\nMotif Parang',
        description: 'Pelajari asal usul lereng ombak Panembahan Senopati dan pakem larangan Mataram.',
        orderNo: 1,
        progressPercent: 100,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: true,
      ),
      ModuleModel(
        id: 2,
        motifId: 1,
        title: 'Pengenalan Kain Mori\nPrimissima & Canting',
        description: 'Mengenal kualitas serat mori primissima dan pemilihan cucuk canting nglowongi dan isen.',
        orderNo: 2,
        progressPercent: 100,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: true,
      ),
      ModuleModel(
        id: 3,
        motifId: 4,
        title: 'Harmoni Isen-Isen:\nOrnamen & Pola Cecek',
        description: 'Latihan menjaga kestabilan aliran malam cucuk canting pada kain mori prima yang terbentang di gawangan.',
        orderNo: 3,
        progressPercent: 65,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: false,
      ),
      ModuleModel(
        id: 4,
        motifId: 3,
        title: 'Teknik Pewarnaan Alami\nKulit Soga Jambal',
        description: 'Proses ekstraksi warna soga klasik alami untuk menghasilkan gradasi cokelat keraton.',
        orderNo: 4,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
      ),
      ModuleModel(
        id: 5,
        motifId: 2,
        title: 'Proses Nglorod:\nPelepasan Malam Lilin',
        description: 'Melarutkan lilin malam pada air mendidih untuk memunculkan warna murni kain.',
        orderNo: 5,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
      ),
      ModuleModel(
        id: 6,
        motifId: 5,
        title: 'Filosofi & Pola Geometri\nMotif Kawung',
        description: 'Memahami makna empat kelopak bunga aren sebagai lambang kemurnian hati ksatria.',
        orderNo: 6,
        progressPercent: 100,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: true,
      ),
      ModuleModel(
        id: 7,
        motifId: 6,
        title: 'Gradasi Warna Teduh\nMotif Mega Mendung',
        description: 'Teknik kuasan tujuh tingkatan gradasi warna langit pesisir Cirebon.',
        orderNo: 7,
        progressPercent: 100,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: true,
      ),
      ModuleModel(
        id: 8,
        motifId: 3,
        title: 'Taburan Bintang Kasih\nSayang Truntum',
        description: 'Batik cinta tulus diciptakan Kanjeng Ratu Kencana permaisuri Pakubuwana III.',
        orderNo: 8,
        progressPercent: 100,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: true,
      ),
      ModuleModel(
        id: 9,
        motifId: 4,
        title: 'Harapan & Kemuliaan\nMotif Sidomukti',
        description: 'Batik pengantin agung Jawa bermakna kemakmuran abadi dan ketenteraman.',
        orderNo: 9,
        progressPercent: 100,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: true,
      ),
      ModuleModel(
        id: 10,
        motifId: 1,
        title: 'Keanekaragaman Jagad\nRaya Sekar Jagad',
        description: 'Peta keindahan nusantara dalam komposisi pulau dan kembang puspa warna-warni.',
        orderNo: 10,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
      ),
      ModuleModel(
        id: 11,
        motifId: 2,
        title: 'Rekonstruksi Jiwa\nMotif Tambal',
        description: 'Menambal kekurangan diri dan memperbaiki budi pekerti manusia luhur.',
        orderNo: 11,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
      ),
    ];

    // 4. 6 Riwayat Scan Sesuai Profil PDF Page 12
    _scanHistories = [
      ScanHistoryModel(
        id: 1,
        scanType: 'kuismu',
        motifName: 'Motif Parang Kusumo',
        score: 0.70,
        passed: true,
        createdAt: '2 hari lalu',
      ),
      ScanHistoryModel(
        id: 2,
        scanType: 'universal',
        motifName: 'Filosofi & Pola Kawung',
        score: 0.88,
        passed: true,
        createdAt: '5 hari lalu',
      ),
      ScanHistoryModel(
        id: 3,
        scanType: 'universal',
        motifName: 'Teknik Celup Kulit Soga',
        score: 0.92,
        passed: true,
        createdAt: '1 mgg lalu',
      ),
      ScanHistoryModel(
        id: 4,
        scanType: 'universal',
        motifName: 'Motif Mega Mendung',
        score: 0.85,
        passed: true,
        createdAt: '2 mgg lalu',
      ),
      ScanHistoryModel(
        id: 5,
        scanType: 'universal',
        motifName: 'Motif Parang Rusak',
        score: 0.78,
        passed: true,
        createdAt: '3 mgg lalu',
      ),
      ScanHistoryModel(
        id: 6,
        scanType: 'universal',
        motifName: 'Motif Cecek Hasan',
        score: 0.90,
        passed: true,
        createdAt: '1 bln lalu',
      ),
    ];
  }

  Future<void> initApp() async {
    _isLoading = false; // Memastikan UI instan tidak terhalang
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;

      // Coba load database SQLite di background jika tersedia secara non-blocking
      final db = await DatabaseHelper.instance.database;
      if (db != null) {
        final users = await db.query('users', limit: 1);
        if (users.isNotEmpty) {
          _currentUser = UserModel.fromMap(users.first);
        }
      }
    } catch (e) {
      debugPrint('Info sync SQLite: $e (Aplikasi berjalan dalam Interactive Prototype Mode)');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulasi delay autentikasi cepat & responsif
    await Future.delayed(const Duration(milliseconds: 250));

    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Format email tidak valid';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (cleanPass.length < 8) {
      _errorMessage = 'Kata sandi minimal 8 karakter';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Login Sukses (Mendukung kredensial demo maupun email kustom pengguna)
    _currentUser = UserModel(
      id: 1,
      name: cleanEmail.startsWith('sekar') ? 'Sekar Ayu Kinanti' : 'Sekar Ayu Kinanti',
      email: cleanEmail,
      createdAt: DateTime.now().toIso8601String(),
    );

    _isLoading = false;
    notifyListeners();

    // Simpan preferensi secara asinkron
    try {
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('logged_user_id', 1);
      }
    } catch (_) {}

    return true;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 250));

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      _errorMessage = 'Nama lengkap wajib diisi';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Format email tidak valid';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.trim().length < 8) {
      _errorMessage = 'Kata sandi minimal 8 karakter';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _currentUser = UserModel(
      id: 1,
      name: cleanName,
      email: cleanEmail,
      createdAt: DateTime.now().toIso8601String(),
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_user_id');
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updatePillarProgress(int moduleId, String pillar) async {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      bool h = old.historyDone;
      bool c = old.characterDone;
      bool g = old.galleryDone;
      bool q = old.quizDone;
      bool p = old.practiceDone;

      if (pillar == 'history') h = true;
      if (pillar == 'character') c = true;
      if (pillar == 'gallery') g = true;

      int completedComponents = (h ? 1 : 0) + (c ? 1 : 0) + (g ? 1 : 0) + (q ? 1 : 0) + (p ? 1 : 0);
      int percent = (completedComponents * 20).clamp(0, 100);

      _modules[index] = ModuleModel(
        id: old.id,
        motifId: old.motifId,
        title: old.title,
        description: old.description,
        coverImage: old.coverImage,
        passingScore: old.passingScore,
        orderNo: old.orderNo,
        progressPercent: percent,
        historyDone: h,
        characterDone: c,
        galleryDone: g,
        quizDone: q,
        practiceDone: p,
      );
      notifyListeners();
    }
  }

  Future<void> saveQuizResult(int moduleId, int score, bool passed) async {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      bool h = old.historyDone;
      bool c = old.characterDone;
      bool g = old.galleryDone;
      bool p = old.practiceDone;

      int completedComponents = (h ? 1 : 0) + (c ? 1 : 0) + (g ? 1 : 0) + (passed ? 1 : 0) + (p ? 1 : 0);
      int percent = (completedComponents * 20).clamp(0, 100);

      _modules[index] = ModuleModel(
        id: old.id,
        motifId: old.motifId,
        title: old.title,
        description: old.description,
        coverImage: old.coverImage,
        passingScore: old.passingScore,
        orderNo: old.orderNo,
        progressPercent: percent,
        historyDone: h,
        characterDone: c,
        galleryDone: g,
        quizDone: passed,
        practiceDone: p,
      );
      notifyListeners();
    }
  }

  Future<void> savePracticeResult(int moduleId, double fitScore, bool passed) async {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      bool h = old.historyDone;
      bool c = old.characterDone;
      bool g = old.galleryDone;
      bool q = old.quizDone;

      int completedComponents = (h ? 1 : 0) + (c ? 1 : 0) + (g ? 1 : 0) + (q ? 1 : 0) + (passed ? 1 : 0);
      int percent = (completedComponents * 20).clamp(0, 100);

      _modules[index] = ModuleModel(
        id: old.id,
        motifId: old.motifId,
        title: old.title,
        description: old.description,
        coverImage: old.coverImage,
        passingScore: old.passingScore,
        orderNo: old.orderNo,
        progressPercent: percent,
        historyDone: h,
        characterDone: c,
        galleryDone: g,
        quizDone: q,
        practiceDone: passed,
      );

      // Tambahkan ke riwayat scan
      _scanHistories.insert(
        0,
        ScanHistoryModel(
          id: DateTime.now().millisecondsSinceEpoch,
          scanType: 'kuismu',
          motifName: old.title.replaceAll('\n', ' '),
          score: fitScore,
          passed: passed,
          createdAt: 'Baru saja',
        ),
      );
      notifyListeners();
    }
  }

  void addUniversalScanResult({required String motifName, required double confidence}) {
    _scanHistories.insert(
      0,
      ScanHistoryModel(
        id: DateTime.now().millisecondsSinceEpoch,
        scanType: 'universal',
        motifName: motifName,
        score: confidence,
        passed: confidence >= 0.70,
        createdAt: 'Baru saja',
      ),
    );
    notifyListeners();
  }
}
