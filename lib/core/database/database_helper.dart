import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../utils/password_hasher.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('kenali_batikmu.db').timeout(const Duration(seconds: 1));
      return _database;
    } catch (e) {
      debugPrint('DatabaseHelper notice: $e (Using in-memory prototype store)');
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureSeedData(db);
      },
      onOpen: (db) async {
        await _ensureSeedData(db);
      },
    );
  }

  Future<void> _ensureSeedData(Database db) async {
    try {
      final users = await db.query('users', where: 'LOWER(email) = ?', whereArgs: ['sekar@batikmu.id']);
      if (users.isEmpty) {
        final now = DateTime.now().toIso8601String();
        await db.insert('users', {
          'name': 'Sekar Ayu Kinanti',
          'email': 'sekar@batikmu.id',
          'password_hash': PasswordHasher.hashPassword('Batikmu123#'),
          'created_at': now,
          'updated_at': now,
        });
      }
    } catch (_) {}
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        failed_attempts INTEGER DEFAULT 0,
        lockout_until TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. batik_motifs
    await db.execute('''
      CREATE TABLE batik_motifs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        origin_region TEXT NOT NULL,
        short_description TEXT NOT NULL,
        thumbnail_url TEXT,
        ml_class_index INTEGER NOT NULL
      )
    ''');

    // 3. modules
    await db.execute('''
      CREATE TABLE modules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motif_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        cover_image TEXT,
        passing_score INTEGER DEFAULT 70,
        order_no INTEGER NOT NULL,
        FOREIGN KEY (motif_id) REFERENCES batik_motifs (id)
      )
    ''');

    // 4. module_contents
    await db.execute('''
      CREATE TABLE module_contents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER NOT NULL,
        pillar TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        order_no INTEGER NOT NULL,
        FOREIGN KEY (module_id) REFERENCES modules (id)
      )
    ''');

    // 5. module_gallery_images
    await db.execute('''
      CREATE TABLE module_gallery_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        caption TEXT,
        order_no INTEGER NOT NULL,
        FOREIGN KEY (module_id) REFERENCES modules (id)
      )
    ''');

    // 6. quiz_questions
    await db.execute('''
      CREATE TABLE quiz_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER NOT NULL,
        question TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        correct_option TEXT NOT NULL,
        explanation TEXT,
        FOREIGN KEY (module_id) REFERENCES modules (id)
      )
    ''');

    // 7. user_module_progress
    await db.execute('''
      CREATE TABLE user_module_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        module_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        progress_percent INTEGER NOT NULL DEFAULT 0,
        history_done INTEGER NOT NULL DEFAULT 0,
        character_done INTEGER NOT NULL DEFAULT 0,
        gallery_done INTEGER NOT NULL DEFAULT 0,
        quiz_done INTEGER NOT NULL DEFAULT 0,
        practice_done INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        last_accessed_at TEXT NOT NULL,
        UNIQUE(user_id, module_id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (module_id) REFERENCES modules (id)
      )
    ''');

    // 8. quiz_attempts
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        module_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        passed INTEGER NOT NULL,
        attempted_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (module_id) REFERENCES modules (id)
      )
    ''');

    // 9. quiz_attempt_answers
    await db.execute('''
      CREATE TABLE quiz_attempt_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        selected_option TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        FOREIGN KEY (attempt_id) REFERENCES quiz_attempts (id),
        FOREIGN KEY (question_id) REFERENCES quiz_questions (id)
      )
    ''');

    // 10. scans
    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        scan_type TEXT NOT NULL,
        module_id INTEGER,
        image_path TEXT,
        top_motif_id INTEGER,
        confidence REAL,
        fit_score REAL,
        passed INTEGER,
        inference_time_ms INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (module_id) REFERENCES modules (id),
        FOREIGN KEY (top_motif_id) REFERENCES batik_motifs (id)
      )
    ''');

    // 11. scan_probabilities
    await db.execute('''
      CREATE TABLE scan_probabilities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scan_id INTEGER NOT NULL,
        motif_id INTEGER NOT NULL,
        probability REAL NOT NULL,
        FOREIGN KEY (scan_id) REFERENCES scans (id),
        FOREIGN KEY (motif_id) REFERENCES batik_motifs (id)
      )
    ''');

    // Seed Data Awal Sesuai PRD
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // 1. Akun Default Pengguna (Sekar Ayu Kinanti)
    await db.insert('users', {
      'name': 'Sekar Ayu Kinanti',
      'email': 'sekar@batikmu.id',
      'password_hash': PasswordHasher.hashPassword('Batikmu123#'),
      'created_at': now,
      'updated_at': now,
    });

    // 2. Motif Batik Nusantara (5 Kelas Sesuai PRD)
    final motifs = [
      {
        'id': 1,
        'name': 'Parang Kusumo',
        'slug': 'parang-kusumo',
        'origin_region': 'Surakarta & Yogyakarta',
        'short_description': 'Motif klasik lereng ombak laut selatan yang melambangkan keteguhan dan perjuangan tak pernah padam.',
        'thumbnail_url': 'assets/images/parang.png',
        'ml_class_index': 0,
      },
      {
        'id': 2,
        'name': 'Kawung',
        'slug': 'kawung',
        'origin_region': 'Yogyakarta & Jawa Tengah',
        'short_description': 'Pola empat bulatan kolang-kaling melambangkan kesucian hati, keadilan, dan pengendalian diri.',
        'thumbnail_url': 'assets/images/kawung.png',
        'ml_class_index': 1,
      },
      {
        'id': 3,
        'name': 'Megamendung',
        'slug': 'megamendung',
        'origin_region': 'Cirebon, Jawa Barat',
        'short_description': 'Pola awan bergradasi khas pesisiran yang mencerminkan keteduhan, kesabaran, dan akulturasi Tionghoa-Nusantara.',
        'thumbnail_url': 'assets/images/megamendung.png',
        'ml_class_index': 2,
      },
      {
        'id': 4,
        'name': 'Sekar Jagad',
        'slug': 'sekar-jagad',
        'origin_region': 'Solo & Yogyakarta',
        'short_description': 'Kumpulan ragam pulau bunga yang menggambarkan keindahan keragaman nusantara dalam satu kesatuan.',
        'thumbnail_url': 'assets/images/sekar_jagad.png',
        'ml_class_index': 3,
      },
      {
        'id': 5,
        'name': 'Truntum',
        'slug': 'truntum',
        'origin_region': 'Surakarta',
        'short_description': 'Bunga-bunga bintang malam yang melambangkan cinta kasih yang tulus dan bersemi kembali tanpa pamrih.',
        'thumbnail_url': 'assets/images/truntum.png',
        'ml_class_index': 4,
      },
    ];

    for (var m in motifs) {
      await db.insert('batik_motifs', m);
    }

    // 3. Modul Belajar
    for (var m in motifs) {
      await db.insert('modules', {
        'id': m['id'],
        'motif_id': m['id'],
        'title': 'Modul ${m['id']}: Seni & Filosofi ${m['name']}',
        'description': 'Pelajari sejarah keraton, karakteristik garis canting 45 derajat, dan latihan praktik pola ${m['name']}.',
        'cover_image': m['thumbnail_url'],
        'passing_score': 70,
        'order_no': m['id'],
      });
    }

    // 4. Isi Tiga Pilar Materi untuk Modul 1 (Parang Kusumo)
    await db.insert('module_contents', {
      'module_id': 1,
      'pillar': 'sejarah_filosofi',
      'title': 'Sejarah & Filosofi Parang Kusumo',
      'body': 'Motif Parang diciptakan oleh Sultan Agung Hanyakrakusuma saat mengheningkan cipta di pesisir pantai selatan Yogyakarta. Gerakan ombak yang terus menghantam karang tanpa putus memberi inspirasi filosofis mendalam: kesatria Mataram harus memiliki tekad membaja, pantang menyerah, dan berakhlak mulia laksana harum bunga (kusuma).',
      'order_no': 1,
    });

    await db.insert('module_contents', {
      'module_id': 1,
      'pillar': 'karakteristik',
      'title': 'Karakteristik Motif & Sudut 45°',
      'body': 'Parang Kusumo tersusun dari ragam ornamen utama mlinjon dan canting cecek berdiagonal miring 45 derajat. Bentuk huruf S berkesinambungan mencerminkan gelombang laut tiada akhir. Tetesan canting lilin malam harus konsisten dengan tekanan stabil pada mori prima.',
      'order_no': 2,
    });

    await db.insert('module_contents', {
      'module_id': 1,
      'pillar': 'galeri',
      'title': 'Galeri Visual & Dokumentasi Keraton',
      'body': 'Koleksi kain batik Parang Kusumo soga klasik buatan abdi dalem pengrajin Surakarta abad ke-19.',
      'order_no': 3,
    });

    // 5. Bank Soal Kuis Teori (10 Soal untuk Modul 1 Parang Kusumo)
    final questions = [
      {
        'q': 'Motif Batik Parang Kusumo secara filosofis melambangkan apa dalam kehidupan?',
        'a': 'Semangat perjuangan dan keteguhan hati yang pantang padam',
        'b': 'Ketenangan danau keraton yang syahdu',
        'c': 'Kekayaan hasil laut para nelayan',
        'd': 'Keberanian berlayar mengarungi samudera luas',
        'cor': 'A',
        'exp': 'Parang Kusumo melambangkan keteguhan hati laksana karang dan harum budi pekerti.'
      },
      {
        'q': 'Siapakah tokoh kerajaan yang diyakini menciptakan motif Parang pertama kali?',
        'a': 'Sultan Hamengkubuwono I',
        'b': 'Sultan Agung Hanyakrakusuma',
        'c': 'Raden Wijaya',
        'd': 'Pangeran Diponegoro',
        'cor': 'B',
        'exp': 'Sultan Agung terinspirasi saat bersemedi di tebing karang pantai selatan.'
      },
      {
        'q': 'Berapa derajat sudut kemiringan diagonal pakem lereng pada motif Parang?',
        'a': '30 derajat',
        'b': '45 derajat',
        'c': '60 derajat',
        'd': '90 derajat',
        'cor': 'B',
        'exp': 'Sudut diagonal pakem lereng Parang adalah 45 derajat.'
      },
      {
        'q': 'Apa makna dari kata Kusumo dalam bahasa Jawa kawi?',
        'a': 'Ombak yang kuat',
        'b': 'Bunga yang harum semerbak',
        'c': 'Batu karang kokoh',
        'd': 'Pohon beringin besar',
        'cor': 'B',
        'exp': 'Kusumo bermakna bunga, melambangkan generasi bangsawan yang berbudi harum.'
      },
      {
        'q': 'Batik Parang termasuk ke dalam kategori motif batik apa di lingkungan keraton?',
        'a': 'Batik Pesisiran',
        'b': 'Batik Larangan (Awisan Dalem)',
        'c': 'Batik Modern Kontemporer',
        'd': 'Batik Saudagaran',
        'cor': 'B',
        'exp': 'Parang dahulu merupakan batik larangan yang hanya boleh dipakai raja dan kerabat keraton.'
      },
      {
        'q': 'Bentuk ornamen dasar berulang pada batik Parang menyerupai huruf...',
        'a': 'Huruf V',
        'b': 'Huruf S miring berkesinambungan',
        'c': 'Huruf O melingkar',
        'd': 'Huruf X menyilang',
        'cor': 'B',
        'exp': 'Bentuk ombak menyerupai huruf S beruntai yang tak pernah putus.'
      },
      {
        'q': 'Kain mori jenis apa yang biasa digunakan untuk membatik halus?',
        'a': 'Mori Prima atau Primissima',
        'b': 'Kain Blacu Kasar',
        'c': 'Kain Goni',
        'd': 'Kain Denim',
        'cor': 'A',
        'exp': 'Mori Primissima adalah jenis katun terbaik dan paling rapat untuk membatik tulis.'
      },
      {
        'q': 'Alat khas berparuh tembaga untuk menorehkan cairan malam batik disebut...',
        'a': 'Cucuk Gawangan',
        'b': 'Canting',
        'c': 'Wajan Wajan',
        'd': 'Bandul Timbal',
        'cor': 'B',
        'exp': 'Canting adalah alat utama untuk menyendok dan mengalirkan malam pada mori.'
      },
      {
        'q': 'Teknik awal menggambar garis outline pola utama batik dinamakan...',
        'a': 'Nembok',
        'b': 'Nglowongi',
        'c': 'Medel',
        'd': 'Nglorod',
        'cor': 'B',
        'exp': 'Nglowongi adalah proses membuat garis luar/kerangka pola utama menggunakan canting.'
      },
      {
        'q': 'Berapa batas nilai kelulusan minimal (passing score) pada Kuis Kenali Batikmu?',
        'a': '50%',
        'b': '60%',
        'c': '70%',
        'd': '85%',
        'cor': 'C',
        'exp': 'Sesuai PRD, syarat kelulusan kuis teori maupun kuis praktik adalah minimal 70%.'
      }
    ];

    for (var q in questions) {
      await db.insert('quiz_questions', {
        'module_id': 1,
        'question': q['q'],
        'option_a': q['a'],
        'option_b': q['b'],
        'option_c': q['c'],
        'option_d': q['d'],
        'correct_option': q['cor'],
        'explanation': q['exp'],
      });
    }

    // 6. Progres Modul Awal Pengguna (User 1 pada Modul 1 = 60% selesai: Sejarah, Karakter, Galeri)
    await db.insert('user_module_progress', {
      'user_id': 1,
      'module_id': 1,
      'status': 'in_progress',
      'progress_percent': 60,
      'history_done': 1,
      'character_done': 1,
      'gallery_done': 1,
      'quiz_done': 0,
      'practice_done': 0,
      'last_accessed_at': now,
    });
  }
}
