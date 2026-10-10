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

    // 3. Daftar Modul Belajar — akan menyesuaikan dataset ML Engineer nantinya
    _modules = [
      ModuleModel(
        id: 1,
        motifId: 4,
        title: 'Batik Parang Kusumo',
        description: 'Pelajari asal usul lereng ombak Panembahan Senopati dan pakem larangan Mataram.',
        orderNo: 1,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Batik Klasik Surakarta & Yogyakarta',
          estimatedTime: '8 Menit',
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=fq4N0hgOWzU', // Ganti dengan link video dokumenter Batik aslimu nanti
            deskripsiUtama: 'Motif Parang Kusumo memancarkan ritme visual diagonal yang merepresentasikan deburan ombak Samudra Hindia yang tiada henti menghantam tebing karang terjal. Garis meliuk tanpa putus mencerminkan laku prihatin, kesinambungan budi pekerti luhur, dan ketabahan batin manusia Jawa dalam mengarungi pasang surut gelombang kehidupan tanpa pernah kehilangan kehormatan martabatnya.',
            asalDaerah: 'Diciptakan pada era Panembahan Senopati (pendiri Kesultanan Mataram Islam) saat melakukan semedi meditasi di pesisir tebing Parangtritis. Gerak dinamis air laut yang tak kenal menyerah mengilhami terciptanya garis diagonal sakral ini.',
            maknaFilosofis: 'Berasal dari kata Parang (batu karang/lereng terjal) dan Kusumo (bunga bangsawan). Motif ini memuat amanah luhur bahwa keturunan ningrat sejati wajib mengharumkan nama bangsa laksana bunga mekar dengan ketegaran jiwa sekeras batu karang.',
            penggunaan: 'Tergolong sebagai batik larangan sakral (awisan dalem). Dahulu kala hanya boleh dikenakan keluarga sentana dalem keraton pada upacara tukar cincin pernikahan adat dan pisowanan agung menghadap Sri Sultan atau Sunan.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Kenali struktur anatomi visual dan ornamen pakem yang membedakan Parang Kusumo dari ragam parang lainnya dalam tradisi keraton Mataram.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Jejak Lilin Malam Alami',
              desc: 'Tetesan canting membentuk kontur lereng ombak tanpa henti',
              badge: 'Struktur Utama • 45° Lereng',
              image: '',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Ornamen Mlinjon & Lidah Api',
              desc: 'Tekstur belah ketupat mini pengisi ruang kosong motif.',
              badge: 'Isen-Isen Halus',
              image: '',
            ),
            warna: KarakteristikDetailModel(
              title: 'Warna Khas Sogan',
              desc: 'Paduan soga tua, oker kuning, dan krem mori murni.',
              badge: 'Pewarna Alami',
              image: '',
            ),
            pakemList: [
              PakemModel(title: '1. Sudut Kemiringan 45°', desc: 'Garis lereng sejajar membentang miring 45 derajat tanpa terputus, melambangkan kontinuitas tekad ksatria Jawa.'),
              PakemModel(title: '2. Ornamen Mlinjon & Lidah Api', desc: 'Lekukan menyerupai lidah api berulang yang diselingi belah ketupat mikro, memberi keseimbangan ritme dinamis.'),
              PakemModel(title: '3. Tiga Warna Sakral Sogan', desc: 'Didominasi warna cokelat soga tua (soga jambal), kuning oker keemasan (kayu tegeran), dan dasar putih gading mori prima.'),
              PakemModel(title: '4. Dimensi Khusus Ningrat', desc: 'Ukuran lidah parang berkisar 3-4 cm, dikhususkan bagi bangsawan dan keturunan keraton Mataram.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: '', caption: 'Proses Mencanting'),
            GaleriModel(imageUrl: '', caption: 'Kain Sogan Klasik'),
            GaleriModel(imageUrl: '', caption: 'Jejak Lilin Lereng'),
            GaleriModel(imageUrl: '', caption: 'Detail Isen Canting'),
          ],
        ),
      ),
      ModuleModel(
        id: 2,
        motifId: 6,
        title: 'Batik Mega Mendung',
        description: 'Teknik kuasan tujuh tingkatan gradasi warna langit pesisir Cirebon.',
        orderNo: 2,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Batik Khas Pesisir Cirebon',
          estimatedTime: '10 Menit',
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=fq4N0hgOWzU', // Ganti dengan link video dokumenter Batik aslimu nanti
            deskripsiUtama: 'Motif Megamendung melambangkan awan pembawa hujan sebagai simbol kesuburan dan pemberi kehidupan. Tarikan garis awannya yang tegas mencerminkan maskulinitas, namun tetap luwes membawa kesejukan.',
            asalDaerah: 'Diciptakan di wilayah pesisir utara Jawa, tepatnya Cirebon. Terinspirasi dari kedatangan bangsa Tiongkok ke wilayah keraton Cirebon pada masa lampau.',
            maknaFilosofis: 'Mega berarti awan, dan Mendung berarti cuaca sejuk/menahan amarah. Filosofinya adalah manusia harus bisa meredam amarah (teduh) dalam situasi apa pun.',
            penggunaan: 'Dahulu digunakan oleh kalangan keraton Cirebon, kini menjadi motif kebanggaan masyarakat umum baik untuk pakaian formal maupun kasual.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Berbeda dengan parang, Megamendung berfokus pada gradasi warna dan garis lengkung awan yang menyerupai gumpalan memanjang.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Garis Awan Tegas',
              desc: 'Lengkungan awan ditarik dengan garis yang tegas dan tidak putus.',
              badge: 'Struktur Utama',
              image: '',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Bentuk Lonjong/Segitiga',
              desc: 'Ujung awan cenderung meruncing membedakannya dengan awan Tiongkok yang bulat.',
              badge: 'Ciri Khas Bentuk',
              image: '',
            ),
            warna: KarakteristikDetailModel(
              title: 'Gradasi 7 Warna',
              desc: 'Pakem aslinya memiliki 7 gradasi warna dari biru tua hingga biru muda.',
              badge: 'Pewarna Pesisir',
              image: '',
            ),
            pakemList: [
              PakemModel(title: '1. Gradasi Warna (Ganggeng)', desc: 'Harus memiliki gradasi warna yang halus, umumnya lebih dari 3 tingkat warna untuk menciptakan efek 3D awan.'),
              PakemModel(title: '2. Bentuk Runcing', desc: 'Berbeda dengan motif awan Tiongkok yang membulat, Megamendung memiliki ujung yang agak lancip/runcing.'),
              PakemModel(title: '3. Arah Horizontal', desc: 'Bentuk awan membentang secara horizontal, melambangkan kehidupan yang sejajar.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: '', caption: 'Proses Pembuatan Pola'),
            GaleriModel(imageUrl: '', caption: 'Gradasi Warna Biru'),
            GaleriModel(imageUrl: '', caption: 'Hasil Akhir Khas Cirebon'),
          ],
        ),
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

      // Load progress
      for (int i = 0; i < _modules.length; i++) {
        final mId = _modules[i].id;
        final h = prefs.getBool('module_${mId}_history') ?? false;
        final c = prefs.getBool('module_${mId}_character') ?? false;
        final g = prefs.getBool('module_${mId}_gallery') ?? false;
        final q = prefs.getBool('module_${mId}_quiz') ?? false;
        final p = prefs.getBool('module_${mId}_practice') ?? false;
        final qS = prefs.getInt('module_${mId}_quizScore');
        final pS = prefs.getInt('module_${mId}_practiceScore');
        final percent = prefs.getInt('module_${mId}_progress') ?? 0;

        _modules[i] = _modules[i].copyWith(
          historyDone: h,
          characterDone: c,
          galleryDone: g,
          quizDone: q,
          practiceDone: p,
          quizScore: qS,
          practiceScore: pS,
          progressPercent: percent,
        );
      }

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

  /// Dipanggil dari ModuleDetailScreen saat user menyelesaikan satu page/pillar.
  /// pillar: 'history' | 'character' | 'gallery'
  Future<void> updatePillarProgress(int moduleId, String pillar) async {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      bool h = old.historyDone;
      bool c = old.characterDone;
      bool g = old.galleryDone;
      bool q = old.quizDone;
      bool p = old.practiceDone;

      if (pillar == 'history' && !h) h = true;
      if (pillar == 'character' && !c) c = true;
      if (pillar == 'gallery' && !g) g = true;

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
        content: old.content,
      );
      notifyListeners();

      // Simpan progres ke SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_history', h);
        await prefs.setBool('module_${moduleId}_character', c);
        await prefs.setBool('module_${moduleId}_gallery', g);
        await prefs.setBool('module_${moduleId}_quiz', q);
        await prefs.setBool('module_${moduleId}_practice', p);
      } catch (_) {}
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

      _modules[index] = old.copyWith(
        progressPercent: percent,
        quizDone: passed,
        quizScore: score,
      );
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_quiz', passed);
        await prefs.setInt('module_${moduleId}_quizScore', score);
      } catch (_) {}
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

      _modules[index] = old.copyWith(
        progressPercent: percent,
        practiceDone: passed,
        practiceScore: (fitScore * 100).toInt(),
      );
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_practice', passed);
        await prefs.setInt('module_${moduleId}_practiceScore', (fitScore * 100).toInt());
      } catch (_) {}

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
