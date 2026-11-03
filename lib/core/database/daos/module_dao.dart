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
      const defaultCovers = {
        1: 'assets/images/batik/betawi_cover.jpg',
        2: 'assets/images/batik/bokor_kencono_cover.jpg',
        3: 'assets/images/batik/buketan_cover.jpg',
        4: 'assets/images/batik/dayak_cover.jpg',
        5: 'assets/images/batik/jlamprang_cover.jpg',
        6: 'assets/images/batik/kawung_cover.jpg',
        7: 'assets/images/batik/liong_cover.jpg',
        8: 'assets/images/batik/mega_mendung_cover.jpg',
        9: 'assets/images/batik/parang_cover.jpg',
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

      final existingRows = await db.query('modules');
      final existingById = <int, Map<String, Object?>>{
        for (final row in existingRows) (row['id'] as int): row,
      };

      String? nonEmpty(dynamic value) {
        final text = value?.toString().trim() ?? '';
        return text.isEmpty ? null : text;
      }

      for (var m in modules) {
        final id = m['id'] as int?;
        if (id == null) continue;
        final existing = existingById[id];

        // Data kurasi lokal (judul, deskripsi, cover, video) tidak boleh
        // ditimpa oleh cloud yang masih kosong/basi. Cloud hanya dipakai
        // untuk modul yang belum ada di perangkat.
        if (existing != null) {
          final incomingScore = m['passing_score'];
          if (incomingScore is int && incomingScore != existing['passing_score']) {
            await db.update(
              'modules',
              {'passing_score': incomingScore},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
          continue;
        }

        final incomingVideo = nonEmpty(m['video_url']);
        final incomingCover = nonEmpty(m['cover_image']);
        final title = nonEmpty(m['title']) ?? 'Modul $id';
        final description = nonEmpty(m['description']) ?? '';

        await db.insert(
          'modules',
          {
            'id': id,
            'motif_id': m['motif_id'] ?? id,
            'title': title,
            'description': description,
            'cover_image': incomingCover ?? defaultCovers[id],
            'video_url': incomingVideo,
            'passing_score': m['passing_score'] ?? 70,
            'order_no': m['order_no'] ?? id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
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

      final videoRows = await db.query(
        'modules',
        columns: ['video_url', 'cover_image'],
        where: 'id = ?',
        whereArgs: [moduleId],
        limit: 1,
      );
      final videoUrl = videoRows.isNotEmpty
          ? (videoRows.first['video_url'] as String? ?? '').trim()
          : '';
      final coverImage = videoRows.isNotEmpty
          ? (videoRows.first['cover_image'] as String? ?? '').trim()
          : '';

      final contents = await db.query(
        'module_contents',
        where: 'module_id = ?',
        whereArgs: [moduleId],
        orderBy: 'order_no ASC',
      );

      final sejarahRows = contents.where((c) => c['pillar'] == 'sejarah_filosofi').toList();
      final karakterRows = contents.where((c) => c['pillar'] == 'karakteristik').toList();
      final sumberRujukan = <String>[];
      for (final row in sejarahRows) {
        if (((row['title'] as String?) ?? '').trim() == 'Sumber & Rujukan') {
          sumberRujukan.addAll(
            (((row['body'] as String?) ?? '')
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty))
                .toList(),
          );
        }
      }

      String bodyAt(List<Map<String, Object?>> rows, int index) {
        if (index < rows.length) return (rows[index]['body'] as String?) ?? '';
        return '';
      }

      String sejarahByTitle(String title, int index) {
        for (final row in sejarahRows) {
          if (((row['title'] as String?) ?? '').trim() == title) {
            return (row['body'] as String?) ?? '';
          }
        }
        return bodyAt(sejarahRows, index);
      }

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
          GaleriModel(
            imageUrl: coverImage,
            caption: 'Kain Batik $motifName',
          ),
        ];
      }

      String fallbackImageAt(int position) {
        if (galeri.length > position && galeri[position].imageUrl.isNotEmpty) {
          return galeri[position].imageUrl;
        }
        return coverImage;
      }

      KarakteristikDetailModel detailAt(int index, String defaultTitle, String defaultBadge) {
        if (index < karakterRows.length) {
          final row = karakterRows[index];
          final storedImage = ((row['image_url'] as String?) ?? '').trim();
          return KarakteristikDetailModel(
            title: (row['title'] as String?) ?? defaultTitle,
            desc: (row['body'] as String?) ?? '',
            badge: ((row['badge'] as String?) ?? '').trim().isEmpty
                ? defaultBadge
                : (row['badge'] as String).trim(),
            image: storedImage.isNotEmpty ? storedImage : fallbackImageAt(index),
          );
        }
        return KarakteristikDetailModel(
          title: defaultTitle,
          desc: '',
          badge: defaultBadge,
          image: fallbackImageAt(index),
        );
      }

      final pakemList = <PakemModel>[
        for (final row in karakterRows.skip(4))
          PakemModel(
            title: (row['title'] as String?) ?? '',
            desc: (row['body'] as String?) ?? '',
          ),
      ];

      final sejarahBody = sejarahByTitle('Hakikat & Simbol', 0);

      return ModuleContentModel(
        origin: origin,
        sejarahDanFilosofi: SejarahFilosofiModel(
          youtubeUrl: videoUrl,
          deskripsiUtama: sejarahBody.isNotEmpty
              ? sejarahBody
              : 'Pelajari sejarah dan nilai luhur yang terkandung dalam motif $motifName.',
          asalDaerah: sejarahByTitle('Asal Daerah & Sejarah', 1).isNotEmpty
              ? sejarahByTitle('Asal Daerah & Sejarah', 1)
              : origin,
          maknaFilosofis: sejarahByTitle('Makna Filosofis Simbolik', 2).isNotEmpty
              ? sejarahByTitle('Makna Filosofis Simbolik', 2)
              : 'Mengajarkan nilai kesabaran, keluhuran budi, dan harmoni dengan alam.',
          penggunaan: sejarahByTitle('Penggunaan Tradisional & Pakem', 3).isNotEmpty
              ? sejarahByTitle('Penggunaan Tradisional & Pakem', 3)
              : 'Dikenakan dalam upacara adat tradisi, perayaan resmi, maupun busana kontemporer.',
        ),
        karakteristik: KarakteristikModel(
          deskripsi: bodyAt(karakterRows, 0).isNotEmpty
              ? bodyAt(karakterRows, 0)
              : 'Karakteristik khas motif $motifName dengan sapuan canting presisi.',
          strukturUtama: detailAt(1, 'Struktur Utama Motif', 'Struktur Utama'),
          ornamen: detailAt(2, 'Isen-isen Tradisional', 'Isen-Isen'),
          warna: detailAt(3, 'Pewarnaan Khas', 'Pewarnaan'),
          pakemList: pakemList,
        ),
        galeri: galeri,
        sumberRujukan: sumberRujukan,
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
