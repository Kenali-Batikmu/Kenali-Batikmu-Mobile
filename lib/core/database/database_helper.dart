import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/app_models.dart';
import 'daos/module_dao.dart';
import 'daos/offline_queue_dao.dart';
import 'daos/quiz_dao.dart';
import 'daos/user_dao.dart';

/// DatabaseHelper bertindak sebagai Connection Lifecycle Manager dan Central Facade
/// untuk seluruh operasi database SQLite lokal melalui Data Access Objects (DAOs).
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Completer<Database>? _initCompleter;

  // Domain DAOs (Data Access Objects)
  late final UserDao userDao = UserDao(() => database);
  late final ModuleDao moduleDao = ModuleDao(() => database);
  late final QuizDao quizDao = QuizDao(() => database);
  late final OfflineQueueDao offlineQueueDao = OfflineQueueDao(() => database);

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
      // Dijalankan setelah database benar-benar terbuka (di luar callback
      // onOpen) agar operasi transaksi tidak bertabrakan dengan proses open.
      await ensureMasterContent(db);
      _initCompleter!.complete(db);
      return db;
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      debugPrint('DatabaseHelper notice: $e (Fallback ke in-memory store)');
      return null;
    }
  }

  /// Melakukan reset total database lokal SQLite dan menyalin ulang segar (fresh) dari assets
  Future<Database?> migrateFresh() async {
    if (kIsWeb) return null;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'kenali_batikmu.db');

      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
      _initCompleter = null;

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('DatabaseHelper: Database lokal lama dihapus untuk migrate fresh.');
      }

      // Inisialisasi ulang bersih dari asset
      return await database;
    } catch (e) {
      debugPrint('DatabaseHelper migrateFresh error: $e');
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
      version: 6,
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
        await _ensureQuizQuestionsSeeded(db);
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await _ensureSeedData(db);
        await _ensureQuizQuestionsSeeded(db);
      },
    );
  }

  /// Memastikan seluruh 500 butir soal kuis (25 butir x 20 modul) tersimpan di SQLite lokal
  Future<void> _ensureQuizQuestionsSeeded(Database db) async {
    try {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quiz_questions')) ?? 0;
      if (count < 500) {
        debugPrint('DatabaseHelper: quiz_questions hanya $count butir, menyinkronkan 500 butir dari asset...');
        final dbPath = await getDatabasesPath();
        final tempPath = join(dbPath, 'kenali_batikmu_seed_temp.db');
        final ByteData data = await rootBundle.load('assets/database/kenali_batikmu.db');
        final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes, flush: true);

        final seedDb = await openReadOnlyDatabase(tempPath);
        final questions = await seedDb.query('quiz_questions');
        if (questions.isNotEmpty) {
          final batch = db.batch();
          for (final q in questions) {
            batch.insert(
              'quiz_questions',
              q,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          debugPrint('DatabaseHelper: Berhasil memasukkan ${questions.length} butir soal kuis ke database lokal.');
        }
        await seedDb.close();
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    } catch (e) {
      debugPrint('DatabaseHelper notice _ensureQuizQuestionsSeeded: $e');
    }
  }

  /// Menjaga integritas master data kurikulum (20 modul, konten pilar, galeri).
  /// Dijalankan pada onOpen agar tidak berada di dalam transaksi onUpgrade,
  /// sehingga aman membuka berkas asset sementara.
  Future<void> ensureMasterContent([Database? target]) async {
    final db = target ?? await database;
    if (db == null) return;
    try {
      final moduleCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM modules'),
          ) ??
          0;
      final contentCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM module_contents'),
          ) ??
          0;
      final galleryCount = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM module_gallery_images '
              'WHERE image_url IS NOT NULL AND TRIM(image_url) <> ?',
              [''],
            ),
          ) ??
          0;

      if (moduleCount >= 20 && contentCount >= 240 && galleryCount >= 100) {
        return;
      }

      debugPrint(
        'DatabaseHelper: master data belum lengkap '
        '(modul=$moduleCount, konten=$contentCount, galeri=$galleryCount). Menyegarkan dari asset...',
      );

      final dbPath = await getDatabasesPath();
      final tempPath = join(dbPath, 'kenali_batikmu_seed_content.db');
      final ByteData data = await rootBundle.load('assets/database/kenali_batikmu.db');
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      List<Map<String, Object?>> seedModules = [];
      List<Map<String, Object?>> seedMotifs = [];
      List<Map<String, Object?>> seedContents = [];
      List<Map<String, Object?>> seedGallery = [];

      final seedDb = await openReadOnlyDatabase(tempPath);
      try {
        seedModules = await seedDb.query('modules');
        seedMotifs = await seedDb.query('batik_motifs');
        seedContents = await seedDb.query('module_contents');
        seedGallery = await seedDb.query('module_gallery_images');
      } finally {
        await seedDb.close();
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }

      if (seedModules.isEmpty || seedContents.isEmpty) {
        debugPrint('DatabaseHelper: asset master data kosong, penyegaran dibatalkan.');
        return;
      }

      await db.transaction((txn) async {
        await txn.rawUpdate('UPDATE modules SET order_no = order_no + 1000');

        for (final m in seedModules) {
          await txn.update(
            'modules',
            {
              'title': m['title'],
              'description': m['description'],
              'cover_image': m['cover_image'],
              'video_url': m['video_url'],
              'passing_score': m['passing_score'],
              'order_no': m['order_no'],
            },
            where: 'id = ?',
            whereArgs: [m['id']],
          );
        }

        for (final m in seedMotifs) {
          await txn.update(
            'batik_motifs',
            {
              'name': m['name'],
              'origin_region': m['origin_region'],
              'short_description': m['short_description'],
              'thumbnail_url': m['thumbnail_url'],
            },
            where: 'id = ?',
            whereArgs: [m['id']],
          );
        }

        await txn.delete('module_contents');
        for (final c in seedContents) {
          await txn.insert('module_contents', c);
        }

        await txn.delete('module_gallery_images');
        for (final g in seedGallery) {
          await txn.insert('module_gallery_images', g);
        }
      });

      debugPrint(
        'DatabaseHelper: master data disegarkan '
        '(${seedModules.length} modul, ${seedContents.length} konten, ${seedGallery.length} galeri).',
      );
    } catch (e) {
      debugPrint('DatabaseHelper _ensureMasterContent error: $e');
    }
  }

  Future<void> _ensureSeedData(Database db) async {
    // Pastikan kolom is_synced tersedia di tabel transaksi lokal untuk antrean offline
    for (var table in ['quiz_attempts', 'scans', 'user_module_progress']) {
      try {
        await db.execute('ALTER TABLE $table ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      } catch (_) {
        // Kolom sudah ada
      }
    }

    // Pastikan kolom skor dan kelulusan tersedia di user_module_progress
    final progressColumns = [
      'ALTER TABLE user_module_progress ADD COLUMN quiz_score INTEGER',
      'ALTER TABLE user_module_progress ADD COLUMN practice_score INTEGER',
      'ALTER TABLE user_module_progress ADD COLUMN passing_score INTEGER NOT NULL DEFAULT 70',
      'ALTER TABLE user_module_progress ADD COLUMN is_passed INTEGER NOT NULL DEFAULT 0',
    ];
    for (var colSql in progressColumns) {
      try {
        await db.execute(colSql);
      } catch (_) {}
    }

    // Kolom gambar pendukung kartu karakteristik (struktur, ornamen, warna)
    try {
      await db.execute('ALTER TABLE module_contents ADD COLUMN image_url TEXT');
    } catch (_) {}

    // Pastikan hanya ada 1 baris rekaman kuis praktikum per modul per user (Storage Hygiene)
    try {
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_scans_user_module_kuismu ON scans(user_id, module_id) WHERE scan_type = \'kuismu\'');
    } catch (_) {}

    // Migrasi kredensial akun bawaan (hanya bila hash masih bawaan/ belum diubah
    // pengguna). Kata sandi pengguna yang sudah diganti tidak akan disentuh.
    const shippedDemoHashes = {
      'sekar@batikmu.id': r'scrypt$16384$8$1$zbrWPS+S0/jlqYeDvOGmnA==$fow1obJAcTSUZYYj3k0NgxSOCZfJQUiCrG8bO/BR+iM=',
      'kenalibatikmu@gmail.com': r'scrypt$16384$8$1$AmBBs0TFWg2EGcznFFrCAw==$ka/YpHQY7l7o7oBAtW9Wm4sa0mR7UgO7W352NoGDSCw=',
    };
    const refreshedDemoHashes = {
      'sekar@batikmu.id': r'scrypt$16384$8$1$9c0R6c5+ShvUikyZ5Crtng==$bt+8mFGo294+k9PoZ3YmWg6d3N8fjfIX9bcNZ0HSTXc=',
      'kenalibatikmu@gmail.com': r'scrypt$16384$8$1$WTIJ0QDb0wecvsfiMAvuKA==$BFuIufSKQ6TDsLh/8EdzENd2yG/N0VfMz40HCDbwoAk=',
    };
    for (final entry in shippedDemoHashes.entries) {
      try {
        await db.update(
          'users',
          {
            'password_hash': refreshedDemoHashes[entry.key],
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'email = ? AND password_hash = ?',
          whereArgs: [entry.key, entry.value],
        );
      } catch (e) {
        debugPrint('DatabaseHelper demo credential patch: $e');
      }
    }

    // Patch cover_image untuk semua 20 modul batik dari assets lokal
    // Setiap kali app dibuka, pastikan path cover_image sudah benar (UPSERT aman)
    const moduleCoverImages = {
      1:  'assets/images/batik/betawi_cover.jpg',
      2:  'assets/images/batik/bokor_kencono_cover.jpg',
      3:  'assets/images/batik/buketan_cover.jpg',
      4:  'assets/images/batik/dayak_cover.jpg',
      5:  'assets/images/batik/jlamprang_cover.jpg',
      6:  'assets/images/batik/kawung_cover.jpg',
      7:  'assets/images/batik/liong_cover.jpg',
      8:  'assets/images/batik/mega_mendung_cover.jpg',
      9:  'assets/images/batik/parang_cover.jpg',
      10: 'assets/images/batik/sekarjagad_cover.jpg',
      11: 'assets/images/batik/sidoluhur_cover.jpg',
      12: 'assets/images/batik/sidomukti_cover.jpg',
      13: 'assets/images/batik/sidomulyo_cover.jpg',
      14: 'assets/images/batik/singa_barong_cover.jpg',
      15: 'assets/images/batik/srikaton_cover.jpg',
      16: 'assets/images/batik/tribusono_cover.jpg',
      17: 'assets/images/batik/tujuh_rupa_cover.jpg',
      18: 'assets/images/batik/tuntrum_cover.jpg',
      19: 'assets/images/batik/wahyu_tumurun_cover.jpg',
      20: 'assets/images/batik/wirasat_cover.jpg',
    };
    for (final entry in moduleCoverImages.entries) {
      try {
        // UPDATE tanpa kondisi — selalu perbarui ke path standar modules/
        await db.rawUpdate(
          'UPDATE modules SET cover_image = ? WHERE id = ?',
          [entry.value, entry.key],
        );
      } catch (e) {
        debugPrint('DatabaseHelper _ensureSeedData cover patch: $e');
      }
    }

    // Pastikan tautan video edukasi tiap modul tidak pernah kosong akibat
    // sinkronisasi cloud (nilai NULL dari server tidak boleh menghapus data kurasi lokal)
    const moduleVideoUrls = {
      1: 'https://www.youtube.com/watch?v=rfa_O5Bv1iw',
      2: 'https://www.youtube.com/watch?v=jtdrACMdNjg',
      3: 'https://www.youtube.com/watch?v=Q_j5qLDAGPo',
      4: 'https://www.youtube.com/watch?v=7QTSrCcc3iU',
      5: 'https://www.youtube.com/watch?v=0Isdn3f5SXE',
      6: 'https://www.youtube.com/watch?v=wMo4s5Ja4e4',
      7: 'https://www.youtube.com/watch?v=RtRIOeKEWi0',
      8: 'https://www.youtube.com/watch?v=aetXWgzqI88',
      9: 'https://www.youtube.com/watch?v=iyh4W5en-hk',
      10: 'https://www.youtube.com/watch?v=EBfSz2tlmqQ',
      11: 'https://www.youtube.com/watch?v=fCXqQKYqsX4',
      12: 'https://www.youtube.com/watch?v=8sBgN7Mvz_A',
      13: 'https://www.youtube.com/watch?v=dqzFIu002NM',
      14: 'https://www.youtube.com/watch?v=GN1C21aeYHo',
      15: 'https://www.youtube.com/watch?v=5WA38GD0HUg',
      16: 'https://www.youtube.com/watch?v=o8bI9dauR0Q',
      17: 'https://www.youtube.com/watch?v=_aVvMX2dXCE',
      18: 'https://www.youtube.com/watch?v=zoC_dYfpdiA',
      19: 'https://www.youtube.com/watch?v=Cq6NxsuzXfc',
      20: 'https://www.youtube.com/watch?v=ek-N7hAX1R8',
    };
    for (final entry in moduleVideoUrls.entries) {
      try {
        await db.rawUpdate(
          'UPDATE modules SET video_url = ? WHERE id = ? AND (video_url IS NULL OR TRIM(video_url) = ?)',
          [entry.value, entry.key, ''],
        );
      } catch (e) {
        debugPrint('DatabaseHelper _ensureSeedData video patch: $e');
      }
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
        quiz_score INTEGER,
        practice_score INTEGER,
        passing_score INTEGER NOT NULL DEFAULT 70,
        is_passed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        last_accessed_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
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
        is_synced INTEGER NOT NULL DEFAULT 0,
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
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (module_id) REFERENCES modules (id),
        FOREIGN KEY (top_motif_id) REFERENCES batik_motifs (id)
      )
    ''');

    await _ensureSeedData(db);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELEGATION METHODS (Backward Compatibility - Zero Breaking Changes)
  // Seluruh pemanggil lama (AppProvider, screens, unit test) tetap berfungsi 100%
  // ─────────────────────────────────────────────────────────────────────────

  // --- Module & Motif Delegation ---
  Future<List<BatikMotifModel>> getAllMotifs() => moduleDao.getAllMotifs();
  Future<int> upsertMotifs(List<Map<String, dynamic>> motifs) => moduleDao.upsertMotifs(motifs);
  Future<int> upsertModules(List<Map<String, dynamic>> modules) => moduleDao.upsertModules(modules);
  Future<int> deleteMotifById(int id) => moduleDao.deleteMotifById(id);
  Future<List<ModuleModel>> getAllModules({int? userId, String? userEmail}) =>
      moduleDao.getAllModules(userId: userId, userEmail: userEmail);
  Future<ModuleContentModel?> getModuleContent(int moduleId) => moduleDao.getModuleContent(moduleId);
  Future<void> updatePillarProgress(int userId, int moduleId, String pillar) =>
      moduleDao.updatePillarProgress(userId, moduleId, pillar);
  Future<List<Map<String, dynamic>>> getUserModuleProgressList(int userId, {String? userEmail}) =>
      moduleDao.getUserModuleProgressList(userId, userEmail: userEmail);
  Future<Map<String, dynamic>?> getUserModuleProgress(int userId, int moduleId) =>
      moduleDao.getUserModuleProgress(userId, moduleId);
  Future<bool> upsertUserModuleProgress({
    required int userId,
    required int moduleId,
    required int progressPercent,
    required bool historyDone,
    required bool characterDone,
    required bool galleryDone,
    required bool quizDone,
    required bool practiceDone,
    int? quizScore,
    int? practiceScore,
    int passingScore = 70,
    bool isPassed = false,
    bool isSynced = false,
  }) =>
      moduleDao.upsertUserModuleProgress(
        userId: userId,
        moduleId: moduleId,
        progressPercent: progressPercent,
        historyDone: historyDone,
        characterDone: characterDone,
        galleryDone: galleryDone,
        quizDone: quizDone,
        practiceDone: practiceDone,
        quizScore: quizScore,
        practiceScore: practiceScore,
        passingScore: passingScore,
        isPassed: isPassed,
        isSynced: isSynced,
      );

  // --- Quiz & Practice Delegation ---
  Future<List<QuizQuestionModel>> getQuizQuestions(int moduleId, {int limit = 10, bool shuffle = true}) =>
      quizDao.getQuizQuestions(moduleId, limit: limit, shuffle: shuffle);
  Future<void> saveQuizAttempt({
    required int userId,
    required int moduleId,
    required int score,
    required bool passed,
    int totalQuestions = 10,
    bool isSynced = false,
  }) =>
      quizDao.saveQuizAttempt(
        userId: userId,
        moduleId: moduleId,
        score: score,
        passed: passed,
        totalQuestions: totalQuestions,
        isSynced: isSynced,
      );
  Future<void> savePracticeAttempt({
    required int userId,
    required int moduleId,
    int? topMotifId,
    required double confidence,
    required bool passed,
    String? imagePath,
    bool isSynced = false,
  }) =>
      quizDao.savePracticeAttempt(
        userId: userId,
        moduleId: moduleId,
        topMotifId: topMotifId,
        confidence: confidence,
        passed: passed,
        imagePath: imagePath,
        isSynced: isSynced,
      );
  Future<List<ScanHistoryModel>> getScanHistories(int? userId, {String? userEmail}) =>
      quizDao.getScanHistories(userId, userEmail: userEmail);
  Future<List<Map<String, dynamic>>> getPracticeAttempts({
    required int userId,
    int? moduleId,
  }) =>
      quizDao.getPracticeAttempts(userId: userId, moduleId: moduleId);

  // --- User Delegation ---
  Future<bool> checkEmailExists(String email) => userDao.checkEmailExists(email);
  Future<Map<String, dynamic>?> getUserByEmail(String email) => userDao.getUserByEmail(email);
  Future<bool> updateUserPassword(String email, String newPasswordHash) =>
      userDao.updateUserPassword(email, newPasswordHash);
  Future<int> insertUser({
    int? id,
    required String name,
    required String email,
    required String passwordHash,
    String? phone,
    String? profileImagePath,
  }) =>
      userDao.insertUser(
        id: id,
        name: name,
        email: email,
        passwordHash: passwordHash,
        phone: phone,
        profileImagePath: profileImagePath,
      );
  Future<bool> updateUserProfile({
    required int userId,
    required String name,
    required String email,
    String? phone,
    String? profileImagePath,
  }) =>
      userDao.updateUserProfile(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        profileImagePath: profileImagePath,
      );

  // --- Offline Queue Delegation ---
  Future<List<Map<String, dynamic>>> getUnsyncedQuizAttempts(int userId, {String? userEmail}) =>
      offlineQueueDao.getUnsyncedQuizAttempts(userId, userEmail: userEmail);
  Future<void> markQuizAttemptSynced(int id) => offlineQueueDao.markQuizAttemptSynced(id);
  Future<List<Map<String, dynamic>>> getUnsyncedScans(int userId, {String? userEmail}) =>
      offlineQueueDao.getUnsyncedScans(userId, userEmail: userEmail);
  Future<void> markScanSynced(int id) => offlineQueueDao.markScanSynced(id);
  Future<List<Map<String, dynamic>>> getUnsyncedUserModuleProgress(int userId, {String? userEmail}) =>
      offlineQueueDao.getUnsyncedUserModuleProgress(userId, userEmail: userEmail);
  Future<void> markUserModuleProgressSynced(int userId, int moduleId) =>
      offlineQueueDao.markUserModuleProgressSynced(userId, moduleId);
}
