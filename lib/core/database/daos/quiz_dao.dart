import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../models/app_models.dart';
import '../../services/supabase_service.dart';

/// Data Access Object (DAO) untuk kuis teori, pindaian kuis praktikum AI, dan riwayat penilaian
class QuizDao {
  final Future<Database?> Function() _getDb;

  QuizDao(this._getDb);

  /// Ambil butir soal kuis pilihan ganda berdasarkan modul (default 10 soal acak dari 25 bank soal)
  Future<List<QuizQuestionModel>> getQuizQuestions(int moduleId, {int limit = 10, bool shuffle = true}) async {
    final db = await _getDb();
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
        debugPrint('QuizDao getQuizQuestions SQLite error: $e');
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
        debugPrint('QuizDao getQuizQuestions Supabase fallback error: $e');
      }
    }

    return [];
  }

  /// Simpan hasil pengerjaan kuis teori dan sinkronkan dengan progres kelulusan modul
  Future<void> saveQuizAttempt({
    required int userId,
    required int moduleId,
    required int score,
    required bool passed,
    int totalQuestions = 10,
    bool isSynced = false,
  }) async {
    final db = await _getDb();
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
      debugPrint('QuizDao saveQuizAttempt error: $e');
    }
  }

  /// Simpan hasil evaluasi praktikum AI membatik (1 rekaman per modul: menimpa pindaian lama)
  Future<void> savePracticeAttempt({
    required int userId,
    required int moduleId,
    int? topMotifId,
    required double confidence,
    required bool passed,
    String? imagePath,
    bool isSynced = false,
  }) async {
    final db = await _getDb();
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
      debugPrint('QuizDao savePracticeAttempt error: $e');
    }
  }

  /// Ambil riwayat seluruh pindaian (Universal scan dan kuis praktikum)
  Future<List<ScanHistoryModel>> getScanHistories(int? userId, {String? userEmail}) async {
    final db = await _getDb();
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
      debugPrint('QuizDao getScanHistories error: $e');
      return [];
    }
  }

  /// Ambil riwayat percobaan kuis praktikum dari SQLite lokal
  Future<List<Map<String, dynamic>>> getPracticeAttempts({
    required int userId,
    int? moduleId,
  }) async {
    final db = await _getDb();
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
      debugPrint('QuizDao getPracticeAttempts error: $e');
      return [];
    }
  }
}
