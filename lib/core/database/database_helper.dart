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
      version: 4,
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

    // Pastikan hanya ada 1 baris rekaman kuis praktikum per modul per user (Storage Hygiene)
    try {
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_scans_user_module_kuismu ON scans(user_id, module_id) WHERE scan_type = \'kuismu\'');
    } catch (_) {}

    // Patch cover_image untuk semua 20 modul batik dari assets lokal
    // Setiap kali app dibuka, pastikan path cover_image sudah benar (UPSERT aman)
    const moduleCoverImages = {
      1:  'assets/images/modules/Batik-Betawi.jpeg',
      2:  'assets/images/modules/Batik-Bokor-Kencono.jpeg',
      3:  'assets/images/modules/Batik-Buketan.jpeg',
      4:  'assets/images/modules/Batik-Dayak.jpeg',
      5:  'assets/images/modules/Batik-Jlamprang.jpeg',
      6:  'assets/images/modules/Batik-Kawung.jpeg',
      7:  'assets/images/modules/Batik-Liong.jpeg',
      8:  'assets/images/modules/Batik-Mega-Mendung.jpeg',
      9:  'assets/images/modules/Batik-Parang.jpeg',
      10: 'assets/images/modules/Batik-Sekar-Jagad.jpeg',
      11: 'assets/images/modules/Batik-SidoLuhur.jpeg',
      12: 'assets/images/modules/Batik-SidoMukti.jpeg',
      13: 'assets/images/modules/Batik-SidoMulyo.jpeg',
      14: 'assets/images/modules/Batik-Singa-Barong.jpeg',
      15: 'assets/images/modules/Batik-Srikaton.jpeg',
      16: 'assets/images/modules/Batik-Tribusono.jpeg',
      17: 'assets/images/modules/Batik-Tujuh-Rupa.jpeg',
      18: 'assets/images/modules/Batik-Truntum.jpeg',
      19: 'assets/images/modules/Batik-Wahyu-Tumurun.jpeg',
      20: 'assets/images/modules/Batik-Wirasat.jpeg',
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
