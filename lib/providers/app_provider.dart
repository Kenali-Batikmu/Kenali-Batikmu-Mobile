import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/email_service.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/password_hasher.dart';
import '../models/app_models.dart';

class AppProvider with ChangeNotifier {
  static const String _photoPrefKey = 'profile_image_path';

  UserModel? _currentUser;
  String? _savedPhotoPath; // path foto profil tersimpan (file lokal di folder aplikasi)
  bool _isLoading = false;
  String? _errorMessage;

  String? _resetTargetEmail;
  String? _resetOtpCode;
  DateTime? _resetOtpExpiresAt;
  final Map<String, String> _inMemoryPasswordHashes = {
    'sekar@batikmu.id': PasswordHasher.hashPassword('Batikmu123#'),
    'kenalibatikmu@gmail.com': PasswordHasher.hashPassword('kenalibatikmupbl'),
  };

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

  // Getters Pemulihan Kata Sandi
  String? get resetTargetEmail => _resetTargetEmail;
  String? get activeResetOtp => _resetOtpCode;
  bool get hasActiveResetOtp => _resetOtpCode != null;

  // Stats kalkulasi dinamis sesuai PDF Page 3 & Page 12
  int get completedModulesCount => _modules.where((m) => m.progressPercent >= 100).length;
  int get totalModulesCount => _modules.length;
  int get overallProgressPercent => totalModulesCount > 0 ? ((completedModulesCount / totalModulesCount) * 100).round() : 0;
  int get scannedMotifsCount => _scanHistories.length;

