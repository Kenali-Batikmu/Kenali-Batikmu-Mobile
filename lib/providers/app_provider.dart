import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/email_service.dart';
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

    // 2. Daftar 20 Motif Utama Sesuai Kurikulum Modul & Dataset PBL
    // 2. Daftar 20 Motif Utama Sesuai Kurikulum Modul & Dataset PBL
    // 2. Daftar 20 Motif Utama Sesuai Kurikulum Modul & Dataset PBL
    _motifs = [
      BatikMotifModel(
        id: 1,
        name: 'Sido Luhur',
        slug: 'sidoluhur',
        originRegion: 'Batik Klasik Keraton Surakarta Hadiningrat',
        shortDescription: 'Batik klasik Surakarta perlambang keluhuran budi pekerti, derajat mulia, dan doa pernikahan adat.',
        thumbnailUrl: 'assets/images/batik/sidoluhur_cover.jpg',
        mlClassIndex: 0,
      ),
      BatikMotifModel(
        id: 2,
        name: 'Sido Mukti',
        slug: 'sidomukti',
        originRegion: 'Keraton Mataram, Surakarta & Yogyakarta',
        shortDescription: 'Batik sakral Mataram lambang kemakmuran, kesejahteraan lahir batin, dan keharmonisan hidup.',
        thumbnailUrl: 'assets/images/batik/sidomukti_cover.jpg',
        mlClassIndex: 1,
      ),
      BatikMotifModel(
        id: 3,
        name: 'Sido Mulyo',
        slug: 'sidomulyo',
        originRegion: 'Keraton Surakarta & Yogyakarta',
        shortDescription: 'Simbol harapan kemuliaan derajat, integritas martabat ningrat, dan keberkahan budi pekerti.',
        thumbnailUrl: 'assets/images/batik/sidomulyo_cover.jpg',
        mlClassIndex: 2,
      ),
      BatikMotifModel(
        id: 4,
        name: 'Singa Barong',
        slug: 'singa_barong',
        originRegion: 'Keraton Kasepuhan & Kanoman Cirebon',
        shortDescription: 'Mahakarya spiritual Keraton Cirebon perlambang kekuatan kepemimpinan dan penolak bala.',
        thumbnailUrl: 'assets/images/batik/singa_barong_cover.jpg',
        mlClassIndex: 3,
      ),
      BatikMotifModel(
        id: 5,
        name: 'Srikaton',
        slug: 'srikaton',
        originRegion: 'Keraton Mataram & Tradisi Agraris Jawa',
        shortDescription: 'Persembahan doa kemakmuran nyata Dewi Sri, kesuburan bumi agraris, dan panen melimpah.',
        thumbnailUrl: 'assets/images/batik/srikaton_cover.jpg',
        mlClassIndex: 4,
      ),
      BatikMotifModel(
        id: 6,
        name: 'Tribusono',
        slug: 'tribusono',
        originRegion: 'Keraton Surakarta & Yogyakarta',
        shortDescription: 'Harmonisasi kosmologi tiga alam Jawa: kebenaran, keindahan, dan kebaikan hidup semesta.',
        thumbnailUrl: 'assets/images/batik/tribusono_cover.jpg',
        mlClassIndex: 5,
      ),
      BatikMotifModel(
        id: 7,
        name: 'Tujuh Rupa',
        slug: 'tujuh_rupa',
        originRegion: 'Sentra Batik Pesisir Kota Pekalongan',
        shortDescription: 'Simbol kebhinekaan pesisir Pekalongan berhias tujuh ornamen flora fauna aneka warna cerah.',
        thumbnailUrl: 'assets/images/batik/tujuh_rupa_cover.jpg',
        mlClassIndex: 6,
      ),
      BatikMotifModel(
        id: 8,
        name: 'Tuntrum (Truntum)',
        slug: 'tuntrum',
        originRegion: 'Keraton Kasunanan Surakarta Hadiningrat',
        shortDescription: 'Kilau gemintang cinta abadi ciptaan Kanjeng Ratu Kencana Kasunanan Surakarta.',
        thumbnailUrl: 'assets/images/batik/tuntrum_cover.jpg',
        mlClassIndex: 7,
      ),
      BatikMotifModel(
        id: 9,
        name: 'Wahyu Tumurun',
        slug: 'wahyu_tumurun',
        originRegion: 'Keraton Kasultanan Yogyakarta & Surakarta',
        shortDescription: 'Batik larangan agung perlambang turunnya rahmat, hidayah, dan berkah ilahi bagi pemimpin.',
        thumbnailUrl: 'assets/images/batik/wahyu_tumurun_cover.jpg',
        mlClassIndex: 8,
      ),
      BatikMotifModel(
        id: 10,
        name: 'Wirasat',
        slug: 'wirasat',
        originRegion: 'Keraton Surakarta & Yogyakarta',
        shortDescription: 'Tuntunan kebijaksanaan batin, intuisi membaca tanda alam, dan kumpulan doa restu sesepuh.',
        thumbnailUrl: 'assets/images/batik/wirasat_cover.jpg',
        mlClassIndex: 9,
      ),
      BatikMotifModel(
        id: 11,
        name: 'Betawi',
        slug: 'betawi',
        originRegion: 'DKI Jakarta (Sentra Terogong & Seraci Bekasi)',
        shortDescription: 'Keceriaan budaya pesisir Batavia berhias ikon ondel-ondel, pucuk rebung, dan warna cerah berani.',
        thumbnailUrl: 'assets/images/batik/betawi_cover.jpg',
        mlClassIndex: 10,
      ),
      BatikMotifModel(
        id: 12,
        name: 'Bokor Kencono',
        slug: 'bokor_kencono',
        originRegion: 'Keraton Kasunanan Surakarta Hadiningrat',
        shortDescription: 'Batik agung Keraton Solo era Pakubuwono IX pembawa kewibawaan dan keterbukaan bagi semua kalangan.',
        thumbnailUrl: 'assets/images/batik/bokor_kencono_cover.jpg',
        mlClassIndex: 11,
      ),
      BatikMotifModel(
        id: 13,
        name: 'Buketan',
        slug: 'buketan',
        originRegion: 'Sentra Batik Indo-Eropa Kota Pekalongan',
        shortDescription: 'Mahakarya akulturasi Indo-Eropa di Pekalongan pelopor buket bunga besar karya Eliza van Zuylen.',
        thumbnailUrl: 'assets/images/batik/buketan_cover.jpg',
        mlClassIndex: 12,
      ),
      BatikMotifModel(
        id: 14,
        name: 'Dayak (Benang Bintik)',
        slug: 'dayak',
        originRegion: 'Kalimantan Tengah (Suku Dayak Ngaju)',
        shortDescription: 'Kosmologi sakral Dayak Ngaju berhias Pohon Kehidupan Batang Garing dan burung Enggang suci.',
        thumbnailUrl: 'assets/images/batik/dayak_cover.jpg',
        mlClassIndex: 13,
      ),
      BatikMotifModel(
        id: 15,
        name: 'Jlamprang',
        slug: 'jlamprang',
        originRegion: 'Sentra Batik Krapyak Kota Pekalongan',
        shortDescription: 'Geometri kosmis nitik Pekalongan hasil akulturasi tenun Patola Gujarat dan spiritualitas Islam.',
        thumbnailUrl: 'assets/images/batik/jlamprang_cover.jpg',
        mlClassIndex: 14,
      ),
      BatikMotifModel(
        id: 16,
        name: 'Kawung',
        slug: 'kawung',
        originRegion: 'Keraton Kesultanan Ngayogyakarta Hadiningrat',
        shortDescription: 'Salah satu motif tertua di Jawa lambang kiblat papat limo pancer, kesucian hati, dan keadilan pemimpin.',
        thumbnailUrl: 'assets/images/batik/kawung_cover.jpg',
        mlClassIndex: 15,
      ),
      BatikMotifModel(
        id: 17,
        name: 'Liong',
        slug: 'liong',
        originRegion: 'Pesisir Lasem, Indramayu, & Pekalongan',
        shortDescription: 'Akulturasi agung pesisir Jawa-Tionghoa berhias naga pelindung alam dan burung Phoenix keabadian.',
        thumbnailUrl: 'assets/images/batik/liong_cover.jpg',
        mlClassIndex: 16,
      ),
      BatikMotifModel(
        id: 18,
        name: 'Mega Mendung',
        slug: 'mega_mendung',
        originRegion: 'Keraton Kasepuhan Cirebon & Sentra Trusmi',
        shortDescription: 'Gradasi tujuh lapis awan sejuk pesisir Cirebon lambang kesabaran dan pengendalian amarah.',
        thumbnailUrl: 'assets/images/batik/mega_mendung_cover.jpg',
        mlClassIndex: 17,
      ),
      BatikMotifModel(
        id: 19,
        name: 'Parang (Parang Rusak)',
        slug: 'parang',
        originRegion: 'Keraton Kasultanan Yogyakarta & Surakarta',
        shortDescription: 'Batik larangan utama Mataram ciptaan Panembahan Senopati lambang semangat pantang menyerah.',
        thumbnailUrl: 'assets/images/batik/parang_cover.jpg',
        mlClassIndex: 18,
      ),
      BatikMotifModel(
        id: 20,
        name: 'Sekar Jagad',
        slug: 'sekarjagad',
        originRegion: 'Keraton Kasunanan Surakarta & Yogyakarta',
        shortDescription: 'Miniatur keindahan keragaman dunia dalam hamparan pulau-pulau bunga nusantara yang harmonis.',
        thumbnailUrl: 'assets/images/batik/sekarjagad_cover.jpg',
        mlClassIndex: 19,
      ),
    ];

    // 3. Daftar 20 Modul Belajar — Bersumber dari 2 Dokumen Akademik Batik PBL
    _modules = [
      ModuleModel(
        id: 1,
        motifId: 1,
        title: 'Batik Sido Luhur',
        description: 'Batik klasik Surakarta perlambang keluhuran budi pekerti, derajat mulia, dan doa pernikahan adat.',
        coverImage: 'assets/images/batik/sidoluhur_cover.jpg',
        orderNo: 1,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Batik Klasik Keraton Surakarta Hadiningrat',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=fCXqQKYqsX4',
            deskripsiUtama: 'Motif Sido Luhur merupakan salah satu motif batik klasik adiluhung yang tumbuh dan mengakar di lingkungan Keraton Surakarta Hadiningrat. Kata \'sido\' dalam bahasa Jawa berarti terlaksana atau terwujud, sedangkan \'luhur\' bermakna mulia, agung, dan bermartabat. Garis dan ornamennya melambangkan permohonan batin agar pemakainya mencapai keluhuran budi pekerti serta martabat yang dihormati di hadapan sesama dan Tuhan Yang Maha Esa.',
            asalDaerah: 'Muncul dan berkembang pesat pada era kejayaan Keraton Mataram Islam hingga Kasunanan Surakarta. Batik ini difungsikan bukan sekadar busana, melainkan media doa visual sakral bagi para bangsawan, kerabat sentana dalem, dan abdi dalem keraton.',
            maknaFilosofis: 'Mengandung doa luhur agar pemakainya senantiasa berbudi pekerti luhur, saleh, dan bermanfaat bagi masyarakat luas. Dalam tradisi Jawa, kemuliaan sejati bukan semata tahta atau kekayaan duniawi, melainkan keluhuran moral, integritas batin, dan keharmonisan hubungan manusia dengan Sang Pencipta.',
            penggunaan: 'Termasuk dalam kelompok batik larangan (awisan dalem) Keraton Surakarta. Wajib dikenakan oleh pengantin dalam prosesi sakral panggih dan midodareni sebagai restu kemuliaan bahtera rumah tangga.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Struktur geometris ceplok simetris dengan ornamen isen flora fauna pengisi bidang bertabur warna sogan khas Solo.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Pola Ceplok Geometris Berulang',
              desc: 'Bentuk belah ketupat dan lingkaran berulang teratur melambangkan keteraturan kosmis.',
              badge: 'Struktur Utama • Ceplok',
              image: 'assets/images/batik/sidoluhur_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Ornamen Flora & Fauna Pengisi',
              desc: 'Isen mikro berupa kuncup bunga, dedaunan sulur, dan burung pengisi bidang ruang.',
              badge: 'Isen Halus',
              image: 'assets/images/batik/sidoluhur_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Warna Sogan Klasik Solo',
              desc: 'Perpaduan cokelat soga tua alami, oker keemasan, dan latar krem mori putih bersih.',
              badge: 'Pewarna Alami Sogan',
              image: 'assets/images/batik/sidoluhur_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Pola Ceplok Simetris', desc: 'Bidang ceplok disusun secara matematis dan seimbang di seluruh bentangan kain mori.'),
              PakemModel(title: '2. Ragam Isen Flora & Burung', desc: 'Setiap ruang ceplok diisi canting cecek dan sawut halus ornamen hayati penanda kehidupan.'),
              PakemModel(title: '3. Pewarnaan Sogan Surakarta', desc: 'Menggunakan ekstraksi kayu soga jambal dan tingi berlatar putih gading tanpa noda malam.'),
              PakemModel(title: '4. Busana Upacara Sakral Panggih', desc: 'Dipakai khusus sebagai jarik basahan pengantin dalam prosesi temu manten adat Jawa.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/sidoluhur_gal_1.jpg', caption: 'Kain Batik Tulis Sido Luhur Klasik Keraton'),
            GaleriModel(imageUrl: 'assets/images/batik/sidoluhur_gal_2.jpg', caption: 'Detail Pola Ceplok dan Isen Cecek Halus'),
            GaleriModel(imageUrl: 'assets/images/batik/sidoluhur_gal_3.jpg', caption: 'Pencantingan Malam Tembokan Sido Luhur'),
            GaleriModel(imageUrl: 'assets/images/batik/sidoluhur_gal_4.jpg', caption: 'Pewarnaan Sogan Cokelat Tradisional'),
            GaleriModel(imageUrl: 'assets/images/batik/sidoluhur_gal_5.jpg', caption: 'Busana Pengantin Adat Jawa Panggih'),
          ],
        ),
      ),
      ModuleModel(
        id: 2,
        motifId: 2,
        title: 'Batik Sido Mukti',
        description: 'Batik sakral Mataram lambang kemakmuran, kesejahteraan lahir batin, dan keharmonisan hidup.',
        coverImage: 'assets/images/batik/sidomukti_cover.jpg',
        orderNo: 2,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Mataram, Surakarta & Yogyakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=8sBgN7Mvz_A',
            deskripsiUtama: 'Batik Sido Mukti memancarkan aura keteduhan dan kemakmuran yang berakar dari tradisi luhur Keraton Mataram Islam. Kata \'sido\' bermakna jadi atau terlaksana, sedangkan \'mukti\' berarti sejahtera, tenteram, dan serba berkecukupan. Kain ini merupakan perwujudan doa agar pemakainya senantiasa dinaungi kemakmuran sejati, kedamaian hati, dan kebahagiaan lahir batin.',
            asalDaerah: 'Lahir pada masa pemerintahan Sultan Agung Hanyakrakusuma di Kesultanan Mataram, kemudian dilestarikan secara turun-temurun di Kasunanan Surakarta dan Kasultanan Ngayogyakarta Hadiningrat.',
            maknaFilosofis: 'Filosofi \'mukti\' mencakup kesejahteraan holistik: bukan hanya melimpahnya rezeki materi, melainkan ketenangan jiwa, kerukunan sanak keluarga, dan keberkahan hidup. Mengajarkan keseimbangan antara mengejar urusan dunia dan mempersiapkan bekal akhirat.',
            penggunaan: 'Dikenakan oleh kedua mempelai pada upacara akad nikah dan prosesi panggih pengantin Jawa. Juga digunakan pada perayaan adat penting seperti khitanan keluarga keraton dan tradisi tedhak siten.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Pola ceplok berulang dengan ornamen utama burung merak, kupu-kupu, dan bunga berselaras warna sogan beraksen tegas.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Ceplok Ornamen Burung Merak & Kupu-Kupu',
              desc: 'Pasangan ornamen fauna anggun melambangkan keindahan cinta dan kebebasan jiwa mulia.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/sidomukti_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Pohon Hayat & Singgasana Mahkota',
              desc: 'Simbol perlindungan semesta dan kemuliaan derajat dalam kosmologi keraton Jawa.',
              badge: 'Ragam Ornamen',
              image: 'assets/images/batik/sidomukti_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Cokelat Beraksen Hitam & Putih',
              desc: 'Sentuhan kontras tegas sogan Mataraman dengan latar putih gading yang khidmat.',
              badge: 'Warna Keraton',
              image: 'assets/images/batik/sidomukti_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Pola Ceplok Teratur', desc: 'Bidang kotak atau belah ketupat tersusun konsisten membentang dari ujung ke ujung.'),
              PakemModel(title: '2. Pasangan Ornamen Merak & Flora', desc: 'Wajib memuat elemen merak atau kupu-kupu yang dikelilingi dedaunan dan bunga mekar.'),
              PakemModel(title: '3. Keseimbangan Kontras Warna', desc: 'Gradasi sogan matang dipadu aksen garis kontur hitam pekat (babaran wedelan).'),
              PakemModel(title: '4. Pakaian Sakral Ijab Qobul', desc: 'Dikenakan mempelai sebagai simbol kesiapan membangun rumah tangga mandiri dan sejahtera.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/sidomukti_gal_1.jpg', caption: 'Kain Jarik Sido Mukti Keraton Mataram'),
            GaleriModel(imageUrl: 'assets/images/batik/sidomukti_gal_2.jpg', caption: 'Detail Canting Merak dan Kupu-Kupu'),
            GaleriModel(imageUrl: 'assets/images/batik/sidomukti_gal_3.jpg', caption: 'Jejak Lilin Malam Motif Gurda Sido Mukti'),
            GaleriModel(imageUrl: 'assets/images/batik/sidomukti_gal_4.jpg', caption: 'Proses Pewarnaan Wedelan dan Sogan'),
            GaleriModel(imageUrl: 'assets/images/batik/sidomukti_gal_5.jpg', caption: 'Pemakaian Sido Mukti pada Upacara Akad Nikah'),
          ],
        ),
      ),
      ModuleModel(
        id: 3,
        motifId: 3,
        title: 'Batik Sido Mulyo',
        description: 'Simbol harapan kemuliaan derajat, integritas martabat ningrat, dan keberkahan budi pekerti.',
        coverImage: 'assets/images/batik/sidomulyo_cover.jpg',
        orderNo: 3,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Surakarta & Yogyakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=dqzFIu002NM',
            deskripsiUtama: 'Sido Mulyo merupakan salah satu motif agung dalam rumpun batik \'Sido\' keraton Jawa. Kata \'mulyo\' bermakna mulia, terhormat, dan diberkahi derajat tinggi. Berkembang pesat sejak abad ke-18 sebagai pakaian kehormatan para pembesar keraton, melambangkan perjalanan hidup insan yang meniti kemuliaan lewat ketekunan ikhtiar dan ketulusan doa.',
            asalDaerah: 'Berkembang di lingkungan keraton Surakarta dan Yogyakarta pada abad ke-18 hingga ke-19, difungsikan sebagai salah satu batik larangan resmi dalam lingkungan keraton.',
            maknaFilosofis: 'Kemuliaan sejati dalam falsafah Jawa diraih apabila manusia mampu memberi manfaat nyata bagi sesamanya serta menjaga integritas nama baik leluhur. Sido Mulyo memuat amanah moral agar manusia senantiasa rendah hati saat mencapai puncak kesuksesan.',
            penggunaan: 'Dikenakan oleh para bangsawan pada prosesi upacara wisuda keraton, pisowanan agung, serta dipakai oleh mempelai pengantin adat Jawa sebagai doa kemuliaan hidup.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Variasi pola ceplok teratur yang dipadukan ornamen truntum, pohon hayat, serta satwa bersayap lambang kemuliaan.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Ceplok Variasi Truntum & Pohon Hayat',
              desc: 'Perpaduan bidang ceplok dengan taburan kuntum truntum mikro pembawa cinta abadi.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/sidomulyo_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Burung Garuda & Kupu-Kupu Anggun',
              desc: 'Goresan sayap garuda mini melambangkan ketangkasan budi dan kebesaran jiwa ksatria.',
              badge: 'Isen Gurda',
              image: 'assets/images/batik/sidomulyo_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Klasik Berlatar Putih Mori Prima',
              desc: 'Warna cokelat soga tua di atas dasar putih krem yang memancarkan kewibawaan.',
              badge: 'Warna Adiluhung',
              image: 'assets/images/batik/sidomulyo_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Pola Ceplok Sudut Sejajar', desc: 'Penataan ornamen ceplok dengan simetri seimbang pada sudut diagonal maupun horizontal.'),
              PakemModel(title: '2. Sisipan Isen Truntum & Cecek', desc: 'Ruang kosong ceplok diisi canting cecek bintang mikro yang rapi tanpa celah renggang.'),
              PakemModel(title: '3. Garis Kontur Halus Mori', desc: 'Liku canting malam tegas membentuk garis pembatas bidang yang bersih.'),
              PakemModel(title: '4. Busana Resmi Upacara Keraton', desc: 'Digunakan sebagai kain panjang (jarik) dan kemben bangsawan dalam perhelatan agung.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/sidomulyo_gal_1.jpg', caption: 'Bentangan Kain Tulis Sido Mulyo Kasunanan'),
            GaleriModel(imageUrl: 'assets/images/batik/sidomulyo_gal_2.jpg', caption: 'Detail Ornamen Gurda dan Ceplok Truntum'),
            GaleriModel(imageUrl: 'assets/images/batik/sidomulyo_gal_3.jpg', caption: 'Kerapatan Canting Isen Cecek Tembokan'),
            GaleriModel(imageUrl: 'assets/images/batik/sidomulyo_gal_4.jpg', caption: 'Pencelupan Pewarna Kulit Kayu Tingi'),
            GaleriModel(imageUrl: 'assets/images/batik/sidomulyo_gal_5.jpg', caption: 'Aplikasi Jarik Sido Mulyo Tradisi Jawa'),
          ],
        ),
      ),
      ModuleModel(
        id: 4,
        motifId: 4,
        title: 'Batik Singa Barong',
        description: 'Mahakarya spiritual Keraton Cirebon perlambang kekuatan kepemimpinan dan penolak bala.',
        coverImage: 'assets/images/batik/singa_barong_cover.jpg',
        orderNo: 4,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Kasepuhan & Kanoman Cirebon',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=GN1C21aeYHo',
            deskripsiUtama: 'Motif Singa Barong adalah adikarya keraton Cirebon yang merefleksikan perpaduan spiritualitas Islam, kebudayaan Hindu-Buddha, dan pengaruh peradaban Tionghoa. Wujud Singa Barong terinspirasi dari kereta kebesaran Keraton Kasepuhan Cirebon buatan Panembahan Losari tahun 1549, yang menggabungkan empat unsur makhluk sakral: singa bertubuh gajah, bersayap garuda, dan berbelalai naga.',
            asalDaerah: 'Diciptakan dan berkembang di lingkungan Keraton Kasepuhan dan Kanoman Cirebon pada masa dakwah Sunan Gunung Jati dan para wali Cirebon.',
            maknaFilosofis: 'Singa melambangkan keberanian, belalai gajah melambangkan keteguhan persahabatan, sayap garuda melambangkan keagungan spiritual Islam, dan naga melambangkan keabadian. Menjadi simbol pemimpin adil dan penolak marabahaya lahir batin.',
            penggunaan: 'Tergolong batik larangan wingit di Keraton Cirebon. Dahulu hanya boleh dipakai oleh Sultan dan putra mahkota pada upacara penobatan dan perayaan Grebeg Syawal.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Figur chimera mitologi Singa Barong bersayap garuda bermahkota, dikelilingi ornamen wadasan karang dan lidah api pesisir.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Figur Singa Barong Keraton',
              desc: 'Makhluk mitologis bermahkota megah dengan sayap terbentang dan belalai meliuk gagah.',
              badge: 'Figur Utama',
              image: 'assets/images/batik/singa_barong_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Wadasan Karang & Lidah Api Membara',
              desc: 'Batuan karang wadas khas Cirebon berpadu lidah api penolak marabahaya gaib.',
              badge: 'Ornamen Wadasan',
              image: 'assets/images/batik/singa_barong_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Paduan Sogan Tua, Hitam Pekat & Emas',
              desc: 'Dominasi warna gelap wadasan dengan aksen garis malam cokelat keemasan yang berwibawa.',
              badge: 'Warna Sakral',
              image: 'assets/images/batik/singa_barong_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Anatomi Empat Unsur Satwa', desc: 'Harus memuat paduan kepala singa berbelalai gajah, bersayap garuda, dan berekor naga.'),
              PakemModel(title: '2. Kehadiran Ornamen Wadasan', desc: 'Dasar bidang bawah wajib dihiasi ornamen batu karang wadas khas ukiran Cirebon.'),
              PakemModel(title: '3. Liukan Lidah Api Sakral', desc: 'Lidah api di sekeliling figur melambangkan energi pembersih aura negatif dan tolak bala.'),
              PakemModel(title: '4. Busana Kebesaran Sultan', desc: 'Dikhususkan bagi keluarga inti keraton pada prosesi adat keraton pesisir Cirebon.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/singa_barong_gal_1.jpg', caption: 'Lukisan Kain Batik Singa Barong Cirebon'),
            GaleriModel(imageUrl: 'assets/images/batik/singa_barong_gal_2.jpg', caption: 'Detail Kepala Singa Berbelalai dan Mahkota'),
            GaleriModel(imageUrl: 'assets/images/batik/singa_barong_gal_3.jpg', caption: 'Ornamen Wadasan dan Lidah Api Pesisir'),
            GaleriModel(imageUrl: 'assets/images/batik/singa_barong_gal_4.jpg', caption: 'Proses Pembuatan Canting Malam Halus'),
            GaleriModel(imageUrl: 'assets/images/batik/singa_barong_gal_5.jpg', caption: 'Replika Kereta Singa Barong Keraton Kasepuhan'),
          ],
        ),
      ),
      ModuleModel(
        id: 5,
        motifId: 5,
        title: 'Batik Srikaton',
        description: 'Persembahan doa kemakmuran nyata Dewi Sri, kesuburan bumi agraris, dan panen melimpah.',
        coverImage: 'assets/images/batik/srikaton_cover.jpg',
        orderNo: 5,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Mataram & Tradisi Agraris Jawa',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: '',
            deskripsiUtama: 'Srikaton berakar dari kata \'Sri\' yang merujuk pada Dewi Sri (dewi kesuburan, pangan, dan kemakmuran dalam mitologi Jawa) dan \'katon\' yang berarti tampak jelas atau nyata terwujud. Motif ini lahir dari kearifan masyarakat agraris Nusantara sebagai wujud rasa syukur mendalam kepada Sang Maha Pencipta atas anugerah tanah yang subur dan hasil bumi yang melimpah ruah.',
            asalDaerah: 'Berkembang di wilayah pertanian subur Jawa Tengah dan Daerah Istimewa Yogyakarta sejak era Mataram Kuno hingga Mataram Islam.',
            maknaFilosofis: 'Kemakmuran sejati adalah kemakmuran yang dapat dirasakan nyata oleh seluruh lapisan masyarakat. Mengajarkan manusia untuk menjaga kelestarian alam, tidak serakah terhadap hasil bumi, dan senantiasa berbagi rezeki kepada sesama yang membutuhkan.',
            penggunaan: 'Dikenakan oleh sesepuh desa dan keluarga bangsawan agraris dalam upacara adat sedekah bumi, tradisi wiwitan menjelang panen raya, serta perayaan syukuran panen padi.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Gubahan geometris harmonis menyerupai bulir padi bernas, tangkai kapas ranum, dan sulur tanaman subur berpewarna alam.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Untaian Bulir Padi & Daun Ranum',
              desc: 'Goresan canting melengkung menggambarkan batang padi merunduk penuh bulir berkah.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/srikaton_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Kuncup Bunga Padi & Isen Beras Wutah',
              desc: 'Titik cecek mikro menyerupai butiran beras bertaburan lambang rezeki tanpa henti.',
              badge: 'Isen Beras Wutah',
              image: 'assets/images/batik/srikaton_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Klasik Berpadu Hijau & Emas',
              desc: 'Cokelat tanah subur berpadu aksen hijau pupus daun dan kuning keemasan gabah matang.',
              badge: 'Warna Alam Agraris',
              image: 'assets/images/batik/srikaton_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Rangkaian Tangkai Padi Bernas', desc: 'Motif utama menampilkan gerak tangkai padi yang merunduk sebagai simbol kerendahan hati.'),
              PakemModel(title: '2. Isen Butir Beras (Beras Wutah)', desc: 'Bagian latar dipenuhi bintik cecek mikro yang melambangkan rezeki pangan melimpah.'),
              PakemModel(title: '3. Keseimbangan Tata Bidang Geometris', desc: 'Tangkai dan daun disusun berulang secara seimbang memancarkan ketenteraman.'),
              PakemModel(title: '4. Busana Upacara Adat Sedekah Bumi', desc: 'Dikenakan sebagai sarung atau jarik dalam ritual wiwitan persembahan syukur agraris.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/srikaton_gal_1.jpg', caption: 'Kain Batik Srikaton Padi Bernas Keemasan'),
            GaleriModel(imageUrl: 'assets/images/batik/srikaton_gal_2.jpg', caption: 'Detail Canting Bulir Padi dan Isen Beras'),
            GaleriModel(imageUrl: 'assets/images/batik/srikaton_gal_3.jpg', caption: 'Pola Geometris Tangkai Tanaman Pangan'),
            GaleriModel(imageUrl: 'assets/images/batik/srikaton_gal_4.jpg', caption: 'Proses Pewarnaan Alami Kayu dan Daun'),
            GaleriModel(imageUrl: 'assets/images/batik/srikaton_gal_5.jpg', caption: 'Prosesi Upacara Wiwitan Tradisi Jawa'),
          ],
        ),
      ),
      ModuleModel(
        id: 6,
        motifId: 6,
        title: 'Batik Tribusono',
        description: 'Harmonisasi kosmologi tiga alam Jawa: kebenaran, keindahan, dan kebaikan hidup semesta.',
        coverImage: 'assets/images/batik/tribusono_cover.jpg',
        orderNo: 6,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Surakarta & Yogyakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=o8bI9dauR0Q',
            deskripsiUtama: 'Tribusono berasal dari dua kata sakral: \'tri\' yang berarti tiga, dan \'busono\' yang berarti pakaian atau tatanan dunia. Motif ini merupakan kristalisasi falsafah kosmologi Jawa kuno mengenai Triloka (tiga alam kehidupan): alam atas (langit/ilahi), alam tengah (manusia dan sesama makhluk), serta alam bawah (bumi, air, dan kesuburan materiil). Nilai ini diselaraskan dalam budaya Islam-Jawa sebagai tuntunan hidup seimbang.',
            asalDaerah: 'Tumbuh dan dilestarikan oleh para empu batik di lingkungan Keraton Surakarta dan Yogyakarta sebagai busana para tetua adat.',
            maknaFilosofis: 'Mengajarkan keselarasan tiga pilar utama eksistensi manusia: hubungan batin dengan Tuhan (hablun minallah), kasih sayang antarsesama manusia (hablun minannas), dan kepedulian terhadap kelestarian alam semesta (hablun minal alam).',
            penggunaan: 'Dikenakan oleh para sesepuh keraton, tokoh spiritual, dan guru kebajikan dalam upacara perenungan batin, malam 1 Suro, serta ritual syukuran adat.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Pembagian bidang kain secara tri-zona vertikal atau horizontal yang memuat ragam ornamen simbolik tiga alam semesta.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Trilogi Bidang Kosmologi Tiga Alam',
              desc: 'Zona atas awan langit, zona tengah satwa darat/flora, dan zona bawah riak air dasar bumi.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/tribusono_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Burung Udara, Tumbuhan & Ikan Air',
              desc: 'Keharmonisan aneka makhluk pengisi alam raya yang hidup berdampingan dalam damai.',
              badge: 'Simbol Tiga Alam',
              image: 'assets/images/batik/tribusono_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Klasik Bergradasi Tiga Dimensi',
              desc: 'Peralihan warna lembut dari cokelat pekat dasar bumi ke krem terang cakrawala langit.',
              badge: 'Gradasi Sogan',
              image: 'assets/images/batik/tribusono_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Pembagian Bidang Tri-Zona Teratur', desc: 'Kain dibagi menjadi tiga lapisan motif yang berbeda namun saling menyatu harmonis.'),
              PakemModel(title: '2. Representasi Flora & Fauna Tiga Dimensi', desc: 'Memuat ornamen udara (unggas/awan), daratan (tumbuhan), dan perairan (ombak/ikan).'),
              PakemModel(title: '3. Keseimbangan Komposisi Garis Kontur', desc: 'Tarikan garis canting menghubungkan ketiga zona tanpa kesan terputus canggung.'),
              PakemModel(title: '4. Pakaian Kehormatan Para Sesepuh', desc: 'Menjadi busana martabat para tokoh adat dalam memimpin upacara adat perenungan.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/tribusono_gal_1.jpg', caption: 'Kain Panjang Tribusono Kosmologi Jawa'),
            GaleriModel(imageUrl: 'assets/images/batik/tribusono_gal_2.jpg', caption: 'Detail Zona Langit dengan Ornamen Burung'),
            GaleriModel(imageUrl: 'assets/images/batik/tribusono_gal_3.jpg', caption: 'Zona Daratan dengan Ragam Sulur Flora'),
            GaleriModel(imageUrl: 'assets/images/batik/tribusono_gal_4.jpg', caption: 'Zona Perairan dengan Geliat Riak Air'),
            GaleriModel(imageUrl: 'assets/images/batik/tribusono_gal_5.jpg', caption: 'Proses Pencantingan Teliti Tiga Lapisan'),
          ],
        ),
      ),
      ModuleModel(
        id: 7,
        motifId: 7,
        title: 'Batik Tujuh Rupa',
        description: 'Simbol kebhinekaan pesisir Pekalongan berhias tujuh ornamen flora fauna aneka warna cerah.',
        coverImage: 'assets/images/batik/tujuh_rupa_cover.jpg',
        orderNo: 7,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Sentra Batik Pesisir Kota Pekalongan',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=_aVvMX2dXCE',
            deskripsiUtama: 'Batik Tujuh Rupa adalah ikon kebanggaan masyarakat pesisir Pekalongan yang lahir dari geliat pelabuhan niaga internasional sejak abad ke-19. Dinamakan Tujuh Rupa karena menyatukan tujuh motif visual berbeda dalam satu helai kain. Motif ini menjadi bukti hidup akulturasi damai peradaban Jawa pesisiran dengan pedagang Tionghoa, Arab, Melayu, dan bangsa Eropa yang singgah berabad-abad di pesisir utara Jawa.',
            asalDaerah: 'Diciptakan dan diproduksi massal oleh komunitas pembatik pesisir di sentra-sentra kerajinan batik Pekalongan, Jawa Tengah.',
            maknaFilosofis: 'Keberagaman bukanlah pemisah, melainkan kekayaan estetika dan spiritual yang saling melengkapi. Tujuh ornamen menyimbolkan kelimpahan jalan rezeki, keleluasaan wawasan, sifat toleransi, serta keluwesan beradaptasi dengan kemajuan peradaban zaman.',
            penggunaan: 'Bebas dari aturan kaku batik larangan keraton. Dipakai secara luas oleh masyarakat untuk busana pesta perayaan, kebaya encim, kemeja resmi, hingga gaun modern bernuansa nusantara.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Komposisi dinamis memuat tujuh ornamen alam (kupu-kupu, burung, krisan, mawar, dedaunan, ikan, teratai) dalam warna-warni cerah pesisiran.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Tujuh Ragam Hias Flora & Fauna',
              desc: 'Tiap sudut kain memancarkan keceriaan paduan kupu-kupu, krisan, dan burung merak cerah.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/tujuh_rupa_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Isen Sawut Lembut & Cecek Melingkar',
              desc: 'Goresan sawut canting halus memberikan kesan timbul hidup pada kelopak bunga mekar.',
              badge: 'Isen Sawut Pesisir',
              image: 'assets/images/batik/tujuh_rupa_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Palet Cerah Menyala Pesisir Pekalongan',
              desc: 'Harmoni berani warna merah delima, biru laut, hijau zamrud, kuning cerah, dan oranye.',
              badge: 'Warna Pesisiran',
              image: 'assets/images/batik/tujuh_rupa_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Minimal Memuat Tujuh Unsur Ornamen', desc: 'Dalam satu kain terdapat tujuh ragam flora fauna yang saling mengisi ruang estetika.'),
              PakemModel(title: '2. Tata Letak Asimetris Ekspresif', desc: 'Komposisi dinamis khas pesisir yang tidak terikat kekakuan simetri geometris keraton.'),
              PakemModel(title: '3. Pewarnaan Cerah Bertingkat', desc: 'Menggunakan pewarna cerah dengan teknik kuasan dan celupan berulang yang hidup.'),
              PakemModel(title: '4. Keserasian Ragam Budaya Akulturasi', desc: 'Gaya floral Eropa bersanding serasi dengan sentuhan kupu-kupu oriental Tionghoa.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/tujuh_rupa_gal_1.jpg', caption: 'Kain Batik Tujuh Rupa Pekalongan Aneka Warna'),
            GaleriModel(imageUrl: 'assets/images/batik/tujuh_rupa_gal_2.jpg', caption: 'Detail Kupu-Kupu dan Bunga Krisan Merah'),
            GaleriModel(imageUrl: 'assets/images/batik/tujuh_rupa_gal_3.jpg', caption: 'Ornamen Burung Pesisir dengan Isen Sawut'),
            GaleriModel(imageUrl: 'assets/images/batik/tujuh_rupa_gal_4.jpg', caption: 'Proses Pewarnaan Celup Multitahap Pekalongan'),
            GaleriModel(imageUrl: 'assets/images/batik/tujuh_rupa_gal_5.jpg', caption: 'Aplikasi Batik Tujuh Rupa pada Busana Kebaya'),
          ],
        ),
      ),
      ModuleModel(
        id: 8,
        motifId: 8,
        title: 'Batik Tuntrum (Truntum)',
        description: 'Kilau gemintang cinta abadi ciptaan Kanjeng Ratu Kencana Kasunanan Surakarta.',
        coverImage: 'assets/images/batik/tuntrum_cover.jpg',
        orderNo: 8,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Kasunanan Surakarta Hadiningrat',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=zoC_dYfpdiA',
            deskripsiUtama: 'Motif Tuntrum (lebih populer disebut Truntum) diciptakan oleh Kanjeng Ratu Kencana, permaisuri Sri Susuhunan Pakubuwono III dari Keraton Kasunanan Surakarta pada abad ke-18. Sang Ratu yang berduka karena merasa cinta baginda raja memudar, duduk mencanting di keheningan malam menatap taburan bintang di langit. Titik-titik bintang itulah yang melahirkan motif Truntum, hingga cinta sang Raja kembali bersemi tulus.',
            asalDaerah: 'Lahir di Keraton Kasunanan Surakarta Hadiningrat, kemudian meluas pengaruh pemakaiannya ke Keraton Yogyakarta dan peradaban Jawa.',
            maknaFilosofis: 'Kata \'truntum\' berasal dari istilah Jawa \'taruntum\' yang berarti tumbuh, bersemi kembali, atau menuntun. Melambangkan cinta tulus tanpa pamrih yang tidak pernah padam, kesetiaan suci, serta ketulusan batin yang senantiasa menuntun orang lain ke jalan kebaikan.',
            penggunaan: 'Termasuk salah satu motif paling sakral dalam tata pernikahan adat Jawa. Wajib dikenakan oleh orang tua kedua mempelai saat prosesi ijab qobul dan panggih sebagai doa restu cinta lestari.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Repetisi tebaran kuntum bunga melati mikro menyerupai gemintang bercahaya di atas dasar kain hitam kelam.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Kuntum Bintang Melati Berkelopak Enam',
              desc: 'Kuntum bunga mungil tersusun teratur dengan titik cecek mikro di setiap kelopak bunganya.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/tuntrum_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Taburan Isen Cecek Bintang Malam',
              desc: 'Titik-titik lilin malam presisi yang menyerupai gemerlap bintang di langit hening malam.',
              badge: 'Isen Cecek Halus',
              image: 'assets/images/batik/tuntrum_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Kontras Hitam Pekat & Cokelat Soga',
              desc: 'Latar belakang hitam pekat melambangkan malam hening berpadu cokelat soga keemasan.',
              badge: 'Warna Tradisi Keraton',
              image: 'assets/images/batik/tuntrum_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Kerapatan Kuntum Bunga Seragam', desc: 'Jarak antar kuntum bunga melati bintang harus konsisten di seluruh bentangan kain mori.'),
              PakemModel(title: '2. Latar Hitam Gelap Tanpa Corak Tambahan', desc: 'Warna dasar wajib hitam pekat atau sogan gelap tanpa ornamen pengganggu konsentrasi bintang.'),
              PakemModel(title: '3. Kerapian Cecek Canting Mikro', desc: 'Setiap kuntum ditorehkan canting cecek sangat halus sebagai perlambang ketelitian budi.'),
              PakemModel(title: '4. Busana Kehormatan Orang Tua Pengantin', desc: 'Dikhususkan bagi orang tua mempelai sebagai lambang doa restu dan panutan cinta sejati.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/tuntrum_gal_1.jpg', caption: 'Kain Jarik Truntum Klasik Keraton Solo'),
            GaleriModel(imageUrl: 'assets/images/batik/tuntrum_gal_2.jpg', caption: 'Detail Kuntum Bintang Bunga Melati Mikro'),
            GaleriModel(imageUrl: 'assets/images/batik/tuntrum_gal_3.jpg', caption: 'Goresan Canting Cecek Halus pada Mori Hitam'),
            GaleriModel(imageUrl: 'assets/images/batik/tuntrum_gal_4.jpg', caption: 'Pencelupan Babaran Wedelan Hitam Pekat'),
            GaleriModel(imageUrl: 'assets/images/batik/tuntrum_gal_5.jpg', caption: 'Prosesi Sungkeman Pernikahan Adat Jawa'),
          ],
        ),
      ),
      ModuleModel(
        id: 9,
        motifId: 9,
        title: 'Batik Wahyu Tumurun',
        description: 'Batik larangan agung perlambang turunnya rahmat, hidayah, dan berkah ilahi bagi pemimpin.',
        coverImage: 'assets/images/batik/wahyu_tumurun_cover.jpg',
        orderNo: 9,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Kasultanan Yogyakarta & Surakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=Cq6NxsuzXfc',
            deskripsiUtama: 'Wahyu Tumurun merupakan salah satu motif batik keraton paling sakral berdimensi spiritual tinggi. Kata \'wahyu\' bermakna petunjuk, ilham, atau anugerah rahmat dari Tuhan Yang Maha Esa, sedangkan \'tumurun\' bermakna turun ke bumi. Motif ini diciptakan pada masa Sultan Agung Hanyakrakusuma di Kesultanan Mataram sebagai perlambang permohonan anugerah wahyu kepemimpinan dan kemuliaan hidup.',
            asalDaerah: 'Diciptakan di lingkungan Keraton Mataram Islam dan dilestarikan oleh Keraton Yogyakarta maupun Keraton Surakarta.',
            maknaFilosofis: 'Mengandung harapan mendalam agar pemakainya senantiasa memperoleh bimbingan, petunjuk, berkah, serta ketetapan hati dari Sang Maha Pencipta. Mengajarkan bahwa kemuliaan tahta dan kedudukan manusia hanyalah amanah titipan ilahi yang harus diemban dengan rendah hati.',
            penggunaan: 'Termasuk kategori batik larangan sakral (awisan dalem). Dikenakan oleh raja pada upacara jumenengan (penobatan tahta), tingalan dalem (ulang tahun kenaikan tahta), serta prosesi pernikahan agung bangsawan.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Mahkota terbang agung yang diapit sepasang sayap garuda perkasa, dilingkupi ornamen pohon hayat, awan, dan dedaunan suci.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Mahkota Terbang & Sepasang Sayap Lar',
              desc: 'Mahkota kebesaran diapit sayap garuda membentang kokoh melambangkan perlindungan ilahi.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/wahyu_tumurun_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Pohon Hayat & Kuncup Bunga Teratai',
              desc: 'Pohon kehidupan dan kuncup bunga suci yang memancarkan aura kesucian dan kebijaksanaan.',
              badge: 'Pohon Hayat Sakral',
              image: 'assets/images/batik/wahyu_tumurun_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Keraton Mataram Beraksen Emas',
              desc: 'Cokelat soga matang berpadu latar putih gading dengan garis kontur tegas berwibawa.',
              badge: 'Warna Sakral Keraton',
              image: 'assets/images/batik/wahyu_tumurun_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Figur Mahkota di Puncak Poros', desc: 'Wajib memiliki ornamen mahkota keraton yang melayang diapit kedua sayap membentang.'),
              PakemModel(title: '2. Pasangan Sayap Garuda Simetris', desc: 'Sayap lar garuda digambarkan kokoh dengan susunan bulu sayap yang teratur rapi.'),
              PakemModel(title: '3. Rangkaian Pohon Hayat & Flora Berkah', desc: 'Bagian bawah ditopang pohon hayat dan flora penyangga kehidupan semesta.'),
              PakemModel(title: '4. Busana Jumenengan & Pisowanan Agung', desc: 'Dikenakan dalam perhelatan paling khidmat di bangsal keraton oleh para bangsawan.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/wahyu_tumurun_gal_1.jpg', caption: 'Bentangan Kain Batik Tulis Wahyu Tumurun'),
            GaleriModel(imageUrl: 'assets/images/batik/wahyu_tumurun_gal_2.jpg', caption: 'Detail Ornamen Mahkota dan Sayap Lar Garuda'),
            GaleriModel(imageUrl: 'assets/images/batik/wahyu_tumurun_gal_3.jpg', caption: 'Pohon Hayat dan Rangkaian Bunga Berkah'),
            GaleriModel(imageUrl: 'assets/images/batik/wahyu_tumurun_gal_4.jpg', caption: 'Proses Pencantingan Malam Tembokan Detail'),
            GaleriModel(imageUrl: 'assets/images/batik/wahyu_tumurun_gal_5.jpg', caption: 'Upacara Jumenengan Keraton Kasultanan'),
          ],
        ),
      ),
      ModuleModel(
        id: 10,
        motifId: 10,
        title: 'Batik Wirasat',
        description: 'Tuntunan kebijaksanaan batin, intuisi membaca tanda alam, dan kumpulan doa restu sesepuh.',
        coverImage: 'assets/images/batik/wirasat_cover.jpg',
        orderNo: 10,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Surakarta & Yogyakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=ek-N7hAX1R8',
            deskripsiUtama: 'Wirasat berakar dari kata bahasa Jawa \'wirasat\' (atau firasat) yang berarti petunjuk kebijaksanaan, bisikan nurani, atau ramalan kearifan. Motif ini merupakan kompilasi dari berbagai motif batik klasik Jawa bertuah yang dirangkum menjadi satu susunan ceplok geometris. Diciptakan oleh empu keraton sebagai pakaian media doa agar pemakainya dianugerahi ketajaman mata batin dalam menuntun anak cucunya.',
            asalDaerah: 'Berkembang di lingkungan Kasunanan Surakarta dan Kasultanan Yogyakarta sebagai busana kehormatan para tetua adat.',
            maknaFilosofis: 'Mengajarkan pentingnya kepekaan intuisi, kesabaran, dan kearifan dalam membaca tanda-tanda zaman maupun petunjuk Tuhan. Seseorang yang mengenakan Wirasat diharapkan mampu menjadi pelita dan penasihat bijak yang disegani keluarga serta masyarakat.',
            penggunaan: 'Dikenakan khusus oleh orang tua pengantin, sesepuh adat, dan eyang pada upacara pernikahan adat Jawa, khususnya saat prosesi siraman dan midodareni.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Komposisi ceplok kotak-kotak berselang-seling yang memuat ragam motif doa seperti truntum, cakar ayam, sido mulyo, dan lidah api.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Kompilasi Ceplok Aneka Motif Berkah',
              desc: 'Petak-petak geometris memuat cuplikan motif truntum, cakar ayam, dan sido mulyo berdampingan.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/wirasat_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Isen Sawut & Cecek Penuntun Batin',
              desc: 'Goresan canting mikro pengisi setiap bidang ceplok dengan kerapian presisi tinggi.',
              badge: 'Isen Kompleks',
              image: 'assets/images/batik/wirasat_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Klasik Berlatar Putih Gading Mori',
              desc: 'Warna tanah dan kayu soga alami yang memancarkan ketenangan serta kearifan sesepuh.',
              badge: 'Warna Khas Sesepuh',
              image: 'assets/images/batik/wirasat_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Pembagian Bidang Ceplok Berpetak', desc: 'Kain terbagi rapi dalam petak kotak atau belah ketupat yang memuat motif bertuah berbeda.'),
              PakemModel(title: '2. Perpaduan Motif Truntum & Cakar Ayam', desc: 'Wajib menyertakan motif truntum (cinta abadi) dan cakar ayam (semangat mencari rezeki halal).'),
              PakemModel(title: '3. Keseimbangan Tata Ruang Geometris', desc: 'Tiap motif dalam petak berukuran seimbang tanpa ada motif yang saling mendominasi kasar.'),
              PakemModel(title: '4. Busana Sakral Orang Tua Pengantin', desc: 'Dikenakan orang tua pada upacara siraman pengantin sebagai doa kelancaran hidup.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/wirasat_gal_1.jpg', caption: 'Kain Panjang Batik Wirasat Kasunanan'),
            GaleriModel(imageUrl: 'assets/images/batik/wirasat_gal_2.jpg', caption: 'Detail Petak Ceplok Truntum dan Cakar Ayam'),
            GaleriModel(imageUrl: 'assets/images/batik/wirasat_gal_3.jpg', caption: 'Isen Sawut Halus dalam Bidang Geometris'),
            GaleriModel(imageUrl: 'assets/images/batik/wirasat_gal_4.jpg', caption: 'Proses Canting Teliti Ragam Hias Kompilasi'),
            GaleriModel(imageUrl: 'assets/images/batik/wirasat_gal_5.jpg', caption: 'Prosesi Siraman Pengantin Tradisi Jawa'),
          ],
        ),
      ),
      ModuleModel(
        id: 11,
        motifId: 11,
        title: 'Batik Betawi',
        description: 'Keceriaan budaya pesisir Batavia berhias ikon ondel-ondel, pucuk rebung, dan warna cerah berani.',
        coverImage: 'assets/images/batik/betawi_cover.jpg',
        orderNo: 11,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'DKI Jakarta (Sentra Terogong & Seraci Bekasi)',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=rfa_O5Bv1iw',
            deskripsiUtama: 'Batik Betawi memiliki riwayat panjang yang terbagi menjadi dua era: Batik Betawi Lama (abad ke-19 era Batavia) yang dipengaruhi selera saudagar Tionghoa dan Eropa, serta Batik Betawi Baru (abad ke-21) yang dipelopori sentra Terogong di Cilandak Jakarta Selatan dan Seraci di Bekasi. Batik ini lahir dari kehangatan multikultural warga Betawi yang terbuka menyambut para pendatang.',
            asalDaerah: 'Tumbuh di perkampungan masyarakat Betawi Jakarta (khususnya Terogong, Palmerah) dan sentra perajin Seraci Bekasi.',
            maknaFilosofis: 'Mengusung falsafah keseimbangan alam semesta demi kehidupan yang tenteram, rukun, dan berkah. Motif pucuk rebung melambangkan hubungan vertikal dengan Tuhan serta harapan untuk senantiasa tumbuh bermanfaat, sedangkan ondel-ondel menjadi lambang keceriaan dan penolak bala.',
            penggunaan: 'Dikenakan dalam perayaan festival Abang None Jakarta, upacara pernikahan adat Betawi (pakaian kebaya encim dan ujung serong), busana resmi kedinasan Pemprov DKI, dan pakaian pesta harian.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Tampilan ekspresif, ramai, dan cerah mencolok dengan ornamen ondel-ondel, tanjidor, tumpal pucuk rebung, serta bunga melati gambir.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Ikonik Ondel-Ondel & Tanjidor',
              desc: 'Figur khas kesenian rakyat Betawi yang digambarkan jenaka, ramah, dan penuh semangat hidup.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/betawi_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Tumpal Pucuk Rebung & Melati Gambir',
              desc: 'Deretan segitiga tumpal geometri pada pinggir kain berpadu flora lokal melati dan telang.',
              badge: 'Ornamen Tumpal',
              image: 'assets/images/batik/betawi_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Warna Pesisir Jakarta Cerah Berani',
              desc: 'Perpaduan mencolok kuning keemasan, merah cabai, biru terang, jingga, dan hijau pupus.',
              badge: 'Warna Cerah Betawi',
              image: 'assets/images/batik/betawi_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Kehadiran Motif Pucuk Rebung', desc: 'Bagian tepi kain dihiasi tumpal segitiga pucuk rebung sebagai simbol cita-cita tinggi.'),
              PakemModel(title: '2. Figur Kesenian & Arsitektur Betawi', desc: 'Menampilkan elemen khas seperti ondel-ondel, kerak telor, tanjidor, atau Monas.'),
              PakemModel(title: '3. Pola Warna Cerah Tanpa Ragu', desc: 'Menghindari dominasi warna gelap kusam; mengutamakan kecerahan warna primer yang ceria.'),
              PakemModel(title: '4. Gaya Busana Encim Pagi-Sore', desc: 'Sering diaplikasikan pada kain panjang pagi-sore dengan dua nuansa warna berbeda.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/betawi_gal_1.jpg', caption: 'Kain Batik Betawi Motif Ondel-Ondel Ceria'),
            GaleriModel(imageUrl: 'assets/images/batik/betawi_gal_2.jpg', caption: 'Detail Ornamen Tumpal Pucuk Rebung Emas'),
            GaleriModel(imageUrl: 'assets/images/batik/betawi_gal_3.jpg', caption: 'Pewarnaan Cerah Khas Sentra Batik Terogong'),
            GaleriModel(imageUrl: 'assets/images/batik/betawi_gal_4.jpg', caption: 'Proses Cap dan Canting Kain Batik Betawi'),
            GaleriModel(imageUrl: 'assets/images/batik/betawi_gal_5.jpg', caption: 'Penampilan Busana Batik Betawi Abang None'),
          ],
        ),
      ),
      ModuleModel(
        id: 12,
        motifId: 12,
        title: 'Batik Bokor Kencono',
        description: 'Batik agung Keraton Solo era Pakubuwono IX pembawa kewibawaan dan keterbukaan bagi semua kalangan.',
        coverImage: 'assets/images/batik/bokor_kencono_cover.jpg',
        orderNo: 12,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Kasunanan Surakarta Hadiningrat',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=jtdrACMdNjg',
            deskripsiUtama: 'Batik Bokor Kencono pertama kali diciptakan di lingkungan Keraton Kasunanan Surakarta pada era kepemimpinan Sri Susuhunan Pakubuwono IX. Keistimewaan luar biasa motif ini terletak pada statusnya: sejak awal diciptakan, motif ini tidak dijadikan batik larangan tertutup, melainkan diizinkan untuk dipakai oleh segenap lapisan masyarakat, mulai dari raja hingga rakyat jelata.',
            asalDaerah: 'Lahir di Keraton Kasunanan Surakarta pada paruh kedua abad ke-19 dan dilestarikan oleh para saudagar batik Laweyan.',
            maknaFilosofis: 'Bokor bermakna wadah air bunga kuningan/emas untuk upacara suci, dan kencono bermakna emas berkilau. Mengandung filosofi kewibawaan, kebijaksanaan, dan keagungan budi pekerti agar pemakainya disegani, dihormati, serta mampu menampung keluh kesah sesama laksana wadah air suci.',
            penggunaan: 'Karena sifatnya yang terbuka untuk semua golongan, batik ini sering dipakai dalam upacara resepsi pernikahan, perjamuan resmi kenegaraan, maupun busana kehormatan masyarakat Solo.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Pola lung-lungan sulur meliuk teratur dari rumpun motif Semen yang memuat wadah bokor bertatahkan keemasan sogan.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Ragam Hias Bokor Emas Suci',
              desc: 'Bentuk bejana bokor berukir indah sebagai simbol wadah kemurnian batin dan rezeki berkah.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/bokor_kencono_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Sulur Lung-Lungan Keluarga Semen',
              desc: 'Daun dan ranting meliuk bersambung melambangkan pertumbuhan kebijaksanaan tanpa akhir.',
              badge: 'Lung-Lungan Semen',
              image: 'assets/images/batik/bokor_kencono_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Keemasan Latar Ireng / Krem',
              desc: 'Dominasi cokelat muda keemasan dipadu sogan pekat di atas dasar hitam legam (latar ireng).',
              badge: 'Sogan Keemasan',
              image: 'assets/images/batik/bokor_kencono_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Ornamen Bokor di Poros Bidang', desc: 'Wadah bokor menjadi titik pusat penyeimbang di antara jalinan sulur lung-lungan.'),
              PakemModel(title: '2. Pola Rumpun Semen Melingkar', desc: 'Mengikuti pakem motif Semen dengan sulur tetumbuhan yang tumbuh menyebar serasi.'),
              PakemModel(title: '3. Pewarnaan Bernuansa Emas Kencono', desc: 'Wajib menonjolkan nuansa cokelat oker keemasan yang melambangkan kemuliaan emas.'),
              PakemModel(title: '4. Kesetaraan Busana Tanpa Larangan', desc: 'Dapat dikenakan oleh siapa saja tanpa melanggar adat paugeran larangan keraton.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/bokor_kencono_gal_1.jpg', caption: 'Kain Batik Bokor Kencono Latar Ireng'),
            GaleriModel(imageUrl: 'assets/images/batik/bokor_kencono_gal_2.jpg', caption: 'Detail Ornamen Bejana Bokor dan Sulur Emas'),
            GaleriModel(imageUrl: 'assets/images/batik/bokor_kencono_gal_3.jpg', caption: 'Pencantingan Lilin Malam Pola Semen Solo'),
            GaleriModel(imageUrl: 'assets/images/batik/bokor_kencono_gal_4.jpg', caption: 'Pencelupan Sogan Tradisional Kayu Tingi'),
            GaleriModel(imageUrl: 'assets/images/batik/bokor_kencono_gal_5.jpg', caption: 'Pemanfaatan Busana Formal Batik Bokor Kencono'),
          ],
        ),
      ),
      ModuleModel(
        id: 13,
        motifId: 13,
        title: 'Batik Buketan',
        description: 'Mahakarya akulturasi Indo-Eropa di Pekalongan pelopor buket bunga besar karya Eliza van Zuylen.',
        coverImage: 'assets/images/batik/buketan_cover.jpg',
        orderNo: 13,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Sentra Batik Indo-Eropa Kota Pekalongan',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=Q_j5qLDAGPo',
            deskripsiUtama: 'Batik Buketan lahir dari pertemuan budaya Jawa pesisir dengan perempuan Indo-Eropa di Pekalongan pada akhir abad ke-19. Nama \'buketan\' diserap dari kata bahasa Prancis \'bouquet\' yang berarti karangan bunga. Sosok legendaris perancangnya adalah Eliza van Zuylen (1863-1947), putri serdadu Belanda yang mendirikan bengkel batik mandiri tahun 1890 dan menjadi produsen sarung buketan terbesar di tanah Jawa.',
            asalDaerah: 'Berkembang pesat di Pekalongan, Jawa Tengah, berkat kreativitas kolaboratif antara pembatik lokal dan perempuan Indo-Eropa.',
            maknaFilosofis: 'Bukan bertumpu pada mitologi sakral keraton, melainkan perayaan keindahan akulturasi budaya Jawa, Eropa, dan Peranakan. Melambangkan kesegaran jiwa, cinta kasih, keanggunan wanita, serta kegembiraan dalam memandang keindahan alam raya.',
            penggunaan: 'Awalnya dibuat untuk sarung kebaya nyonya Belanda dan keturunan Peranakan, kini menjadi busana bergengsi para pecinta batik untuk resepsi pesta pernikahan dan busana busana santai mewah.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Rangkaian karangan bunga Eropa berukuran besar (krisan, mawar, dahlia) diselingi kupu-kupu dan burung dengan isen cecek padat.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Buket Bunga Eropa Ukuran Besar',
              desc: 'Karangan bunga krisan, mawar, dan lili mekar ranum dengan proporsi visual anggun.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/buketan_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Kupu-Kupu & Burung Penghisap Madu',
              desc: 'Satwa mungil berterbangan di sekitar kelopak bunga di atas isen latar cecek padat.',
              badge: 'Fauna Pendamping',
              image: 'assets/images/batik/buketan_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Warna Pastel Sintetis Eropa & Latar Parang',
              desc: 'Warna merah muda, ungu lembayung, hijau toska, serta paduan latar klasik parang.',
              badge: 'Warna Pastel Indis',
              image: 'assets/images/batik/buketan_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Rangkaian Buket Bunga Membentang', desc: 'Rangkaian bunga tersusun vertikal dari bagian badan hingga kepala sarung secara natural.'),
              PakemModel(title: '2. Pasangan Kupu-Kupu & Burung', desc: 'Wajib menyertakan fauna terbang pengisap madu sebagai pelengkap romantisme buketan.'),
              PakemModel(title: '3. Kerapatan Isen Canting Latar', desc: 'Latar bidang diisi penuh isen cecek sawut atau dipadukan motif parang lereng halus.'),
              PakemModel(title: '4. Gradasi Kelopak Bunga Halus', desc: 'Teknik coletan warna pada kelopak bunga menghasilkan efek pencahayaan tiga dimensi.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/buketan_gal_1.jpg', caption: 'Sarung Batik Buketan Klasik Karya Eliza van Zuylen'),
            GaleriModel(imageUrl: 'assets/images/batik/buketan_gal_2.jpg', caption: 'Detail Karangan Bunga Mawar dan Kupu-Kupu'),
            GaleriModel(imageUrl: 'assets/images/batik/buketan_gal_3.jpg', caption: 'Paduan Buketan dengan Latar Motif Parang'),
            GaleriModel(imageUrl: 'assets/images/batik/buketan_gal_4.jpg', caption: 'Teknik Pewarnaan Coletan Halus Multigradasi'),
            GaleriModel(imageUrl: 'assets/images/batik/buketan_gal_5.jpg', caption: 'Koleksi Museum Seni Sarung Buketan Pekalongan'),
          ],
        ),
      ),
      ModuleModel(
        id: 14,
        motifId: 14,
        title: 'Batik Dayak (Benang Bintik)',
        description: 'Kosmologi sakral Dayak Ngaju berhias Pohon Kehidupan Batang Garing dan burung Enggang suci.',
        coverImage: 'assets/images/batik/dayak_cover.jpg',
        orderNo: 14,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Kalimantan Tengah (Suku Dayak Ngaju)',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=7QTSrCcc3iU',
            deskripsiUtama: 'Batik Dayak (terkenal dengan sebutan Batik Benang Bintik) merupakan kreasi luhur masyarakat Dayak Ngaju di Kalimantan Tengah yang mulai dikembangkan sejak tahun 1991. Dalam bahasa Dayak Ngaju, \'benang\' berarti helaian kain putih mori, sedangkan \'bintik\' bermakna goresan gambar atau titik motif. Lahir dari inisiatif pelestarian seni ukir tradisional Dayak ke dalam medium batik nusantara.',
            asalDaerah: 'Diciptakan dan diproduksi di Palangka Raya dan berbagai penjuru Provinsi Kalimantan Tengah.',
            maknaFilosofis: 'Berpusat pada kosmologi Batang Garing (Pohon Kehidupan) yang diyakini diturunkan oleh Ranying Hatalla Langit (Tuhan Yang Maha Esa), melambangkan keseimbangan dunia atas dan dunia bawah. Burung Tingang (Enggang) melambangkan kesucian, keberanian, dan perlindungan semesta.',
            penggunaan: 'Dikenakan pada upacara sakral adat Dayak (seperti Tiwah), festival kebudayaan Isen Mulang, pakaian resmi kedinasan daerah, serta busana pesta pernikahan suku Dayak.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Tarikan garis lengkung ukiran Dayak yang tegas, siluet pohon Batang Garing laksana tombak, dan burung Enggang dengan warna primer berani.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Pohon Batang Garing (Pohon Kehidupan)',
              desc: 'Siluet pohon menjulang berujung tombak tajam dengan daun permata lambang rezeki ilahi.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/dayak_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Burung Enggang (Tingang) & Ukir Tameng',
              desc: 'Paruh dan bulu ekor burung enggang berpadu sulur lekukan khas mandau dan perisai Dayak.',
              badge: 'Ornamen Sakral',
              image: 'assets/images/batik/dayak_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Warna Berani Khas Dayak (Bahenda, Bahandang)',
              desc: 'Kuning kunyit menyala, merah saga, hitam jelaga, dan hijau zamrud rimba Kalimantan.',
              badge: 'Warna Primer Dayak',
              image: 'assets/images/batik/dayak_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Siluet Pohon Batang Garing Tegak', desc: 'Bentuk pohon kehidupan menjulang ke atas sebagai poros penghubung manusia dengan Tuhan.'),
              PakemModel(title: '2. Figur Burung Enggang Keramat', desc: 'Menghadirkan burung tingang berkepala megah sebagai lambang kepemimpinan sejati.'),
              PakemModel(title: '3. Garis Ukir Sulur Tanpa Putus', desc: 'Goresan lengkung khas ukiran suku Dayak yang dinamis, tegas, dan tidak patah.'),
              PakemModel(title: '4. Pewarnaan Kontras yang Berani', desc: 'Kombinasi warna primer alam Kalimantan yang mencerminkan keteguhan dan keberanian jiwa.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/dayak_gal_1.jpg', caption: 'Bentangan Kain Batik Benang Bintik Dayak Kalteng'),
            GaleriModel(imageUrl: 'assets/images/batik/dayak_gal_2.jpg', caption: 'Detail Batang Garing dan Ukiran Burung Enggang'),
            GaleriModel(imageUrl: 'assets/images/batik/dayak_gal_3.jpg', caption: 'Goresan Canting Ragam Hias Mandau dan Tameng'),
            GaleriModel(imageUrl: 'assets/images/batik/dayak_gal_4.jpg', caption: 'Proses Pewarnaan Kuning dan Merah Khas Dayak'),
            GaleriModel(imageUrl: 'assets/images/batik/dayak_gal_5.jpg', caption: 'Pentas Busana Festival Adat Budaya Isen Mulang'),
          ],
        ),
      ),
      ModuleModel(
        id: 15,
        motifId: 15,
        title: 'Batik Jlamprang',
        description: 'Geometri kosmis nitik Pekalongan hasil akulturasi tenun Patola Gujarat dan spiritualitas Islam.',
        coverImage: 'assets/images/batik/jlamprang_cover.jpg',
        orderNo: 15,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Sentra Batik Krapyak Kota Pekalongan',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=0Isdn3f5SXE',
            deskripsiUtama: 'Batik Jlamprang merupakan salah satu dari lima motif tertua dan paling legendaris asli Pekalongan. Berkembang pesat di perkampungan Arab Krapyak sejak abad ke-18. Lahir dari akulturasi kain tenun sutra Patola asal Gujarat, India. Nilai Islam yang melarang penggambaran makhluk bernyawa mendorong para empu Pekalongan mengubah bentuk fauna menjadi ornamen geometris nitik murni yang sangat presisi.',
            asalDaerah: 'Kawasan pesisir Pekalongan, khususnya sentra Kampung Arab Krapyak dan pesisir utara Jawa Tengah.',
            maknaFilosofis: 'Pola geometris konsentris melambangkan hubungan batin mikrokosmos (diri manusia) dengan makrokosmos (keteraturan semesta ciptaan Tuhan). Simbol kesucian hati, keteraturan budi pekerti, dan kepatuhan spiritual mutlak kepada Sang Pencipta.',
            penggunaan: 'Selain digunakan sebagai busana perayaan Syawalan (Lopis Raksasa Krapyak), dahulu motif ini juga menjadi kain persembahan dalam ritual sedekah laut kepada penguasa pantai utara, Dewi Lanjar.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Ragam hias geometris murni golongan nitik berbentuk lingkaran cakra bunga delapan arah mata angin dengan warna cerah pesisir.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Cakra Geometris Delapan Penjuru',
              desc: 'Lingkaran simetris dengan poros bunga cakra yang teratur laksana mandala kosmis.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/jlamprang_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Teknik Nitik Titik-Titik Halus',
              desc: 'Torehan canting khusus menyerupai rajutan tenun patola tanpa figur makhluk bernyawa.',
              badge: 'Isen Nitik Presisi',
              image: 'assets/images/batik/jlamprang_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Pewarna Alami Nila (Indigo) & Merah Manggis',
              desc: 'Warna biru nila alami berpadu merah mengkudu, hijau tua, dan oker cokelat tanah.',
              badge: 'Pewarna Indigo & Sogan',
              image: 'assets/images/batik/jlamprang_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Bentuk Geometris Murni (Nitik)', desc: 'Seluruh motif tersusun dari titik dan garis geometris teratur tanpa ada gambar makhluk hidup.'),
              PakemModel(title: '2. Simetri Delapan Arah Mata Angin', desc: 'Setiap roset bunga memiliki delapan atau empat kelopak simetris sempurna.'),
              PakemModel(title: '3. Kerapian Titik Canting Khas Tenun', desc: 'Torehan canting malam meniru tekstur tenunan patola dengan kerapatan sangat tinggi.'),
              PakemModel(title: '4. Tradisi Syawalan & Sedekah Laut', desc: 'Digunakan dalam tradisi tahunan masyarakat pesisir Pekalongan sebagai berkah rezeki laut.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/jlamprang_gal_1.jpg', caption: 'Kain Batik Jlamprang Cakra Geometris Krapyak'),
            GaleriModel(imageUrl: 'assets/images/batik/jlamprang_gal_2.jpg', caption: 'Detail Canting Nitik Bunga Delapan Kelopak'),
            GaleriModel(imageUrl: 'assets/images/batik/jlamprang_gal_3.jpg', caption: 'Pewarnaan Biru Indigo Alami Tradisional'),
            GaleriModel(imageUrl: 'assets/images/batik/jlamprang_gal_4.jpg', caption: 'Proses Pembuatan Canting Malam Geometris Presisi'),
            GaleriModel(imageUrl: 'assets/images/batik/jlamprang_gal_5.jpg', caption: 'Tradisi Pesta Syawalan Krapyak Kota Pekalongan'),
          ],
        ),
      ),
      ModuleModel(
        id: 16,
        motifId: 16,
        title: 'Batik Kawung',
        description: 'Salah satu motif tertua di Jawa lambang kiblat papat limo pancer, kesucian hati, dan keadilan pemimpin.',
        coverImage: 'assets/images/batik/kawung_cover.jpg',
        orderNo: 16,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Kesultanan Ngayogyakarta Hadiningrat',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=wMo4s5Ja4e4',
            deskripsiUtama: 'Kawung tercatat sebagai salah satu motif batik tertua di tanah Jawa yang telah ada sejak era kerajaan Kediri dan Majapahit, kemudian dikembangkan secara mendalam oleh Sultan Agung dari Mataram Islam. Bentuknya menyerupai belahan buah kawung (buah aren/kolang-kaling) atau kuncup bunga teratai yang sedang merekah. Dahulu merupakan batik larangan yang hanya boleh dipakai oleh kaum bangsawan keraton.',
            asalDaerah: 'Lahir di tanah Mataram dan menjadi pakem utama di Keraton Kasultanan Yogyakarta dan Keraton Surakarta.',
            maknaFilosofis: 'Mengusung falsafah \'Kiblat Papat Limo Pancer\' (empat arah mata angin berpusat pada satu hati nurani). Mengajarkan manusia untuk memiliki kemurnian hati nurani laksana putihnya kolang-kaling, mampu mengendalikan hawa nafsu duniawi, dan bermanfaat bagi orang banyak laksana seluruh bagian pohon aren.',
            penggunaan: 'Termasuk batik larangan (awisan dalem) yang dahulu hanya boleh dikenakan raja dan pembesar keraton. Saat ini dipakai luas dalam acara resmi kenegaraan dan upacara adat.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Empat bidang elips lonjong simetris yang bertemu pada satu titik poros tengah, dihiasi isen cecek mikro berlatar sogan klasik.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Simetri Empat Elips (Kiblat Papat)',
              desc: 'Empat kelopak lonjong bersudut 90 derajat presisi membentuk lingkaran bunga teratur.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/kawung_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Titik Poros Tengah (Pancer)',
              desc: 'Pusat pertemuan silang empat kelopak diisi titik cecek mikro lambang keteguhan batin.',
              badge: 'Titik Pancer',
              image: 'assets/images/batik/kawung_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Klasik & Putih Mori Prima',
              desc: 'Perpaduan cokelat soga tua matang dengan putih gading kain mori yang bersih berwibawa.',
              badge: 'Warna Klasik Sogan',
              image: 'assets/images/batik/kawung_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Proporsi Elips Presisi Sudut Siku', desc: 'Keempat bidang kelopak elips berukuran identik dan membentuk sudut perpotongan tepat 90 derajat.'),
              PakemModel(title: '2. Kehadiran Poros Isen Pancer', desc: 'Titik temu tengah wajib memiliki isen titik cecek sebagai lambang kendali nurani batin.'),
              PakemModel(title: '3. Garis Kontur Canting Melingkar Halus', desc: 'Tarikan garis malam mulus tanpa patahan kasar untuk menjaga harmoni kebulatan tekad.'),
              PakemModel(title: '4. Falsafah Manunggaling Kawula Gusti', desc: 'Melambangkan persatuan budi pekerti antara pemimpin adil dan rakyat yang sejahtera.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/kawung_gal_1.jpg', caption: 'Kain Panjang Batik Kawung Mataram Klasik'),
            GaleriModel(imageUrl: 'assets/images/batik/kawung_gal_2.jpg', caption: 'Detail Empat Elips Kolang-Kaling Presisi'),
            GaleriModel(imageUrl: 'assets/images/batik/kawung_gal_3.jpg', caption: 'Pencantingan Malam Putih Mori Latar Sogan'),
            GaleriModel(imageUrl: 'assets/images/batik/kawung_gal_4.jpg', caption: 'Pencelupan Pewarna Kulit Kayu Soga Alami'),
            GaleriModel(imageUrl: 'assets/images/batik/kawung_gal_5.jpg', caption: 'Penerapan Batik Kawung pada Busana Ksatria Jawa'),
          ],
        ),
      ),
      ModuleModel(
        id: 17,
        motifId: 17,
        title: 'Batik Liong',
        description: 'Akulturasi agung pesisir Jawa-Tionghoa berhias naga pelindung alam dan burung Phoenix keabadian.',
        coverImage: 'assets/images/batik/liong_cover.jpg',
        orderNo: 17,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Pesisir Lasem, Indramayu, & Pekalongan',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: '',
            deskripsiUtama: 'Batik Liong (berarti naga) adalah mahakarya seni batik pesisir hasil akulturasi berabad-abad antara masyarakat Nusantara dengan etnis Tionghoa, khususnya di Lasem (Kota Tiongkok Kecil), Indramayu, dan Pekalongan sejak tahun 1740. Naga memiliki kedudukan tertinggi dalam mitologi Tionghoa sebagai penjaga khayangan, penguasa angin dan hujan, serta pembawa berkah kelimpahan hidup.',
            asalDaerah: 'Sentra batik pesisiran Lasem (Rembang), Paoman (Indramayu), dan pesisir Pekalongan.',
            maknaFilosofis: 'Liong melambangkan kekuatan, kekuasaan yang adil, serta perlindungan spiritual dari mara bahaya. Ketika dipadukan dengan burung Phoenix (Hong), motif ini melambangkan keseimbangan energi Yin dan Yang: keharmonisan rumah tangga, kelanggengan cinta suami-istri, dan kemakmuran keluarga turun-temurun.',
            penggunaan: 'Digunakan pada upacara pernikahan adat Peranakan Tionghoa (ciotau), perayaan Tahun Baru Imlek, kain penutup meja altar sembahyang (tokwi), serta busana pesta kebaya encim.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Geliat tubuh naga bersisik meliuk perkasa di antara awan kilin dan bunga seruni, dipadukan warna merah getih pitik khas Lasem.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Figur Naga (Liong) Berkepala Gagah',
              desc: 'Tubuh naga bersisik tajam meliuk dinamis dengan cakar kuat pemegang mustika berkah.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/liong_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Burung Phoenix (Hong) & Awan Peranakan',
              desc: 'Pasangan burung phoenix berbulu ekor panjang berpadu awan kilin dan bunga seruni.',
              badge: 'Yin & Yang',
              image: 'assets/images/batik/liong_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Merah Getih Pitik Khas Lasem & Biru Laut',
              desc: 'Merah darah ayam (getih pitik) legendaris dari akar mengkudu berpadu biru nila dan hijau toska.',
              badge: 'Merah Getih Pitik',
              image: 'assets/images/batik/liong_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Liukan Dinamis Tubuh Naga Bersisik', desc: 'Naga digambarkan meliuk anggun dengan sisik teratur dan cakar perkasa membentang.'),
              PakemModel(title: '2. Pasangan Harmonis Liong dan Hong', desc: 'Sering memuat pasangan naga (maskulin/kekuatan) dan burung phoenix (feminin/keindahan).'),
              PakemModel(title: '3. Pewarnaan Khas Laseman (Tiga Negeri)', desc: 'Menampilkan warna merah khas Lasem yang tidak luntur dipadu biru Pekalongan dan sogan Solo.'),
              PakemModel(title: '4. Busana Perayaan Tradisi Peranakan', desc: 'Dipakai dalam perayaan Imlek dan upacara pernikahan sebagai doa kelimpahan rezeki.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/liong_gal_1.jpg', caption: 'Kain Batik Tulis Liong Lasem Warna Tiga Negeri'),
            GaleriModel(imageUrl: 'assets/images/batik/liong_gal_2.jpg', caption: 'Detail Kepala Naga Bersisik dan Cakar Emas'),
            GaleriModel(imageUrl: 'assets/images/batik/liong_gal_3.jpg', caption: 'Pasangan Burung Phoenix Hong Penuh Keanggunan'),
            GaleriModel(imageUrl: 'assets/images/batik/liong_gal_4.jpg', caption: 'Pewarnaan Merah Alami Getih Pitik Lasem'),
            GaleriModel(imageUrl: 'assets/images/batik/liong_gal_5.jpg', caption: 'Perayaan Tradisi Imlek dengan Busana Batik Liong'),
          ],
        ),
      ),
      ModuleModel(
        id: 18,
        motifId: 18,
        title: 'Batik Mega Mendung',
        description: 'Gradasi tujuh lapis awan sejuk pesisir Cirebon lambang kesabaran dan pengendalian amarah.',
        coverImage: 'assets/images/batik/mega_mendung_cover.jpg',
        orderNo: 18,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Kasepuhan Cirebon & Sentra Trusmi',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=aetXWgzqI88',
            deskripsiUtama: 'Mega Mendung merupakan mahakarya tak lekang oleh waktu asal Cirebon yang lahir dari pernikahan diplomatik dan spiritual antara Sunan Gunung Jati dengan Putri Ong Tien Nio dari Tiongkok pada abad ke-16. Gumpalan awan khas lukisan keramik Tionghoa diolah kembali oleh seniman batik Trusmi menjadi bentuk awan bersudut lancip horizontal yang khas dan tiada duanya di dunia.',
            asalDaerah: 'Lahir di Keraton Cirebon dan sentra kerajinan batik Trusmi, Plered, Kabupaten Cirebon, Jawa Barat.',
            maknaFilosofis: '\'Mega\' berarti awan luas, dan \'Mendung\' bermakna suasana sejuk pembawa hujan penyubur bumi. Mengajarkan manusia untuk berhati teduh, senantiasa bersabar, tidak lekas naik pitam saat dirundung masalah, serta mampu membawa kedamaian bagi orang-orang di sekitarnya.',
            penggunaan: 'Dahulu dipakai oleh kalangan keraton Cirebon sebagai kain panjang kehormatan. Kini menjadi ikon budaya Cirebon yang mendunia, digunakan dalam busana formal kenegaraan hingga pakaian santai elegan.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Garis awan berliuk horizontal meruncing membentuk pola segitiga lancip dengan teknik gradasi kuasan hingga 5-7 tingkatan warna.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Gumpalan Awan Runcing Horizontal',
              desc: 'Bentuk awan memanjang mendatar dengan ujung bersudut lancip khas pesisir Cirebon.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/mega_mendung_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Gradasi Warna Kuasan Halus (Ganggeng)',
              desc: 'Teknik sapuan canting gradasi bertingkat menciptakan ilusi dimensi langit berarak.',
              badge: 'Gradasi 7 Lapis',
              image: 'assets/images/batik/mega_mendung_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Gradasi Biru Langit-Malam & Merah Cabai',
              desc: 'Dari biru muda keputihan menuju biru dongker tua pekat, atau gradasi merah berani.',
              badge: 'Warna Khas Cirebon',
              image: 'assets/images/batik/mega_mendung_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Ujung Awan Meruncing Segitiga', desc: 'Berbeda dari awan Tiongkok yang membulat, awan Mega Mendung memiliki ujung lancip bersudut.'),
              PakemModel(title: '2. Orientasi Bentangan Horizontal', desc: 'Bentuk awan membentang sejajar horizontal melambangkan ketenangan hidup yang seimbang.'),
              PakemModel(title: '3. Minimal Tiga Tingkatan Gradasi Warna', desc: 'Pakem agung memiliki 5 hingga 7 lapis gradasi warna dari terang menuju gelap secara bertahap.'),
              PakemModel(title: '4. Garis Batas Kontur Tegas', desc: 'Garis pembatas tiap tingkatan warna ditarik rapi tanpa lelehan malam yang berantakan.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/mega_mendung_gal_1.jpg', caption: 'Kain Batik Mega Mendung Biru Klasik Cirebon'),
            GaleriModel(imageUrl: 'assets/images/batik/mega_mendung_gal_2.jpg', caption: 'Detail Gradasi Tujuh Lapis Awan Lancip'),
            GaleriModel(imageUrl: 'assets/images/batik/mega_mendung_gal_3.jpg', caption: 'Teknik Kuasan Lilin Malam Gradasi Halus'),
            GaleriModel(imageUrl: 'assets/images/batik/mega_mendung_gal_4.jpg', caption: 'Pewarnaan Biru Nila Tradisional Trusmi'),
            GaleriModel(imageUrl: 'assets/images/batik/mega_mendung_gal_5.jpg', caption: 'Aplikasi Mega Mendung pada Busana Resmi Nasional'),
          ],
        ),
      ),
      ModuleModel(
        id: 19,
        motifId: 19,
        title: 'Batik Parang (Parang Rusak)',
        description: 'Batik larangan utama Mataram ciptaan Panembahan Senopati lambang semangat pantang menyerah.',
        coverImage: 'assets/images/batik/parang_cover.jpg',
        orderNo: 19,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Kasultanan Yogyakarta & Surakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=Xh_k47rSFEk',
            deskripsiUtama: 'Batik Parang (terutama Parang Rusak Barong) adalah motif batik tertua dan paling sakral di bumi Mataram. Diciptakan oleh Danang Sutawijaya (Panembahan Senopati), pendiri Kesultanan Mataram Islam, saat melakukan tirakat mengheningkan cipta di tebing terjal pantai Parangtritis. Riak ombak laut selatan yang tiada henti menghantam tebing karang mengilhami terciptanya garis diagonal sakral lereng ombak ini.',
            asalDaerah: 'Lahir di pesisir selatan Yogyakarta dan menjadi motif paling sakral di Keraton Yogyakarta dan Surakarta.',
            maknaFilosofis: 'Deburan ombak Samudra Hindia yang pantang surut melambangkan semangat ksatria yang gigih, pantang menyerah mengarungi badai cobaan hidup, serta kesinambungan laku prihatin untuk menegakkan budi pekerti luhur dan menjaga martabat kehormatan bangsa.',
            penggunaan: 'Merupakan batik larangan utama (awisan dalem) nomor satu di keraton Jawa. Dahulu hanya Sri Sultan, Sunan, dan putra mahkota yang berhak mengenakan Parang Barong pada upacara pisowanan agung.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Garis lereng sejajar membentang diagonal miring 45 derajat berkesinambungan menyerupai huruf \'S\' bertautan diselingi mlinjon belah ketupat.',
            strukturUtama: KarakteristikDetailModel(
              title: 'Kemiringan Lereng Diagonal 45°',
              desc: 'Deretan gelombang huruf S miring 45 derajat tanpa terputus lambang kesinambungan tekad.',
              badge: 'Struktur Utama • 45°',
              image: 'assets/images/batik/parang_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Ornamen Mlinjon & Isen Lidah Api',
              desc: 'Belah ketupat mlinjon mikro dan aksen lidah api penyeimbang dinamika ritme lereng.',
              badge: 'Mlinjon & Lidah Api',
              image: 'assets/images/batik/parang_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Tiga Warna Sakral Sogan Keraton',
              desc: 'Cokelat soga tua (jambal), kuning oker keemasan (kayu tegeran), dan dasar putih mori prima.',
              badge: 'Pewarna Alami Sogan',
              image: 'assets/images/batik/parang_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Sudut Kemiringan Tepat 45 Derajat', desc: 'Garis lereng membentang diagonal 45 derajat melambangkan kecepatan gerak dan kewibawaan.'),
              PakemModel(title: '2. Bentuk Huruf S Saling Bertautan', desc: 'Lekukan parang menyerupai deburan ombak bersambung tanpa putus sepanjang bidang kain.'),
              PakemModel(title: '3. Isen Belah Ketupat Mlinjon', desc: 'Ruang di antara parang wajib diselingi belah ketupat mlinjon dan cecek lidah api.'),
              PakemModel(title: '4. Aturan Dimensi Awisan Dalem', desc: 'Ukuran lidah parang menandakan hirarki bangsawan; Parang Barong (ukuran >10 cm) untuk Raja.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/parang_gal_1.jpg', caption: 'Kain Panjang Parang Rusak Barong Sakral Keraton'),
            GaleriModel(imageUrl: 'assets/images/batik/parang_gal_2.jpg', caption: 'Detail Kemiringan Diagonal 45 Derajat dan Mlinjon'),
            GaleriModel(imageUrl: 'assets/images/batik/parang_gal_3.jpg', caption: 'Pencantingan Malam Lilin Halus Lereng Ombak'),
            GaleriModel(imageUrl: 'assets/images/batik/parang_gal_4.jpg', caption: 'Pewarnaan Sogan Alami Keraton Ngayogyakarta'),
            GaleriModel(imageUrl: 'assets/images/batik/parang_gal_5.jpg', caption: 'Busana Kebesaran Sri Sultan pada Pisowanan Agung'),
          ],
        ),
      ),
      ModuleModel(
        id: 20,
        motifId: 20,
        title: 'Batik Sekar Jagad',
        description: 'Miniatur keindahan keragaman dunia dalam hamparan pulau-pulau bunga nusantara yang harmonis.',
        coverImage: 'assets/images/batik/sekarjagad_cover.jpg',
        orderNo: 20,
        progressPercent: 0,
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        content: ModuleContentModel(
          origin: 'Keraton Kasunanan Surakarta & Yogyakarta',
          // estimatedTime: otomatis dihitung dinamis dari total kata materi
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: 'https://www.youtube.com/watch?v=EBfSz2tlmqQ',
            deskripsiUtama: 'Batik Sekar Jagad merupakan salah satu motif tradisional klasik paling mempesona yang lahir dari lingkungan Keraton Kasunanan Surakarta, Kesultanan Yogyakarta, dan Pura Mangkunegaran. Berasal dari kata bahasa Jawa \'sekar\' yang berarti bunga dan \'jagad\' yang berarti dunia atau alam semesta. Motif ini menggambarkan hamparan kepulauan dunia yang bertabur pesona keragaman keindahan bunga.',
            asalDaerah: 'Berkembang di wilayah Solo, Yogyakarta, dan Kebumen, menyebar luas ke seluruh penjuru Nusantara.',
            maknaFilosofis: 'Sekar Jagad menyiratkan pesan keelokan budi pekerti, kegembiraan hati, dan kedamaian dalam kebhinekaan. Mengajarkan bahwa perbedaan suku, budaya, dan corak hidup bukanlah jurang pemisah, melainkan untaian keindahan miniatur dunia yang saling melengkapi dalam harmoni.',
            penggunaan: 'Berbeda dari motif parang yang terikat larangan ketat, Sekar Jagad sangat disukai untuk busana perayaan keluarga, upacara lamaran pernikahan, busana formal kenegaraan, serta perhelatan budaya nusantara.',
          ),
          karakteristik: KarakteristikModel(
            deskripsi: 'Pembagian bidang pulau-pulau kecil berdampingan dibatasi garis liku, di mana tiap pulau memuat motif berbeda (kawung, parang, gringsing, truntum).',
            strukturUtama: KarakteristikDetailModel(
              title: 'Gugusan Pulau-Pulau Berdampingan',
              desc: 'Bidang-bidang asimetris menyerupai kepulauan yang dirangkai harmonis dalam satu kain.',
              badge: 'Struktur Utama',
              image: 'assets/images/batik/sekarjagad_gal_1.jpg',
            ),
            ornamen: KarakteristikDetailModel(
              title: 'Kompilasi Ragam Isen Motif Klasik',
              desc: 'Tiap pulau memuat motif berbeda seperti ceplok kawung, parang kecil, truntum, dan gringsing.',
              badge: 'Mosaik Motif Jawa',
              image: 'assets/images/batik/sekarjagad_gal_2.jpg',
            ),
            warna: KarakteristikDetailModel(
              title: 'Sogan Hangat Berpadu Warna Pesisir',
              desc: 'Warna cokelat soga tanah keraton dipadukan dengan aksen cerah lembut khas nusantara.',
              badge: 'Warna Harmonis Dunia',
              image: 'assets/images/batik/sekarjagad_gal_3.jpg',
            ),
            pakemList: [
              PakemModel(title: '1. Pembagian Bidang Gugusan Pulau', desc: 'Kain terbagi menjadi kantong-kantong bidang pulau yang dibatasi garis lekuk alami.'),
              PakemModel(title: '2. Keberagaman Motif Tiap Bidang', desc: 'Setiap bidang pulau wajib memuat ornamen batik berbeda (gringsing, kawung, parang, nitik).'),
              PakemModel(title: '3. Keseimbangan Komposisi Keseluruhan', desc: 'Perbedaan motif antar pulau tersusun padu tanpa menimbulkan kesan berantakan.'),
              PakemModel(title: '4. Busana Keanggunan Resepsi & Pesta', desc: 'Sangat populer dikenakan dalam upacara lamaran dan resepsi pesta pernikahan adat.'),
            ],
          ),
          galeri: [
            GaleriModel(imageUrl: 'assets/images/batik/sekarjagad_gal_1.jpg', caption: 'Kain Panjang Batik Sekar Jagad Mosaik Nusantara'),
            GaleriModel(imageUrl: 'assets/images/batik/sekarjagad_gal_2.jpg', caption: 'Detail Pulau-Pulau dengan Motif Kawung dan Parang'),
            GaleriModel(imageUrl: 'assets/images/batik/sekarjagad_gal_3.jpg', caption: 'Pencantingan Malam Garis Pembatas Pulau'),
            GaleriModel(imageUrl: 'assets/images/batik/sekarjagad_gal_4.jpg', caption: 'Pewarnaan Sogan Hangat Tradisional Keraton'),
            GaleriModel(imageUrl: 'assets/images/batik/sekarjagad_gal_5.jpg', caption: 'Busana Anggun Sekar Jagad dalam Resepsi Adat'),
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

      // Muat foto profil tersimpan (hanya jika filenya masih ada)
      final savedPhoto = prefs.getString(_photoPrefKey);
      if (!kIsWeb && savedPhoto != null && File(savedPhoto).existsSync()) {
        _savedPhotoPath = savedPhoto;
      }

      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (isLoggedIn) {
        final savedEmail = prefs.getString('logged_user_email');
        if (savedEmail != null) {
          final dbUser = await DatabaseHelper.instance.getUserByEmail(savedEmail);
          if (dbUser != null) {
            _currentUser = UserModel.fromMap(dbUser);
          } else {
            final name = savedEmail.startsWith('kenalibatikmu')
                ? 'Kenali Batikmu'
                : (savedEmail.startsWith('sekar') ? 'Sekar Ayu Kinanti' : 'Sahabat Batik');
            _currentUser = UserModel(
              id: 1,
              name: name,
              email: savedEmail,
              phone: '081234567890',
              profileImagePath: _savedPhotoPath,
              createdAt: '2026-03-01T08:00:00Z',
            );
          }
          // Muat progres modul khusus milik user yang tersimpan
          await _loadUserModuleProgress(savedEmail);
        }
      } else {
        _currentUser = null;
        _resetModuleProgressInMemory();
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

    // Login Sukses
    _currentUser = UserModel(
      id: dbUser != null ? (dbUser['id'] as int? ?? 1) : 1,
      name: userName,
      email: cleanEmail,
      profileImagePath: _savedPhotoPath,
      createdAt: DateTime.now().toIso8601String(),
    );

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
      profileImagePath: _savedPhotoPath,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Akun baru: pastikan progres modul di memori bersih (0%)
    _resetModuleProgressInMemory();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('logged_user_email', cleanEmail);
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

      // Simpan progres ke SharedPreferences (cache cepat) & SQLite (relational)
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

        final userId = _currentUser?.id;
        if (userId != null) {
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

        final userId = _currentUser?.id;
        if (userId != null) {
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
        }
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
        final userKey = _currentUser?.email.trim().toLowerCase() ?? 'guest';
        final userKeyPrefix = 'user_${userKey}_module_$moduleId';
        await prefs.setInt('${userKeyPrefix}_progress', percent);
        await prefs.setBool('${userKeyPrefix}_practice', passed);
        await prefs.setInt('${userKeyPrefix}_practiceScore', (fitScore * 100).toInt());

        final userId = _currentUser?.id;
        if (userId != null) {
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
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phone: phone,
      );
      notifyListeners();
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
      return true;
    } catch (e) {
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
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPrefKey);
    notifyListeners();
  }
}