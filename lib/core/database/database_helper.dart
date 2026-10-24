import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/app_models.dart';
import '../services/supabase_service.dart';

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

  /// Sinkronisasi daftar motif dari cloud ke SQLite lokal (UPSERT)
  Future<int> upsertMotifs(List<Map<String, dynamic>> motifs) async {
    final db = await database;
    if (db == null || motifs.isEmpty) return 0;
    try {
      final batch = db.batch();
      for (var m in motifs) {
        batch.insert(
          'batik_motifs',
          {
            'id': m['id'],
            'name': m['name'],
            'slug': m['slug'],
            'origin_region': m['origin_region'] ?? 'Nusantara',
            'short_description': m['short_description'] ?? '',
            'thumbnail_url': m['thumbnail_url'],
            'ml_class_index': m['ml_class_index'] ?? 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return motifs.length;
    } catch (e) {
      debugPrint('DatabaseHelper upsertMotifs error: $e');
      return 0;
    }
  }

  /// Sinkronisasi daftar modul dari cloud ke SQLite lokal (UPSERT)
  Future<int> upsertModules(List<Map<String, dynamic>> modules) async {
    final db = await database;
    if (db == null || modules.isEmpty) return 0;
    try {
      final batch = db.batch();
      for (var m in modules) {
        batch.insert(
          'modules',
          {
            'id': m['id'],
            'motif_id': m['motif_id'],
            'title': m['title'],
            'description': m['description'],
            'cover_image': m['cover_image'],
            'video_url': m['video_url'],
            'passing_score': m['passing_score'] ?? 70,
            'order_no': m['order_no'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return modules.length;
    } catch (e) {
      debugPrint('DatabaseHelper upsertModules error: $e');
      return 0;
    }
  }

  /// Hapus satu motif spesifik (berguna untuk pembersihan uji coba atau sinkronisasi)
  Future<int> deleteMotifById(int id) async {
    final db = await database;
    if (db == null) return 0;
    try {
      return await db.delete('batik_motifs', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('DatabaseHelper deleteMotifById error: $e');
      return 0;
    }
  }

  Future<List<ModuleModel>> getAllModules({int? userId, String? userEmail}) async {
    final db = await database;
    if (db == null) return [];
    try {
      int? effectiveUserId = userId;
      if (userEmail != null && userEmail.trim().isNotEmpty) {
        final u = await db.query(
          'users',
          columns: ['id'],
          where: 'LOWER(email) = ?',
          whereArgs: [userEmail.trim().toLowerCase()],
          limit: 1,
        );
        if (u.isNotEmpty) {
          effectiveUserId = u.first['id'] as int;
        }
      }

      final List<Map<String, dynamic>> rows;
      if (effectiveUserId != null) {
        rows = await db.rawQuery('''
          SELECT 
            m.id, m.motif_id, m.title, m.description, m.cover_image, m.passing_score, m.order_no,
            COALESCE(p.progress_percent, 0) as progress_percent,
            COALESCE(p.history_done, 0) as history_done,
            COALESCE(p.character_done, 0) as character_done,
            COALESCE(p.gallery_done, 0) as gallery_done,
            COALESCE(p.quiz_done, 0) as quiz_done,
            COALESCE(p.practice_done, 0) as practice_done,
            p.quiz_score,
            p.practice_score
          FROM modules m
          LEFT JOIN user_module_progress p 
            ON m.id = p.module_id AND p.user_id = ?
          ORDER BY m.order_no ASC
        ''', [effectiveUserId]);
      } else {
        rows = await db.rawQuery('''
          SELECT 
            m.id, m.motif_id, m.title, m.description, m.cover_image, m.passing_score, m.order_no,
            0 as progress_percent,
            0 as history_done,
            0 as character_done,
            0 as gallery_done,
            0 as quiz_done,
            0 as practice_done,
            NULL as quiz_score,
            NULL as practice_score
          FROM modules m
          ORDER BY m.order_no ASC
        ''');
      }

      List<ModuleModel> list = [];
      for (var r in rows) {
        final mId = r['id'] as int;
        final content = await getModuleContent(mId);
        final tempMod = ModuleModel(
          id: mId,
          motifId: r['motif_id'] as int,
          title: r['title'] as String,
          description: r['description'] as String,
          coverImage: r['cover_image'] as String?,
          passingScore: r['passing_score'] as int? ?? 70,
          orderNo: r['order_no'] as int,
          historyDone: (r['history_done'] as int? ?? 0) == 1,
          characterDone: (r['character_done'] as int? ?? 0) == 1,
          galleryDone: (r['gallery_done'] as int? ?? 0) == 1,
          quizDone: (r['quiz_done'] as int? ?? 0) == 1,
          practiceDone: (r['practice_done'] as int? ?? 0) == 1,
          quizScore: r['quiz_score'] as int?,
          practiceScore: r['practice_score'] as int?,
          content: content,
        );
        list.add(tempMod.copyWith(
          progressPercent: tempMod.calculateProgressPercent(),
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
    if (db != null) {
      try {
        final rows = await db.query(
          'quiz_questions',
          where: 'module_id = ?',
          whereArgs: [moduleId],
          orderBy: shuffle ? 'RANDOM()' : 'id ASC',
          limit: limit,
        );

        if (rows.isNotEmpty) {
          return rows.map((r) => QuizQuestionModel.fromMap(r)).toList();
        }
      } catch (e) {
        debugPrint('Error getQuizQuestions SQLite: $e');
      }
    }

    // Fallback ke Cloud Supabase jika SQLite kosong atau di web
    if (SupabaseService.instance.isReady) {
      try {
        final cloudRows = await SupabaseService.instance.fetchQuizQuestions(moduleId);
        if (cloudRows.isNotEmpty) {
          if (db != null) {
            final batch = db.batch();
            for (final r in cloudRows) {
              batch.insert('quiz_questions', r, conflictAlgorithm: ConflictAlgorithm.replace);
            }
            await batch.commit(noResult: true);
          }

          var list = cloudRows.map((r) => QuizQuestionModel.fromMap(r)).toList();
          if (shuffle) list.shuffle();
          if (list.length > limit) list = list.sublist(0, limit);
          return list;
        }
      } catch (e) {
        debugPrint('Error getQuizQuestions Supabase fallback: $e');
      }
    }

    return [];
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
      int? qS, pS;
      int passScore = 70;
      if (rows.isNotEmpty) {
        h = rows.first['history_done'] as int? ?? 0;
        c = rows.first['character_done'] as int? ?? 0;
        g = rows.first['gallery_done'] as int? ?? 0;
        q = rows.first['quiz_done'] as int? ?? 0;
        p = rows.first['practice_done'] as int? ?? 0;
        qS = rows.first['quiz_score'] as int?;
        pS = rows.first['practice_score'] as int?;
        passScore = rows.first['passing_score'] as int? ?? 70;
      }

      if (pillar == 'history') h = 1;
      if (pillar == 'character') c = 1;
      if (pillar == 'gallery') g = 1;

      // 5 komponen masing-masing 20%: Kuis hanya menyumbang 20% jika lulus KKM (>= 70)
      int completedComponents = (h == 1 ? 1 : 0) +
          (c == 1 ? 1 : 0) +
          (g == 1 ? 1 : 0) +
          (q == 1 && (qS ?? 0) >= passScore ? 1 : 0) +
          (p == 1 && (pS ?? 0) >= passScore ? 1 : 0);
      int percent = (completedComponents * 20).clamp(0, 100);
      String status = percent >= 100 ? 'completed' : (percent > 0 ? 'in_progress' : 'not_started');
      int isPassed = percent >= 100 ? 1 : 0;

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
          'quiz_score': qS,
          'practice_score': pS,
          'passing_score': passScore,
          'is_passed': isPassed,
          'last_accessed_at': now,
          'is_synced': 0,
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
            'quiz_score': qS,
            'practice_score': pS,
            'passing_score': passScore,
            'is_passed': isPassed,
            'last_accessed_at': now,
            if (percent >= 100) 'completed_at': now,
            'is_synced': 0,
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
    bool isSynced = false,
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
        'is_synced': isSynced ? 1 : 0,
      });

      final rows = await db.query(
        'user_module_progress',
        where: 'user_id = ? AND module_id = ?',
        whereArgs: [userId, moduleId],
      );

      int h = 0, c = 0, g = 0, p = 0;
      int? pS;
      int passScore = 70;
      if (rows.isNotEmpty) {
        h = rows.first['history_done'] as int? ?? 0;
        c = rows.first['character_done'] as int? ?? 0;
        g = rows.first['gallery_done'] as int? ?? 0;
        p = rows.first['practice_done'] as int? ?? 0;
        pS = rows.first['practice_score'] as int?;
        passScore = rows.first['passing_score'] as int? ?? 70;
      }

      int q = passed ? 1 : 0;
      int completedComponents = (h == 1 ? 1 : 0) +
          (c == 1 ? 1 : 0) +
          (g == 1 ? 1 : 0) +
          (q == 1 && score >= passScore ? 1 : 0) +
          (p == 1 && (pS ?? 0) >= passScore ? 1 : 0);
      int percent = (completedComponents * 20).clamp(0, 100);
      String status = percent >= 100 ? 'completed' : (percent > 0 ? 'in_progress' : 'not_started');
      int isPassed = percent >= 100 ? 1 : 0;

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
          'quiz_score': score,
          'practice_score': pS,
          'passing_score': passScore,
          'is_passed': isPassed,
          'last_accessed_at': now,
          'is_synced': isSynced ? 1 : 0,
        });
      } else {
        await db.update(
          'user_module_progress',
          {
            'status': status,
            'progress_percent': percent,
            'quiz_done': q,
            'quiz_score': score,
            'is_passed': isPassed,
            'last_accessed_at': now,
            if (percent >= 100) 'completed_at': now,
            'is_synced': isSynced ? 1 : 0,
          },
          where: 'user_id = ? AND module_id = ?',
          whereArgs: [userId, moduleId],
        );
      }
    } catch (e) {
      debugPrint('Error saveQuizAttempt: $e');
    }
  }

  Future<void> savePracticeAttempt({
    required int userId,
    required int moduleId,
    int? topMotifId,
    required double confidence,
    required bool passed,
    String? imagePath,
    bool isSynced = false,
  }) async {
    final db = await database;
    if (db == null) return;
    try {
      final now = DateTime.now().toIso8601String();
      int? effectiveMotifId = topMotifId;
      if (effectiveMotifId == null) {
        final modRows = await db.query('modules', columns: ['motif_id'], where: 'id = ?', whereArgs: [moduleId]);
        if (modRows.isNotEmpty) {
          effectiveMotifId = modRows.first['motif_id'] as int?;
        }
      }

      // Bersihkan scan praktikum lama modul ini dan hapus file foto lama jika beda (1 rekaman per modul)
      final oldScans = await db.query(
        'scans',
        columns: ['id', 'image_path'],
        where: 'user_id = ? AND module_id = ? AND scan_type = ?',
        whereArgs: [userId, moduleId, 'kuismu'],
      );

      for (var old in oldScans) {
        final oldImg = old['image_path'] as String?;
        if (oldImg != null && oldImg.isNotEmpty && oldImg != imagePath && !kIsWeb && !oldImg.startsWith('http')) {
          try {
            final f = File(oldImg);
            if (f.existsSync()) {
              f.deleteSync();
            }
          } catch (_) {}
        }
      }

      await db.delete(
        'scans',
        where: 'user_id = ? AND module_id = ? AND scan_type = ?',
        whereArgs: [userId, moduleId, 'kuismu'],
      );

      await db.insert('scans', {
        'user_id': userId,
        'scan_type': 'kuismu',
        'module_id': moduleId,
        'top_motif_id': effectiveMotifId,
        'image_path': imagePath,
        'confidence': confidence,
        'fit_score': confidence,
        'passed': passed ? 1 : 0,
        'inference_time_ms': 120,
        'created_at': now,
        'is_synced': isSynced ? 1 : 0,
      });

      final intScore = (confidence > 1.0 ? confidence : confidence * 100).round().clamp(0, 100);

      final rows = await db.query(
        'user_module_progress',
        where: 'user_id = ? AND module_id = ?',
        whereArgs: [userId, moduleId],
      );

      int h = 0, c = 0, g = 0, q = 0;
      int? qS;
      int passScore = 70;
      if (rows.isNotEmpty) {
        h = rows.first['history_done'] as int? ?? 0;
        c = rows.first['character_done'] as int? ?? 0;
        g = rows.first['gallery_done'] as int? ?? 0;
        q = rows.first['quiz_done'] as int? ?? 0;
        qS = rows.first['quiz_score'] as int?;
        passScore = rows.first['passing_score'] as int? ?? 70;
      }

      int p = passed ? 1 : 0;
      int completedComponents = (h == 1 ? 1 : 0) +
          (c == 1 ? 1 : 0) +
          (g == 1 ? 1 : 0) +
          (q == 1 && (qS ?? 0) >= passScore ? 1 : 0) +
          (p == 1 && intScore >= passScore ? 1 : 0);
      int percent = (completedComponents * 20).clamp(0, 100);
      String status = percent >= 100 ? 'completed' : (percent > 0 ? 'in_progress' : 'not_started');
      int isPassed = percent >= 100 ? 1 : 0;

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
          'quiz_score': qS,
          'practice_score': intScore,
          'passing_score': passScore,
          'is_passed': isPassed,
          'last_accessed_at': now,
          'is_synced': isSynced ? 1 : 0,
        });
      } else {
        await db.update(
          'user_module_progress',
          {
            'status': status,
            'progress_percent': percent,
            'practice_done': p,
            'practice_score': intScore,
            'is_passed': isPassed,
            'last_accessed_at': now,
            if (percent >= 100) 'completed_at': now,
            'is_synced': isSynced ? 1 : 0,
          },
          where: 'user_id = ? AND module_id = ?',
          whereArgs: [userId, moduleId],
        );
      }
    } catch (e) {
      debugPrint('Error savePracticeAttempt: $e');
    }
  }

  Future<List<ScanHistoryModel>> getScanHistories(int? userId, {String? userEmail}) async {
    final db = await database;
    if (db == null) return [];
    try {
      int? effectiveUserId = userId;
      if (userEmail != null && userEmail.trim().isNotEmpty) {
        final u = await db.query(
          'users',
          columns: ['id'],
          where: 'LOWER(email) = ?',
          whereArgs: [userEmail.trim().toLowerCase()],
          limit: 1,
        );
        if (u.isNotEmpty) {
          effectiveUserId = u.first['id'] as int;
        }
      }
      if (effectiveUserId == null) return [];

      final rows = await db.rawQuery('''
        SELECT s.id, s.scan_type, s.confidence, s.fit_score, s.passed, s.created_at, s.image_path, s.module_id,
               COALESCE(b.name, m_b.name, m.title, 'Motif Batik') as motif_name
        FROM scans s
        LEFT JOIN batik_motifs b ON s.top_motif_id = b.id
        LEFT JOIN modules m ON s.module_id = m.id
        LEFT JOIN batik_motifs m_b ON m.motif_id = m_b.id
        WHERE s.user_id = ?
        ORDER BY s.id DESC
      ''', [effectiveUserId]);

      return rows.map((r) {
        final rawScore = (r['fit_score'] ?? r['confidence'] ?? 0.0) as num;
        return ScanHistoryModel(
          id: r['id'] as int,
          scanType: r['scan_type'] as String? ?? 'universal',
          motifName: r['motif_name'] as String?,
          score: rawScore.toDouble(),
          passed: (r['passed'] as int? ?? 0) == 1,
          createdAt: r['created_at'] as String? ?? '',
          imagePath: r['image_path'] as String?,
          moduleId: r['module_id'] as int?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getScanHistories: $e');
      return [];
    }
  }

  /// Ambil riwayat percobaan kuis praktikum dari SQLite lokal
  Future<List<Map<String, dynamic>>> getPracticeAttempts({
    required int userId,
    int? moduleId,
  }) async {
    final db = await database;
    if (db == null) return [];
    try {
      String query = '''
        SELECT s.id, s.scan_type, s.module_id, s.confidence, s.fit_score, s.passed, 
               s.created_at, s.image_path,
               COALESCE(b.name, m_b.name, m.title, 'Batik Praktikum') as motif_name,
               m.title as module_title
        FROM scans s
        LEFT JOIN modules m ON s.module_id = m.id
        LEFT JOIN batik_motifs b ON s.top_motif_id = b.id
        LEFT JOIN batik_motifs m_b ON m.motif_id = m_b.id
        WHERE s.user_id = ? AND (s.scan_type = 'kuismu' OR s.module_id IS NOT NULL)
      ''';
      List<dynamic> args = [userId];
      if (moduleId != null) {
        query += ' AND s.module_id = ?';
        args.add(moduleId);
      }
      query += ' ORDER BY s.id DESC';

      final rows = await db.rawQuery(query, args);
      return rows;
    } catch (e) {
      debugPrint('Error getPracticeAttempts: $e');
      return [];
    }
  }

  /// Cek apakah email terdaftar dalam tabel users
  Future<bool> checkEmailExists(String email) async {
    final clean = email.trim().toLowerCase();
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
      } catch (_) {}
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
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  /// Menambahkan akun pengguna baru ke SQLite lokal
  Future<int> insertUser({
    int? id,
    required String name,
    required String email,
    required String passwordHash,
    String? phone,
    String? profileImagePath,
  }) async {
    final db = await database;
    if (db == null) return -1;
    try {
      final cleanEmail = email.trim().toLowerCase();
      final now = DateTime.now().toIso8601String();
      final data = <String, dynamic>{
        'name': name.trim(),
        'email': cleanEmail,
        'phone': phone?.trim(),
        'password_hash': passwordHash,
        'profile_image_path': profileImagePath,
        'created_at': now,
        'updated_at': now,
      };
      if (id != null) {
        data['id'] = id;
      }

      // Cek apakah user dengan email ini sudah ada di SQLite
      final existing = await db.query(
        'users',
        columns: ['id'],
        where: 'LOWER(email) = ?',
        whereArgs: [cleanEmail],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        await db.update('users', data, where: 'LOWER(email) = ?', whereArgs: [cleanEmail]);
        return id ?? existingId;
      } else {
        final newId = await db.insert(
          'users',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return newId;
      }
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
  Future<List<Map<String, dynamic>>> getUserModuleProgressList(int userId, {String? userEmail}) async {
    final db = await database;
    if (db == null) return [];
    try {
      int effectiveUserId = userId;
      if (userEmail != null && userEmail.trim().isNotEmpty) {
        final u = await db.query(
          'users',
          columns: ['id'],
          where: 'LOWER(email) = ?',
          whereArgs: [userEmail.trim().toLowerCase()],
          limit: 1,
        );
        if (u.isNotEmpty) {
          effectiveUserId = u.first['id'] as int;
        }
      }

      return await db.query(
        'user_module_progress',
        where: 'user_id = ?',
        whereArgs: [effectiveUserId],
        orderBy: 'module_id ASC',
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
    int? quizScore,
    int? practiceScore,
    int passingScore = 70,
    bool isPassed = false,
    bool isSynced = false,
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
          'quiz_score': quizScore,
          'practice_score': practiceScore,
          'passing_score': passingScore,
          'is_passed': isPassed ? 1 : 0,
          'completed_at': progressPercent >= 100 ? now : null,
          'last_accessed_at': now,
          'is_synced': isSynced ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      debugPrint('Info upsert user_module_progress: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MANAJEMEN ANTREAN SINKRONISASI OFFLINE (OFFLINE QUEUE SYNC)
  // Menjamin seluruh aktivitas offline disinkronkan saat online kembali
  // ─────────────────────────────────────────────────────────────────────────

  /// Ambil seluruh riwayat kuis teori yang belum tersinkronkan ke cloud
  Future<List<Map<String, dynamic>>> getUnsyncedQuizAttempts(int userId) async {
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        'quiz_attempts',
        where: 'user_id = ? AND is_synced = 0',
        whereArgs: [userId],
        orderBy: 'id ASC',
      );
    } catch (e) {
      debugPrint('Error getUnsyncedQuizAttempts: $e');
      return [];
    }
  }

  /// Tandai riwayat kuis teori sebagai sudah tersinkronkan
  Future<void> markQuizAttemptSynced(int id) async {
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        'quiz_attempts',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error markQuizAttemptSynced: $e');
    }
  }

  /// Ambil seluruh pindaian/praktikum yang belum tersinkronkan ke cloud
  Future<List<Map<String, dynamic>>> getUnsyncedScans(int userId) async {
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        'scans',
        where: 'user_id = ? AND is_synced = 0',
        whereArgs: [userId],
        orderBy: 'id ASC',
      );
    } catch (e) {
      debugPrint('Error getUnsyncedScans: $e');
      return [];
    }
  }

  /// Tandai pindaian/praktikum sebagai sudah tersinkronkan
  Future<void> markScanSynced(int id) async {
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        'scans',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error markScanSynced: $e');
    }
  }

  /// Ambil progres modul yang belum tersinkronkan ke cloud
  Future<List<Map<String, dynamic>>> getUnsyncedUserModuleProgress(int userId) async {
    final db = await database;
    if (db == null) return [];
    try {
      return await db.query(
        'user_module_progress',
        where: 'user_id = ? AND is_synced = 0',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('Error getUnsyncedUserModuleProgress: $e');
      return [];
    }
  }

  /// Tandai progres modul sebagai sudah tersinkronkan
  Future<void> markUserModuleProgressSynced(int userId, int moduleId) async {
    final db = await database;
    if (db == null) return;
    try {
      await db.update(
        'user_module_progress',
        {'is_synced': 1},
        where: 'user_id = ? AND module_id = ?',
        whereArgs: [userId, moduleId],
      );
    } catch (e) {
      debugPrint('Error markUserModuleProgressSynced: $e');
    }
  }
}