  AppProvider({bool initialIsLoggedIn = false, String? initialEmail}) {
    _initInMemoryDefaultData(isLoggedIn: initialIsLoggedIn, userEmail: initialEmail);
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

  void _initInMemoryDefaultData({bool isLoggedIn = false, String? userEmail}) {
    if (isLoggedIn) {
      final email = userEmail ?? 'sekar@batikmu.id';
      final name = email.startsWith('kenalibatikmu')
          ? 'Kenali Batikmu'
          : (email.startsWith('sekar') ? 'Sekar Ayu Kinanti' : 'Sahabat Batik');
      _currentUser = UserModel(
        id: 1,
        name: name,
        email: email,
        phone: '081234567890',
        createdAt: '2026-03-01T08:00:00Z',
      );
    } else {
      _currentUser = null;
    }

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
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=iulhQDSIVMQ', // Video Edukasi Motif Batik Parang (Javanologi UNS)
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
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=wylWYSHkzoQ', // Video Dokumenter Seni & Filosofi Batik (UNESCO)
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
      ModuleModel(
        id: 3,
        motifId: 5,
        title: 'Batik Kawung',
        description: 'Struktur empat lingkaran elips lambang kiblat papat limo pancer Mataram.',
        orderNo: 3,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Batik Klasik Kesultanan Yogyakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: '', // Tidak ada link YouTube (opsional) untuk pengujian UI tanpa video
            deskripsiUtama: 'Motif Kawung tersusun dari empat elips geometris simetris yang menyerupai belahan buah kolang-kaling atau kuncup teratai yang merekah. Motif ini mencerminkan pengendalian diri yang teguh, kemurnian hati nurani, dan keadilan pemimpin dalam menaungi rakyatnya.',
            asalDaerah: 'Diciptakan dan berkembang pesat di lingkungan Keraton Kesultanan Ngayogyakarta Hadiningrat sejak era Mataram Islam pada abad ke-13.',
            maknaFilosofis: 'Filosofi empat elips merujuk pada konsep Kiblat Papat Limo Pancer: empat penjuru mata angin dengan satu pusat batin yang menuntun manusia senantiasa eling lan waspada terhadap godaan duniawi.',
            penggunaan: 'Termasuk salah satu batik larangan (awisan dalem) yang dahulu hanya boleh dikenakan oleh para pembesar dan abdi dalem keraton sebagai lambang integritas moral.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Pola geometris simetris empat lingkaran lonjong dengan isen titik cecek di poros tengah.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Simetri 4 Elips (Kiblat Papat)',
              desc: 'Empat bidang lonjong yang berpotongan secara presisi membentuk lingkaran bunga.',
              badge: 'Struktur Utama',
              image: '',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Poros Tengah (Pancer)',
              desc: 'Titik pusat perpotongan kelopak yang dihiasi isen cecek mikro halus.',
              badge: 'Titik Poros',
              image: '',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Klasik & Putih Mori',
              desc: 'Warna cokelat alami kulit kayu soga berpadu kontras dengan putih mori lembut.',
              badge: 'Pewarna Alami',
              image: '',
            ),
            pakemList: [
              PakemModel(title: '1. Proporsi Elips Presisi', desc: 'Ukuran keempat bidang kelopak harus proporsional dan membentuk sudut 90 derajat yang teratur.'),
              PakemModel(title: '2. Isen Poros Pancer', desc: 'Pusat silang harus memiliki titik temu atau cecek penyeimbang ritme ornamen.'),
              PakemModel(title: '3. Garis Kontur Mulus', desc: 'Tarikan canting melingkar tanpa patahan tajam untuk menjaga keharmonisan bentuk.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: '', caption: 'Sketsa Geometris Kawung'),
            GaleriModel(imageUrl: '', caption: 'Pencantingan Mori Putih'),
            GaleriModel(imageUrl: '', caption: 'Kain Kawung Mataram Sogan'),
          ],
        ),
      ),
      ModuleModel(
        id: 4,
        motifId: 3,
        title: 'Batik Truntum',
        description: 'Pola gemintang cinta kasih tulus yang senantiasa bersemi di keheningan malam.',
        orderNo: 4,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Batik Keraton Kasunanan Surakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: '', // Tidak ada link YouTube (opsional) untuk pengujian UI tanpa video
            deskripsiUtama: 'Motif Truntum menampilkan tebaran kuntum bunga melati mikro menyerupai gemintang di langit malam. Diciptakan oleh Kanjeng Ratu Kencana (Permaisuri Pakubuwono III) saat merenung menatap bintang di keheningan malam sembari mencanting untuk menumbuhkan kembali cinta kasih sang Raja.',
            asalDaerah: 'Diciptakan di lingkungan Keraton Kasunanan Surakarta Hadiningrat pada pertengahan abad ke-18.',
            maknaFilosofis: 'Truntum berasal dari kata taruntum yang berarti bersemi atau tumbuh kembali. Mengandung filosofi cinta kasih yang tulus, tanpa pamrih, dan senantiasa mekar abadi sepanjang masa.',
            penggunaan: 'Wajib dikenakan oleh orang tua pengantin pada upacara pernikahan adat Jawa, menyimbolkan doa restu agar cinta kedua mempelai selalu bersemi dan mampu menjadi panutan hidup.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Pola repetisi kuntum bunga melati mikro yang tertata rapi di atas latar hitam pekat.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Kuntum Bintang Melati',
              desc: 'Motif bunga kecil berbentuk bintang berkelopak mekar teratur di seluruh kain.',
              badge: 'Struktur Utama',
              image: '',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Cecek Isen Melati',
              desc: 'Titik-titik mikro lilin malam yang mengisi bagian dalam kelopak bintang.',
              badge: 'Isen Canting Halus',
              image: '',
            ),
            warna: KarakteristikDetailModel(
              title: 'Latar Hitam & Emas Cokelat',
              desc: 'Latar hitam pekat menyerupai langit malam berpadu cokelat soga keemasan.',
              badge: 'Warna Tradisi',
              image: '',
            ),
            pakemList: [
              PakemModel(title: '1. Kerapatan Kuntum Seragam', desc: 'Jarak antar kuntum bunga terjaga secara konsisten di seluruh bidang kain mori.'),
              PakemModel(title: '2. Latar Gelap Pekat', desc: 'Warna dasar harus hitam atau cokelat pekat tanpa corak latar tambahan.'),
              PakemModel(title: '3. Canting Cecek Halus', desc: 'Bintik cecek mikro pada mahkota melambangkan ketulusan dan kehalusan budi pekerti.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: '', caption: 'Pola Kuntum Bintang'),
            GaleriModel(imageUrl: '', caption: 'Pencelupan Warna Gelap'),
            GaleriModel(imageUrl: '', caption: 'Kain Truntum Pengantin'),
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

      // Muat foto profil tersimpan (hanya jika filenya masih ada atau URL cloud)
      final savedPhoto = prefs.getString(_photoPrefKey);
      if (savedPhoto != null && (savedPhoto.startsWith('http') || kIsWeb || File(savedPhoto).existsSync())) {
        _savedPhotoPath = savedPhoto;
      }

      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (isLoggedIn) {
        final savedEmail = prefs.getString('logged_user_email');
        if (savedEmail != null) {
          final dbUser = await DatabaseHelper.instance.getUserByEmail(savedEmail);
          if (dbUser != null) {
            _currentUser = UserModel.fromMap(dbUser);
            if (_currentUser?.profileImagePath != null && _currentUser!.profileImagePath!.isNotEmpty) {
              _savedPhotoPath = _currentUser!.profileImagePath;
            }
          } else {
            // Coba ambil dari cloud Supabase jika terhubung
            final supaUser = await SupabaseService.instance.getUserByEmail(savedEmail);
            if (supaUser != null) {
              _currentUser = UserModel.fromMap(supaUser);
              if (_currentUser?.profileImagePath != null && _currentUser!.profileImagePath!.isNotEmpty) {
                _savedPhotoPath = _currentUser!.profileImagePath;
              }
              // Cache ke SQLite lokal
              await DatabaseHelper.instance.insertUser(
                name: supaUser['name'] ?? 'Sahabat Batik',
                email: savedEmail,
                passwordHash: supaUser['password_hash'] ?? '',
                phone: supaUser['phone'],
                profileImagePath: supaUser['profile_image_path'],
              );
            } else {
              final savedName = prefs.getString('logged_user_name');
              final name = savedName ?? (savedEmail.startsWith('kenalibatikmu')
                  ? 'Kenali Batikmu'
                  : (savedEmail.startsWith('sekar') ? 'Sekar Ayu Kinanti' : 'Sahabat Batik'));
              _currentUser = UserModel(
                id: prefs.getInt('logged_user_id') ?? 1,
                name: name,
                email: savedEmail,
                phone: prefs.getString('logged_user_phone') ?? '081234567890',
                profileImagePath: _savedPhotoPath,
                createdAt: '2026-03-01T08:00:00Z',
              );
            }
          }
          // Muat progres modul khusus milik user yang tersimpan
          await _loadUserModuleProgress(savedEmail);
        }
      } else {
        // Fallback default akun jika ada di DB lokal
        final db = await DatabaseHelper.instance.database;
        if (db != null) {
          final users = await db.query('users', limit: 1);
          if (users.isNotEmpty && _currentUser != null) {
            _currentUser = UserModel.fromMap(users.first);
          }
        }
        if (_currentUser == null) {
          _resetModuleProgressInMemory();
        }
      }

      // Muat data master dari SQLite lokal (20 Modul & 20 Motif)
      final db = await DatabaseHelper.instance.database;
      if (db != null) {
        if (_currentUser == null) {
          final users = await db.query('users', limit: 1);
          if (users.isNotEmpty) {
            _currentUser = UserModel.fromMap(users.first);
          }
        }

        final dbMotifs = await DatabaseHelper.instance.getAllMotifs();
        if (dbMotifs.isNotEmpty) {
          _motifs = dbMotifs;
        }

        final dbModules = await DatabaseHelper.instance.getAllModules(userId: _currentUser?.id ?? 1);
        if (dbModules.isNotEmpty) {
          _modules = dbModules;
        }

        final histories = await DatabaseHelper.instance.getScanHistories(_currentUser?.id ?? 1);
        if (histories.isNotEmpty) {
          _scanHistories = histories;
        }
      }
    } catch (e) {
      debugPrint('Info sync SQLite: $e (Aplikasi berjalan dalam Interactive Prototype Mode)');
    } finally {
      _applySavedPhoto();
      notifyListeners();
    }
  }

  /// Reset progres seluruh modul di memori ke kondisi awal (0%)
  void _resetModuleProgressInMemory() {
    for (int i = 0; i < _modules.length; i++) {
      _modules[i] = _modules[i].copyWith(
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        quizScore: null,
        practiceScore: null,
        progressPercent: 0,
      );
    }
  }

  /// Memuat progres modul khusus untuk user tertentu (berdasarkan email & SQLite)
  Future<void> _loadUserModuleProgress(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final dbUser = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
      final userId = dbUser != null ? dbUser['id'] as int? : null;

      // 1. Ambil data dari tabel relasional SQLite jika user terdaftar
      Map<int, Map<String, dynamic>> sqliteProgressMap = {};
      if (userId != null) {
        final list = await DatabaseHelper.instance.getUserModuleProgressList(userId);
        for (final row in list) {
          final mId = row['module_id'] as int;
          sqliteProgressMap[mId] = row;
        }
      }

      final prefs = await SharedPreferences.getInstance();

      for (int i = 0; i < _modules.length; i++) {
        final mId = _modules[i].id;
        final sqlRow = sqliteProgressMap[mId];

        bool? h;
        bool? c;
        bool? g;
        bool? q;
        bool? p;
        int? qS;
        int? pS;
        int? percent;

        if (sqlRow != null) {
          h = (sqlRow['history_done'] as int? ?? 0) == 1;
          c = (sqlRow['character_done'] as int? ?? 0) == 1;
          g = (sqlRow['gallery_done'] as int? ?? 0) == 1;
          q = (sqlRow['quiz_done'] as int? ?? 0) == 1;
          p = (sqlRow['practice_done'] as int? ?? 0) == 1;
          percent = sqlRow['progress_percent'] as int? ?? 0;
        } else {
          // Fallback ke SharedPreferences cache
          final userKeyPrefix = 'user_${cleanEmail}_module_$mId';
          h = prefs.getBool('${userKeyPrefix}_history');
          c = prefs.getBool('${userKeyPrefix}_character');
          g = prefs.getBool('${userKeyPrefix}_gallery');
          q = prefs.getBool('${userKeyPrefix}_quiz');
          p = prefs.getBool('${userKeyPrefix}_practice');
          percent = prefs.getInt('${userKeyPrefix}_progress');
        }

        final userKeyPrefix = 'user_${cleanEmail}_module_$mId';
        qS = prefs.getInt('${userKeyPrefix}_quizScore');
        pS = prefs.getInt('${userKeyPrefix}_practiceScore');

        // Fallback backward compatibility untuk akun default 'sekar' jika belum ada key baru
        if (h == null && cleanEmail.startsWith('sekar')) {
          h = prefs.getBool('module_${mId}_history');
          c = prefs.getBool('module_${mId}_character');
          g = prefs.getBool('module_${mId}_gallery');
          q = prefs.getBool('module_${mId}_quiz');
          p = prefs.getBool('module_${mId}_practice');
          qS = prefs.getInt('module_${mId}_quizScore');
          pS = prefs.getInt('module_${mId}_practiceScore');
          percent = prefs.getInt('module_${mId}_progress');
        }

        _modules[i] = _modules[i].copyWith(
          historyDone: h ?? false,
          characterDone: c ?? false,
          galleryDone: g ?? false,
          quizDone: q ?? false,
          practiceDone: p ?? false,
          quizScore: qS,
          practiceScore: pS,
          progressPercent: percent ?? 0,
        );
      }
    } catch (_) {}
  }

