import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/app_models.dart';
import '../utils/password_hasher.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Completer<Database>? _initCompleter;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;

    if (_initCompleter != null) {
      return await _initCompleter!.future;
    }

    _initCompleter = Completer<Database>();
    try {
      final db = await _initDB('kenali_batikmu.db');
      _database = db;
      _initCompleter!.complete(db);
      return db;
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      debugPrint('DatabaseHelper notice: $e (Fallback ke in-memory store)');
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final exists = await databaseExists(path);

    if (!exists) {
      // Buat folder jika belum tersedia
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Salin dari asset pre-populated kenali_batikmu.db (20 Modul & 500 Soal)
      try {
        final ByteData data = await rootBundle.load('assets/database/kenali_batikmu.db');
        final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        debugPrint('DatabaseHelper: Berhasil menyalin database master 20 modul dari assets.');
      } catch (e) {
        debugPrint('DatabaseHelper notice: Gagal menyalin assets: $e. Membuat database baru.');
      }
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          try {
            final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM batik_motifs')) ?? 0;
            if (count < 20) {
              final ByteData data = await rootBundle.load('assets/database/kenali_batikmu.db');
              final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
              await File(path).writeAsBytes(bytes, flush: true);
              debugPrint('DatabaseHelper: Berhasil upgrade database lokal ke 20 modul.');
            }
          } catch (_) {}
        }
        await _ensureSeedData(db);
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await _ensureSeedData(db);
      },
    );
  }

  Future<void> _ensureSeedData(Database db) async {
    try {
      final now = DateTime.now().toIso8601String();
      // 1. Akun Default Pengguna (Sekar Ayu Kinanti)
      final users = await db.query('users', where: 'LOWER(email) = ?', whereArgs: ['sekar@batikmu.id']);
      if (users.isEmpty) {
        await db.insert('users', {
          'name': 'Sekar Ayu Kinanti',
          'email': 'sekar@batikmu.id',
          'phone': '081234567890',
          'password_hash': PasswordHasher.hashPassword('Batikmu123#'),
          'created_at': now,
          'updated_at': now,
        });
      }

      // 2. Akun Demo / Kenali Batikmu
      final demoUsers = await db.query('users', where: 'LOWER(email) = ?', whereArgs: ['kenalibatikmu@gmail.com']);
      if (demoUsers.isEmpty) {
        await db.insert('users', {
          'name': 'Kenali Batikmu',
          'email': 'kenalibatikmu@gmail.com',
          'phone': '081987654321',
          'password_hash': PasswordHasher.hashPassword('kenalibatikmupbl'),
          'created_at': now,
          'updated_at': now,
        });
      }

      // 3. Progres Modul 1 Awal jika belum ada
      final progress = await db.query('user_module_progress', where: 'user_id = ? AND module_id = ?', whereArgs: [1, 1]);
      if (progress.isEmpty) {
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
    } catch (e) {
      debugPrint('DatabaseHelper _ensureSeedData error: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        password_hash TEXT NOT NULL,
        failed_attempts INTEGER DEFAULT 0,
        lockout_until TEXT,
        profile_image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS batik_motifs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        slug TEXT NOT NULL UNIQUE,
        origin_region TEXT NOT NULL,
        short_description TEXT NOT NULL,
        thumbnail_url TEXT,
        ml_class_index INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS modules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motif_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        cover_image TEXT,
        video_url TEXT,
        passing_score INTEGER DEFAULT 70,
        order_no INTEGER NOT NULL,
        FOREIGN KEY (motif_id) REFERENCES batik_motifs (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS module_contents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER NOT NULL,
        pillar TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        badge TEXT,
        order_no INTEGER NOT NULL,
        FOREIGN KEY (module_id) REFERENCES modules (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS module_gallery_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        caption TEXT,
        order_no INTEGER NOT NULL,
        FOREIGN KEY (module_id) REFERENCES modules (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS quiz_questions (
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_module_progress (
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        module_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        passed INTEGER NOT NULL,
        total_questions INTEGER DEFAULT 10,
        attempted_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (module_id) REFERENCES modules (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS scans (
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

    await _ensureSeedData(db);
  }

  // --- QUERY METHODS ---

  Future<List<BatikMotifModel>> getAllMotifs() async {
    final db = await database;
    if (db == null) return [];
    try {
      final rows = await db.query('batik_motifs', orderBy: 'id ASC');
      return rows.map((r) => BatikMotifModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error getAllMotifs: $e');
      return [];
    }
  }

  Future<List<ModuleModel>> getAllModules({int userId = 1}) async {
    final db = await database;
    if (db == null) return [];
    try {
      final rows = await db.rawQuery('''
        SELECT 
          m.id, m.motif_id, m.title, m.description, m.cover_image, m.passing_score, m.order_no,
          COALESCE(p.progress_percent, 0) as progress_percent,
          COALESCE(p.history_done, 0) as history_done,
          COALESCE(p.character_done, 0) as character_done,
          COALESCE(p.gallery_done, 0) as gallery_done,
          COALESCE(p.quiz_done, 0) as quiz_done,
          COALESCE(p.practice_done, 0) as practice_done
        FROM modules m
        LEFT JOIN user_module_progress p ON m.id = p.module_id AND p.user_id = ?
        ORDER BY m.order_no ASC
      ''', [userId]);

      List<ModuleModel> list = [];
      for (var r in rows) {
        final mId = r['id'] as int;
        final content = await getModuleContent(mId);
        list.add(ModuleModel(
          id: mId,
          motifId: r['motif_id'] as int,
          title: r['title'] as String,
          description: r['description'] as String,
          coverImage: r['cover_image'] as String?,
          passingScore: r['passing_score'] as int? ?? 70,
          orderNo: r['order_no'] as int,
          progressPercent: r['progress_percent'] as int? ?? 0,
          historyDone: (r['history_done'] as int? ?? 0) == 1,
          characterDone: (r['character_done'] as int? ?? 0) == 1,
          galleryDone: (r['gallery_done'] as int? ?? 0) == 1,
          quizDone: (r['quiz_done'] as int? ?? 0) == 1,
          practiceDone: (r['practice_done'] as int? ?? 0) == 1,
          content: content,
        ));
      }
      return list;
    } catch (e) {
      debugPrint('Error getAllModules: $e');
      return [];
    }
  }

  Future<ModuleContentModel?> getModuleContent(int moduleId) async {
    final db = await database;
    if (db == null) return null;
    try {
      // Ambil asal daerah dari motif
      final motifRows = await db.rawQuery('''
        SELECT b.name, b.origin_region 
        FROM batik_motifs b 
        JOIN modules m ON m.motif_id = b.id 
        WHERE m.id = ? LIMIT 1
      ''', [moduleId]);

      String origin = 'Nusantara';
      String motifName = 'Batik Nusantara';
      if (motifRows.isNotEmpty) {
        origin = motifRows.first['origin_region'] as String? ?? 'Nusantara';
        motifName = motifRows.first['name'] as String? ?? 'Batik Nusantara';
      }

      // Ambil konten 3 pilar
      final contents = await db.query(
        'module_contents',
        where: 'module_id = ?',
        whereArgs: [moduleId],
        orderBy: 'order_no ASC',
      );

      String sejarahBody = '';
      String karakterBody = '';
      for (var c in contents) {
        final p = c['pillar'] as String;
        final b = c['body'] as String;
        if (p == 'sejarah_filosofi') {
          sejarahBody = b;
        } else if (p == 'karakteristik') {
          karakterBody = b;
        }
      }

      // Ambil foto galeri
      final galleryRows = await db.query(
        'module_gallery_images',
        where: 'module_id = ?',
        whereArgs: [moduleId],
        orderBy: 'order_no ASC',
      );

      List<GaleriModel> galeri = galleryRows.map((g) {
        return GaleriModel(
          imageUrl: g['image_url'] as String? ?? '',
          caption: g['caption'] as String? ?? 'Dokumentasi Motif',
        );
      }).toList();

      if (galeri.isEmpty) {
        galeri = [
          GaleriModel(imageUrl: '', caption: 'Proses Canting $motifName'),
          GaleriModel(imageUrl: '', caption: 'Kain Batik Klasik $motifName'),
        ];
      }

      return ModuleContentModel(
        origin: origin,
        estimatedTime: '10 Menit',
        sejarahDanFilosofi: SejarahFilosofiModel(
          youtubeUrl: 'https://www.youtube.com/watch?v=fq4N0hgOWzU',
          deskripsiUtama: sejarahBody.isNotEmpty
              ? sejarahBody
              : 'Pelajari sejarah dan nilai luhur yang terkandung dalam motif $motifName.',
          asalDaerah: origin,
          maknaFilosofis: 'Mengajarkan nilai kesabaran, keluhuran budi, dan harmoni dengan alam.',
          penggunaan: 'Dikenakan dalam upacara adat tradisi, perayaan resmi, maupun busana kontemporer.',
        ),
        karakteristik: KarakteristikModel(
          deskripsi: karakterBody.isNotEmpty
              ? karakterBody
              : 'Karakteristik khas motif $motifName dengan sapuan canting presisi.',
          strukturUtama: KarakteristikDetailModel(
            title: 'Struktur Utama Motif',
            desc: 'Garis kontur ornamen pokok mencerminkan identitas $motifName.',
            badge: 'Struktur Utama',
            image: '',
          ),
          ornamen: KarakteristikDetailModel(
            title: 'Isen-isen Tradisional',
            desc: 'Ornamen isen halus pengisi bidang kain secara berulang.',
            badge: 'Isen-Isen',
            image: '',
          ),
          warna: KarakteristikDetailModel(
            title: 'Pewarnaan Khas',
            desc: 'Kombinasi warna alami soga, indigo, maupun cerah pesisiran.',
            badge: 'Pewarnaan',
            image: '',
          ),
          pakemList: [
            PakemModel(
              title: '1. Konsistensi Tarikan Canting',
              desc: 'Garis lilin malam harus stabil dan tembus ke balik kain mori.',
            ),
            PakemModel(
              title: '2. Kerapian Ornamen Berulang',
              desc: 'Pola geometris atau flora tersusun harmonis mengikuti proporsi pakem.',
            ),
            PakemModel(
              title: '3. Harmoni Warna Tradisional',
              desc: 'Menggunakan perpaduan warna yang selaras dengan filosofi motif daerah asalnya.',
            ),
          ],
        ),
        galeri: galeri,
      );
    } catch (e) {
      debugPrint('Error getModuleContent: $e');
      return null;
    }
  }

  Future<List<QuizQuestionModel>> getQuizQuestions(int moduleId, {int limit = 10, bool shuffle = true}) async {
    final db = await database;
    if (db == null) return [];
    try {
      final rows = await db.query(
        'quiz_questions',
        where: 'module_id = ?',
        whereArgs: [moduleId],
        orderBy: shuffle ? 'RANDOM()' : 'id ASC',
        limit: limit,
      );

      return rows.map((r) => QuizQuestionModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error getQuizQuestions: $e');
      return [];
    }
  }

  Future<void> updatePillarProgress(int userId, int moduleId, String pillar) async {
    final db = await database;
    if (db == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      final rows = await db.query(
        'user_module_progress',
        where: 'user_id = ? AND module_id = ?',
        whereArgs: [userId, moduleId],
      );

      int h = 0, c = 0, g = 0, q = 0, p = 0;
      if (rows.isNotEmpty) {
        h = rows.first['history_done'] as int? ?? 0;
        c = rows.first['character_done'] as int? ?? 0;
        g = rows.first['gallery_done'] as int? ?? 0;
        q = rows.first['quiz_done'] as int? ?? 0;
        p = rows.first['practice_done'] as int? ?? 0;
      }

      if (pillar == 'history') h = 1;
      if (pillar == 'character') c = 1;
      if (pillar == 'gallery') g = 1;

      // Hitung persentase: 5 pilar masing-masing 20%
      int percent = ((h + c + g + q + p) * 20).clamp(0, 100);
      String status = percent >= 100 ? 'completed' : 'in_progress';

      if (rows.isEmpty) {
        await db.insert('user_module_progress', {
          'user_id': userId,
          'module_id': moduleId,
          'status': status,
          'progress_percent': percent,
          'history_done': h,
          'character_done': c,
          'gallery_done': g,
          'quiz_done': q,
          'practice_done': p,
          'last_accessed_at': now,
        });
      } else {
        await db.update(
          'user_module_progress',
          {
            'status': status,
            'progress_percent': percent,
            'history_done': h,
            'character_done': c,
            'gallery_done': g,
            'quiz_done': q,
            'practice_done': p,
            'last_accessed_at': now,
            if (percent >= 100) 'completed_at': now,
          },
          where: 'user_id = ? AND module_id = ?',
          whereArgs: [userId, moduleId],
        );
      }
    } catch (e) {
      debugPrint('Error updatePillarProgress: $e');
    }
  }

  Future<void> saveQuizAttempt({
    required int userId,
    required int moduleId,
    required int score,
    required bool passed,
    int totalQuestions = 10,
  }) async {
    final db = await database;
    if (db == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      await db.insert('quiz_attempts', {
        'user_id': userId,
        'module_id': moduleId,
        'score': score,
        'passed': passed ? 1 : 0,
        'attempted_at': now,
      });

      if (passed) {
        final rows = await db.query(
          'user_module_progress',
          where: 'user_id = ? AND module_id = ?',
          whereArgs: [userId, moduleId],
        );

        int h = 1, c = 1, g = 1, q = 1, p = 0;
        if (rows.isNotEmpty) {
          h = rows.first['history_done'] as int? ?? 1;
          c = rows.first['character_done'] as int? ?? 1;
          g = rows.first['gallery_done'] as int? ?? 1;
          p = rows.first['practice_done'] as int? ?? 0;
        }

        int percent = ((h + c + g + q + p) * 20).clamp(0, 100);
        String status = percent >= 100 ? 'completed' : 'in_progress';

        if (rows.isEmpty) {
          await db.insert('user_module_progress', {
            'user_id': userId,
            'module_id': moduleId,
            'status': status,
            'progress_percent': percent,
            'history_done': h,
            'character_done': c,
            'gallery_done': g,
            'quiz_done': 1,
            'practice_done': p,
            'last_accessed_at': now,
          });
        } else {
          await db.update(
            'user_module_progress',
            {
              'status': status,
              'progress_percent': percent,
              'quiz_done': 1,
              'last_accessed_at': now,
              if (percent >= 100) 'completed_at': now,
            },
            where: 'user_id = ? AND module_id = ?',
            whereArgs: [userId, moduleId],
          );
        }
      }
    } catch (e) {
      debugPrint('Error saveQuizAttempt: $e');
    }
  }

  Future<void> savePracticeAttempt({
    required int userId,
    required int moduleId,
    required double confidence,
    required bool passed,
    String? imagePath,
  }) async {
    final db = await database;
    if (db == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      await db.insert('scans', {
        'user_id': userId,
        'scan_type': 'kuismu',
        'module_id': moduleId,
        'image_path': imagePath,
        'confidence': confidence,
        'fit_score': confidence,
        'passed': passed ? 1 : 0,
        'inference_time_ms': 120,
        'created_at': now,
      });

      if (passed) {
        final rows = await db.query(
          'user_module_progress',
          where: 'user_id = ? AND module_id = ?',
          whereArgs: [userId, moduleId],
        );

        int h = 1, c = 1, g = 1, q = 0, p = 1;
        if (rows.isNotEmpty) {
          h = rows.first['history_done'] as int? ?? 1;
          c = rows.first['character_done'] as int? ?? 1;
          g = rows.first['gallery_done'] as int? ?? 1;
          q = rows.first['quiz_done'] as int? ?? 0;
        }

        int percent = ((h + c + g + q + p) * 20).clamp(0, 100);
        String status = percent >= 100 ? 'completed' : 'in_progress';

        if (rows.isEmpty) {
          await db.insert('user_module_progress', {
            'user_id': userId,
            'module_id': moduleId,
            'status': status,
            'progress_percent': percent,
            'history_done': h,
            'character_done': c,
            'gallery_done': g,
            'quiz_done': q,
            'practice_done': 1,
            'last_accessed_at': now,
          });
        } else {
          await db.update(
            'user_module_progress',
            {
              'status': status,
              'progress_percent': percent,
              'practice_done': 1,
              'last_accessed_at': now,
              if (percent >= 100) 'completed_at': now,
            },
            where: 'user_id = ? AND module_id = ?',
            whereArgs: [userId, moduleId],
          );
        }
      }
    } catch (e) {
      debugPrint('Error savePracticeAttempt: $e');
    }
  }

  Future<List<ScanHistoryModel>> getScanHistories(int userId) async {
    final db = await database;
    if (db == null) return [];
    try {
      final rows = await db.rawQuery('''
        SELECT s.id, s.scan_type, s.confidence, s.passed, s.created_at, b.name as motif_name
        FROM scans s
        LEFT JOIN batik_motifs b ON s.top_motif_id = b.id
        WHERE s.user_id = ?
        ORDER BY s.id DESC
      ''', [userId]);

      return rows.map((r) {
        return ScanHistoryModel(
          id: r['id'] as int,
          scanType: r['scan_type'] as String? ?? 'universal',
          motifName: r['motif_name'] as String?,
          score: (r['confidence'] as num? ?? 0.0).toDouble(),
          passed: (r['passed'] as int? ?? 0) == 1,
          createdAt: r['created_at'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getScanHistories: $e');
      return [];
    }
  }

  /// Cek apakah email terdaftar dalam tabel users
  Future<bool> checkEmailExists(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean == 'kenalibatikmu@gmail.com' || clean == 'sekar@batikmu.id') {
      return true;
    }
    final db = await database;
    if (db == null) return false;
    try {
      final res = await db.query(
        'users',
        columns: ['id'],
        where: 'LOWER(email) = ?',
        whereArgs: [clean],
        limit: 1,
      );
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Ambil data user berdasarkan email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final clean = email.trim().toLowerCase();
    final db = await database;
    if (db != null) {
      try {
        final res = await db.query(
          'users',
          where: 'LOWER(email) = ?',
          whereArgs: [clean],
          limit: 1,
        );
        if (res.isNotEmpty) return res.first;

        // Auto-insert akun default jika belum ada di database lokal
        if (clean == 'kenalibatikmu@gmail.com') {
          final now = DateTime.now().toIso8601String();
          final id = await db.insert('users', {
            'name': 'Kenali Batikmu',
            'email': 'kenalibatikmu@gmail.com',
            'password_hash': PasswordHasher.hashPassword('kenalibatikmupbl'),
            'created_at': now,
            'updated_at': now,
          });
          return {
            'id': id,
            'name': 'Kenali Batikmu',
            'email': 'kenalibatikmu@gmail.com',
            'password_hash': PasswordHasher.hashPassword('kenalibatikmupbl'),
          };
        }
      } catch (_) {}
    }

    // Fallback data in-memory jika SQLite tidak aktif
    if (clean == 'kenalibatikmu@gmail.com') {
      return {
        'id': 2,
        'name': 'Kenali Batikmu',
        'email': 'kenalibatikmu@gmail.com',
        'password_hash': PasswordHasher.hashPassword('kenalibatikmupbl'),
      };
    }
    if (clean == 'sekar@batikmu.id') {
      return {
        'id': 1,
        'name': 'Sekar Ayu Kinanti',
        'email': 'sekar@batikmu.id',
        'password_hash': PasswordHasher.hashPassword('Batikmu123#'),
      };
    }
    return null;
  }

  /// Perbarui kata sandi pengguna (password hash)
  Future<bool> updateUserPassword(String email, String newPasswordHash) async {
    final db = await database;
    if (db == null) return false;
    try {
      final clean = email.trim().toLowerCase();
      final now = DateTime.now().toIso8601String();
      final count = await db.update(
        'users',
        {
          'password_hash': newPasswordHash,
          'updated_at': now,
        },
        where: 'LOWER(email) = ?',
        whereArgs: [clean],
      );
      if (count == 0) {
        await db.insert('users', {
          'name': clean.startsWith('kenalibatikmu')
              ? 'Kenali Batikmu'
              : (clean.startsWith('sekar') ? 'Sekar Ayu Kinanti' : 'Sahabat Batik'),
          'email': clean,
          'password_hash': newPasswordHash,
          'created_at': now,
          'updated_at': now,
        });
        return true;
      }
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  /// Menambahkan akun pengguna baru ke SQLite lokal
  Future<int> insertUser({
    required String name,
    required String email,
    required String passwordHash,
    String? phone,
    String? profileImagePath,
  }) async {
    final db = await database;
    if (db == null) return -1;
    try {
      final now = DateTime.now().toIso8601String();
      final id = await db.insert(
        'users',
        {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone?.trim(),
          'password_hash': passwordHash,
          'profile_image_path': profileImagePath,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      debugPrint('DatabaseHelper insertUser error: $e');
      return -1;
    }
  }

  /// Memperbarui informasi profil pengguna di SQLite lokal
  Future<bool> updateUserProfile({
    required int userId,
    required String name,
    required String email,
    String? phone,
    String? profileImagePath,
  }) async {
    final db = await database;
    if (db == null) return false;
    try {
      final now = DateTime.now().toIso8601String();
      final map = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'updated_at': now,
      };
      if (phone != null) map['phone'] = phone.trim();
      if (profileImagePath != null) map['profile_image_path'] = profileImagePath;

      final count = await db.update(
        'users',
        map,
        where: 'id = ?',
        whereArgs: [userId],
      );
      return count > 0;
    } catch (e) {
      debugPrint('DatabaseHelper updateUserProfile error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MANAJEMEN PROGRES MODUL PENGGUNA (Tabel: user_module_progress)
  // Sesuai standar SQLite Relasional & Siap Integrasi Backend Python
  // ─────────────────────────────────────────────────────────────────────────

  /// Ambil seluruh progres modul untuk satu pengguna tertentu
  Future<List<Map<String, dynamic>>> getUserModuleProgressList(int userId) async {
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        'user_module_progress',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Info query user_module_progress: $e');
      return [];
    }
  }

  /// Ambil progres satu modul spesifik untuk pengguna
  Future<Map<String, dynamic>?> getUserModuleProgress(int userId, int moduleId) async {
    final db = await database;
    if (db == null) return null;
    try {
      final res = await db.query(
        'user_module_progress',
        where: 'user_id = ? AND module_id = ?',
        whereArgs: [userId, moduleId],
        limit: 1,
      );
      if (res.isNotEmpty) return res.first;
    } catch (e) {
      debugPrint('Info query single user_module_progress: $e');
    }
    return null;
  }

  /// Simpan atau perbarui progres modul pengguna ke SQLite (UPSERT)
  Future<bool> upsertUserModuleProgress({
    required int userId,
    required int moduleId,
    required int progressPercent,
    required bool historyDone,
    required bool characterDone,
    required bool galleryDone,
    required bool quizDone,
    required bool practiceDone,
  }) async {
    final db = await database;
    if (db == null) return false;
    try {
      final now = DateTime.now().toIso8601String();
      final status = progressPercent >= 100
          ? 'completed'
          : (progressPercent > 0 ? 'in_progress' : 'not_started');

      await db.insert(
        'user_module_progress',
        {
          'user_id': userId,
          'module_id': moduleId,
          'status': status,
          'progress_percent': progressPercent,
          'history_done': historyDone ? 1 : 0,
          'character_done': characterDone ? 1 : 0,
          'gallery_done': galleryDone ? 1 : 0,
          'quiz_done': quizDone ? 1 : 0,
          'practice_done': practiceDone ? 1 : 0,
          'completed_at': progressPercent >= 100 ? now : null,
          'last_accessed_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      debugPrint('Info upsert user_module_progress: $e');
      return false;
    }
  }
}
