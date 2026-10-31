import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../models/app_models.dart';

/// Data Access Object (DAO) untuk kurikulum modul pembelajaran, motif batik, dan progres pilar
class ModuleDao {
  final Future<Database?> Function() _getDb;

  ModuleDao(this._getDb);

  /// Ambil seluruh daftar motif batik yang tersimpan di SQLite lokal
  Future<List<BatikMotifModel>> getAllMotifs() async {
    final db = await _getDb();
    if (db == null) return [];
    try {
      final rows = await db.query('batik_motifs', orderBy: 'id ASC');
      return rows.map((r) => BatikMotifModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('ModuleDao getAllMotifs error: $e');
      return [];
    }
  }

  /// Sinkronisasi daftar motif dari cloud ke SQLite lokal (UPSERT)
  Future<int> upsertMotifs(List<Map<String, dynamic>> motifs) async {
    final db = await _getDb();
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
      debugPrint('ModuleDao upsertMotifs error: $e');
      return 0;
    }
  }

  /// Sinkronisasi daftar modul dari cloud ke SQLite lokal (UPSERT)
  Future<int> upsertModules(List<Map<String, dynamic>> modules) async {
    final db = await _getDb();
    if (db == null || modules.isEmpty) return 0;
    try {
      final batch = db.batch();
      const defaultCovers = {
        1: 'assets/images/modules/Batik-Betawi.jpeg',
        2: 'assets/images/modules/Batik-Bokor-Kencono.jpeg',
        3: 'assets/images/modules/Batik-Buketan.jpeg',
        4: 'assets/images/modules/Batik-Dayak.jpeg',
        5: 'assets/images/modules/Batik-Jlamprang.jpeg',
        6: 'assets/images/modules/Batik-Kawung.jpeg',
        7: 'assets/images/modules/Batik-Liong.jpeg',
        8: 'assets/images/modules/Batik-Mega-Mendung.jpeg',
        9: 'assets/images/modules/Batik-Parang.jpeg',
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

      for (var m in modules) {
        final id = m['id'] as int?;
        final cover = (m['cover_image'] != null && (m['cover_image'] as String).isNotEmpty)
            ? m['cover_image']
            : defaultCovers[id];

        batch.insert(
          'modules',
          {
            'id': m['id'],
            'motif_id': m['motif_id'],
            'title': m['title'],
            'description': m['description'],
            'cover_image': cover,
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
      debugPrint('ModuleDao upsertModules error: $e');
      return 0;
    }
  }

  /// Hapus satu motif spesifik (berguna untuk pembersihan uji coba atau sinkronisasi)
  Future<int> deleteMotifById(int id) async {
    final db = await _getDb();
    if (db == null) return 0;
    try {
      return await db.delete('batik_motifs', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('ModuleDao deleteMotifById error: $e');
      return 0;
    }
  }

  /// Ambil seluruh modul beserta progres pengguna (jika userId/userEmail diberikan)
  Future<List<ModuleModel>> getAllModules({int? userId, String? userEmail}) async {
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
      debugPrint('ModuleDao getAllModules error: $e');
      return [];
    }
  }

  /// Ambil konten 3 pilar lengkap untuk satu modul tertentu
  Future<ModuleContentModel?> getModuleContent(int moduleId) async {
    final db = await _getDb();
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
      debugPrint('ModuleDao getModuleContent error: $e');
      return null;
    }
  }

  /// Memperbarui progres baca pilar modul (history, character, atau gallery)
  Future<void> updatePillarProgress(int userId, int moduleId, String pillar) async {
    final db = await _getDb();
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
      debugPrint('ModuleDao updatePillarProgress error: $e');
    }
  }

  /// Ambil seluruh progres modul untuk satu pengguna tertentu
  Future<List<Map<String, dynamic>>> getUserModuleProgressList(int userId, {String? userEmail}) async {
    final db = await _getDb();
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
      debugPrint('ModuleDao getUserModuleProgressList error: $e');
      return [];
    }
  }

  /// Ambil progres satu modul spesifik untuk pengguna
  Future<Map<String, dynamic>?> getUserModuleProgress(int userId, int moduleId) async {
    final db = await _getDb();
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
      debugPrint('ModuleDao getUserModuleProgress error: $e');
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
    final db = await _getDb();
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
      debugPrint('ModuleDao upsertUserModuleProgress error: $e');
      return false;
    }
  }
}