  // Tempelkan foto tersimpan ke pengguna aktif (dipakai setelah data pengguna dimuat dari DB)
  void _applySavedPhoto() {
    if (_currentUser != null && _savedPhotoPath != null) {
      _currentUser = _currentUser!.copyWith(profileImagePath: _savedPhotoPath);
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

    final dbUser = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
    if (dbUser != null && dbUser['password_hash'] != null) {
      final storedHash = dbUser['password_hash'] as String;
      if (!PasswordHasher.verify(cleanPass, storedHash)) {
        _errorMessage = 'Kata sandi salah. Silakan periksa kembali.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } else if (_inMemoryPasswordHashes.containsKey(cleanEmail)) {
      final storedHash = _inMemoryPasswordHashes[cleanEmail]!;
      if (!PasswordHasher.verify(cleanPass, storedHash)) {
        _errorMessage = 'Kata sandi salah. Silakan periksa kembali.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    // Ambil nama profil jika ada
    final userName = dbUser != null && dbUser['name'] != null
        ? dbUser['name'] as String
        : (cleanEmail.startsWith('sekar')
            ? 'Sekar Ayu Kinanti'
            : (cleanEmail.startsWith('kenalibatikmu')
                ? 'Kenali Batikmu'
                : 'Sahabat Batik'));

    // Ambil foto profil dari database lokal jika tersedia
    final dbPhoto = dbUser?['profile_image_path'] as String?;
    final userPhoto = (dbPhoto != null && dbPhoto.isNotEmpty) ? dbPhoto : _savedPhotoPath;
    if (userPhoto != null && userPhoto.isNotEmpty) {
      _savedPhotoPath = userPhoto;
    }

    // Login Sukses
    _currentUser = UserModel(
      id: dbUser != null ? (dbUser['id'] as int? ?? 1) : 1,
      name: userName,
      email: cleanEmail,
      phone: dbUser?['phone'] as String?,
      profileImagePath: userPhoto,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Jika belum ada foto lokal, coba sinkronkan profil & foto dari Supabase
    if (userPhoto == null || userPhoto.isEmpty) {
      SupabaseService.instance.getUserByEmail(cleanEmail).then((supaUser) {
        if (supaUser != null) {
          final cloudPhoto = supaUser['profile_image_path'] as String?;
          final cloudPhone = supaUser['phone'] as String?;
          if ((cloudPhoto != null && cloudPhoto.isNotEmpty) || cloudPhone != null) {
            if (cloudPhoto != null && cloudPhoto.isNotEmpty) {
              _savedPhotoPath = cloudPhoto;
            }
            _currentUser = _currentUser?.copyWith(
              profileImagePath: cloudPhoto,
              phone: cloudPhone,
            );
            DatabaseHelper.instance.updateUserProfile(
              userId: _currentUser?.id ?? 1,
              name: _currentUser?.name ?? 'Sahabat Batik',
              email: cleanEmail,
              phone: cloudPhone,
              profileImagePath: cloudPhoto,
            );
            notifyListeners();
          }
        }
      }).catchError((_) {});
    }

    // Muat progres modul khusus milik user yang berhasil login
    await _loadUserModuleProgress(cleanEmail);

    _isLoading = false;
    notifyListeners();

    // Simpan preferensi secara asinkron
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      if (rememberMe) {
        await prefs.setInt('logged_user_id', _currentUser?.id ?? 1);
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('logged_user_email', cleanEmail);
      } else {
        await prefs.remove('logged_user_id');
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('logged_user_email');
      }
    } catch (_) {}

    return true;
  }

  /// Meminta kode OTP untuk pemulihan kata sandi
  Future<EmailSendResult> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();

    // Validasi format email
    if (cleanEmail.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(cleanEmail)) {
      _errorMessage = 'Format email tidak valid';
      _isLoading = false;
      notifyListeners();
      return const EmailSendResult(
        isSuccess: false,
        isDemoSimulated: false,
        message: 'Format email tidak valid',
      );
    }

    // Cek apakah email terdaftar di SQLite atau in-memory default
    bool isRegistered = false;
    String recipientName = 'Sahabat Batik';

    if (cleanEmail == 'kenalibatikmu@gmail.com') {
      isRegistered = true;
      recipientName = 'Kenali Batikmu';
    } else if (cleanEmail == 'sekar@batikmu.id') {
      isRegistered = true;
      recipientName = 'Sekar Ayu Kinanti';
    } else {
      final dbUser = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
      if (dbUser != null) {
        isRegistered = true;
        recipientName = dbUser['name'] as String? ?? 'Sahabat Batik';
      } else if (_inMemoryPasswordHashes.containsKey(cleanEmail)) {
        isRegistered = true;
        recipientName = 'Sahabat Batik';
      }
    }

    if (!isRegistered) {
      _errorMessage = 'Email tidak terdaftar dalam sistem';
      _isLoading = false;
      notifyListeners();
      return const EmailSendResult(
        isSuccess: false,
        isDemoSimulated: false,
        message: 'Email belum terdaftar di Kenali Batikmu',
      );
    }

    // Generate 4 digit OTP acak (1000 - 9999)
    final otp = (1000 + Random().nextInt(9000)).toString();
    _resetTargetEmail = cleanEmail;
    _resetOtpCode = otp;
    _resetOtpExpiresAt = DateTime.now().add(const Duration(minutes: 5));

    // Kirim via EmailService (baik live via EmailJS maupun demo simulation)
    final result = await EmailService.sendPasswordResetOtp(
      recipientEmail: cleanEmail,
      recipientName: recipientName,
      otpCode: otp,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Verifikasi kecocokan kode OTP yang diinput
  bool verifyResetOtp(String inputOtp) {
    if (_resetOtpCode == null || _resetOtpExpiresAt == null) {
      _errorMessage = 'Sesi pemulihan tidak valid. Silakan minta kode baru.';
      notifyListeners();
      return false;
    }

    if (DateTime.now().isAfter(_resetOtpExpiresAt!)) {
      _errorMessage = 'Kode OTP telah kedaluwarsa. Silakan kirim ulang.';
      notifyListeners();
      return false;
    }

    if (inputOtp.trim() != _resetOtpCode) {
      _errorMessage = 'Kode verifikasi salah. Periksa kembali kode Anda.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Menyimpan kata sandi baru ke database & memory
  Future<bool> finalizePasswordReset(String newPassword) async {
    if (_resetTargetEmail == null) {
      _errorMessage = 'Sesi pemulihan telah berakhir';
      notifyListeners();
      return false;
    }

    final cleanPass = newPassword.trim();
    if (cleanPass.length < 8) {
      _errorMessage = 'Kata sandi baru minimal 8 karakter';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newHash = PasswordHasher.hashPassword(cleanPass);
    final targetEmail = _resetTargetEmail!;

    // Perbarui hash di database SQLite
    await DatabaseHelper.instance.updateUserPassword(targetEmail, newHash);

    // Perbarui di in-memory map
    _inMemoryPasswordHashes[targetEmail] = newHash;

    // Bersihkan sesi reset
    _resetTargetEmail = null;
    _resetOtpCode = null;
    _resetOtpExpiresAt = null;

    _isLoading = false;
    notifyListeners();
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

    final cleanPass = password.trim();
    if (cleanPass.length < 8) {
      _errorMessage = 'Kata sandi minimal 8 karakter';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final passwordHash = PasswordHasher.hashPassword(cleanPass);
    _inMemoryPasswordHashes[cleanEmail] = passwordHash;

    // 1. Simpan ke SQLite lokal
    int newId = await DatabaseHelper.instance.insertUser(
      name: cleanName,
      email: cleanEmail,
      passwordHash: passwordHash,
      profileImagePath: _savedPhotoPath,
    );
    if (newId <= 0) {
      newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    // 2. Sinkronkan ke cloud Supabase (jika terhubung)
    SupabaseService.instance.registerUser(
      name: cleanName,
      email: cleanEmail,
      passwordHash: passwordHash,
    ).then((ok) {
      if (ok) debugPrint('Cloud sync register: $cleanEmail berhasil disimpan ke Supabase');
    }).catchError((e) {
      debugPrint('Cloud sync register fallback: $e');
    });

    _currentUser = UserModel(
      id: newId,
      name: cleanName,
      email: cleanEmail,
      profileImagePath: _savedPhotoPath,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Akun baru: pastikan progres modul di memori bersih (0%)
    _resetModuleProgressInMemory();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      await prefs.setBool('is_logged_in', true);
      await prefs.setInt('logged_user_id', newId);
      await prefs.setString('logged_user_email', cleanEmail);
      await prefs.setString('logged_user_name', cleanName);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_user_id');
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('logged_user_email');
    } catch (_) {}
    _currentUser = null;
    // Reset progres modul di memori saat logout agar tidak bocor ke akun berikutnya
    _resetModuleProgressInMemory();
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

      // Simpan progres ke SharedPreferences & SQLite
      try {
        final prefs = await SharedPreferences.getInstance();
        final userKey = _currentUser?.email.trim().toLowerCase() ?? 'guest';
        final userKeyPrefix = 'user_${userKey}_module_$moduleId';
        await prefs.setInt('${userKeyPrefix}_progress', percent);
        await prefs.setBool('${userKeyPrefix}_history', h);
        await prefs.setBool('${userKeyPrefix}_character', c);
        await prefs.setBool('${userKeyPrefix}_gallery', g);
        await prefs.setBool('${userKeyPrefix}_quiz', q);
        await prefs.setBool('${userKeyPrefix}_practice', p);

        // Fallback key umum
        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_history', h);
        await prefs.setBool('module_${moduleId}_character', c);
        await prefs.setBool('module_${moduleId}_gallery', g);
        await prefs.setBool('module_${moduleId}_quiz', q);
        await prefs.setBool('module_${moduleId}_practice', p);

        final userId = _currentUser?.id ?? 1;
        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: h,
          characterDone: c,
          galleryDone: g,
          quizDone: q,
          practiceDone: p,
        );
        await DatabaseHelper.instance.updatePillarProgress(userId, moduleId, pillar);

        // Sinkronisasi ke Cloud Supabase (non-blocking)
        final userEmail = _currentUser?.email;
        if (userEmail != null) {
          SupabaseService.instance.syncUserModuleProgress(
            userEmail: userEmail,
            moduleId: moduleId,
            progressPercent: percent,
            historyDone: h,
            characterDone: c,
            galleryDone: g,
            quizDone: q,
            practiceDone: p,
          ).catchError((e) {
            debugPrint('Cloud sync pillar fallback: $e');
            return false;
          });
        }
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
        final userKey = _currentUser?.email.trim().toLowerCase() ?? 'guest';
        final userKeyPrefix = 'user_${userKey}_module_$moduleId';
        await prefs.setInt('${userKeyPrefix}_progress', percent);
        await prefs.setBool('${userKeyPrefix}_quiz', passed);
        await prefs.setInt('${userKeyPrefix}_quizScore', score);

        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_quiz', passed);
        await prefs.setInt('module_${moduleId}_quizScore', score);

        final userId = _currentUser?.id ?? 1;
        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: h,
          characterDone: c,
          galleryDone: g,
          quizDone: passed,
          practiceDone: p,
        );

        await DatabaseHelper.instance.saveQuizAttempt(
          userId: userId,
          moduleId: moduleId,
          score: score,
          passed: passed,
          totalQuestions: 10,
        );

        // Sinkronisasi ke Cloud Supabase (non-blocking)
        final userEmail = _currentUser?.email;
        if (userEmail != null) {
          SupabaseService.instance.saveQuizAttempt(
            userEmail: userEmail,
            moduleId: moduleId,
            score: score,
            passed: passed,
          ).catchError((e) {
            debugPrint('Cloud sync quiz attempt fallback: $e');
            return false;
          });

          SupabaseService.instance.syncUserModuleProgress(
            userEmail: userEmail,
            moduleId: moduleId,
            progressPercent: percent,
            historyDone: h,
            characterDone: c,
            galleryDone: g,
            quizDone: passed,
            practiceDone: p,
          ).catchError((e) {
            debugPrint('Cloud sync quiz progress fallback: $e');
            return false;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> savePracticeResult(int moduleId, double fitScore, bool passed, {String? imagePath}) async {
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
        final userKey = _currentUser?.email.trim().toLowerCase() ?? 'guest';
        final userKeyPrefix = 'user_${userKey}_module_$moduleId';
        await prefs.setInt('${userKeyPrefix}_progress', percent);
        await prefs.setBool('${userKeyPrefix}_practice', passed);
        await prefs.setInt('${userKeyPrefix}_practiceScore', (fitScore * 100).toInt());

        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_practice', passed);
        await prefs.setInt('module_${moduleId}_practiceScore', (fitScore * 100).toInt());

        final userId = _currentUser?.id ?? 1;
        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: h,
          characterDone: c,
          galleryDone: g,
          quizDone: q,
          practiceDone: passed,
        );

        await DatabaseHelper.instance.savePracticeAttempt(
          userId: userId,
          moduleId: moduleId,
          confidence: fitScore,
          passed: passed,
          imagePath: imagePath,
        );

        // Sinkronisasi ke Cloud Supabase (non-blocking)
        final userEmail = _currentUser?.email;
        if (userEmail != null) {
          if (imagePath != null && imagePath.isNotEmpty) {
            SupabaseService.instance.uploadPracticeImage(
              filePath: imagePath,
              email: userEmail,
              moduleId: moduleId,
            ).then((publicUrl) {
              SupabaseService.instance.savePracticeScan(
                userEmail: userEmail,
                moduleId: moduleId,
                confidence: fitScore,
                passed: passed,
                imageUrl: publicUrl,
              ).catchError((e) {
                debugPrint('Cloud sync practice scan fallback: $e');
                return false;
              });
            }).catchError((_) {
              SupabaseService.instance.savePracticeScan(
                userEmail: userEmail,
                moduleId: moduleId,
                confidence: fitScore,
                passed: passed,
                imageUrl: null,
              ).catchError((e) {
                debugPrint('Cloud sync practice scan fallback: $e');
                return false;
              });
            });
          } else {
            SupabaseService.instance.savePracticeScan(
              userEmail: userEmail,
              moduleId: moduleId,
              confidence: fitScore,
              passed: passed,
              imageUrl: null,
            ).catchError((e) {
              debugPrint('Cloud sync practice scan fallback: $e');
              return false;
            });
          }

          SupabaseService.instance.syncUserModuleProgress(
            userEmail: userEmail,
            moduleId: moduleId,
            progressPercent: percent,
            historyDone: h,
            characterDone: c,
            galleryDone: g,
            quizDone: q,
            practiceDone: passed,
          ).catchError((e) {
            debugPrint('Cloud sync practice progress fallback: $e');
            return false;
          });
        }
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

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: cleanName,
        email: cleanEmail,
        phone: cleanPhone,
      );
      notifyListeners();

      // 1. Simpan ke SQLite lokal
      await DatabaseHelper.instance.updateUserProfile(
        userId: _currentUser!.id,
        name: cleanName,
        email: cleanEmail,
        phone: cleanPhone,
        profileImagePath: _savedPhotoPath,
      );

      // 2. Simpan perubahan kata sandi jika diisi
      if (password.isNotEmpty && password.length >= 8) {
        final newHash = PasswordHasher.hashPassword(password);
        _inMemoryPasswordHashes[cleanEmail] = newHash;
        await DatabaseHelper.instance.updateUserPassword(cleanEmail, newHash);
      }

      // 3. Simpan nama dan email ke SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_user_name', cleanName);
        await prefs.setString('logged_user_email', cleanEmail);
        await prefs.setString('logged_user_phone', cleanPhone);
      } catch (_) {}

      // 4. Sinkronkan ke cloud Supabase (jika terhubung)
      SupabaseService.instance.updateUserProfile(
        email: cleanEmail,
        name: cleanName,
        phone: cleanPhone,
        profileImagePath: _savedPhotoPath,
      ).catchError((e) {
        debugPrint('Cloud sync profile update fallback: $e');
        return false;
      });
    }
  }

  Future<bool> setProfilePhoto(String path) async {
    try {
      _savedPhotoPath = path;
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImagePath: path);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoPrefKey, path);
      notifyListeners();

      // 1. Simpan ke database SQLite lokal
      if (_currentUser != null) {
        await DatabaseHelper.instance.updateUserProfile(
          userId: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          profileImagePath: path,
        );
      }

      // 2. Upload ke Supabase Storage & perbarui Supabase users table (non-blocking)
      final userEmail = _currentUser?.email;
      if (userEmail != null) {
        SupabaseService.instance.uploadAvatar(
          filePath: path,
          email: userEmail,
        ).then((publicUrl) async {
          if (publicUrl != null) {
            await SupabaseService.instance.updateUserProfile(
              email: userEmail,
              name: _currentUser?.name ?? '',
              phone: _currentUser?.phone,
              profileImagePath: publicUrl,
            );
            debugPrint('Cloud sync: Foto profil tersinkron ke Supabase users & storage!');
          }
        }).catchError((e) {
          debugPrint('Cloud sync avatar fallback: $e');
        });
      }

      return true;
    } catch (e) {
      debugPrint('setProfilePhoto error: $e');
      return false;
    }
  }

  Future<void> removeProfilePhoto() async {
    _savedPhotoPath = null;
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        profileImagePath: null,
        createdAt: _currentUser!.createdAt,
      );

      // 1. Perbarui SQLite lokal
      await DatabaseHelper.instance.updateUserProfile(
        userId: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        profileImagePath: null,
      );

      // 2. Perbarui Supabase users table
      SupabaseService.instance.updateUserProfile(
        email: _currentUser!.email,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        profileImagePath: null,
      ).catchError((_) => false);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPrefKey);
    notifyListeners();
  }
}