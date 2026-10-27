import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/supabase_service.dart';
import '../models/app_models.dart';

/// Provider pengelola kurikulum 20 modul belajar, pilar materi, dan progres pembelajaran
class ModuleProvider with ChangeNotifier {
  List<ModuleModel> _modules = [];
  List<BatikMotifModel> _motifs = [];

  List<ModuleModel> get modules => _modules;
  List<BatikMotifModel> get motifs => _motifs;

  int get completedModulesCount => _modules.where((m) => m.progressPercent >= 100).length;
  int get totalModulesCount => _modules.length;
  int get overallProgressPercent => totalModulesCount > 0 ? ((completedModulesCount / totalModulesCount) * 100).round() : 0;

  void setModules(List<ModuleModel> mods) {
    _modules = mods;
    notifyListeners();
  }

  void setMotifs(List<BatikMotifModel> m) {
    _motifs = m;
    notifyListeners();
  }

  /// Muat daftar motif dan modul dari SQLite lokal
  Future<void> loadMasterData({int? userId, String? userEmail}) async {
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      final dbMotifs = await DatabaseHelper.instance.getAllMotifs();
      if (dbMotifs.isNotEmpty) {
        _motifs = dbMotifs;
      }

      final dbModules = await DatabaseHelper.instance.getAllModules(
        userId: userId,
        userEmail: userEmail,
      );
      if (dbModules.isNotEmpty) {
        _modules = dbModules;
      }
      notifyListeners();
    }
  }

  /// Reset progres seluruh modul di memori ke kondisi awal (0%) saat logout/ganti user
  void resetModuleProgressInMemory() {
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
    notifyListeners();
  }

  /// Memuat progres modul khusus untuk user tertentu (berdasarkan email & SQLite)
  Future<void> loadUserModuleProgress(String email, {int? userId}) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final effectiveUserId = userId ?? 1;

      Map<int, Map<String, dynamic>> sqliteProgressMap = {};
      final list = await DatabaseHelper.instance.getUserModuleProgressList(effectiveUserId, userEmail: cleanEmail);
      for (final row in list) {
        final mId = row['module_id'] as int;
        sqliteProgressMap[mId] = row;
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

        if (sqlRow != null) {
          h = (sqlRow['history_done'] as int? ?? 0) == 1;
          c = (sqlRow['character_done'] as int? ?? 0) == 1;
          g = (sqlRow['gallery_done'] as int? ?? 0) == 1;
          q = (sqlRow['quiz_done'] as int? ?? 0) == 1;
          p = (sqlRow['practice_done'] as int? ?? 0) == 1;
          qS = sqlRow['quiz_score'] as int?;
          pS = sqlRow['practice_score'] as int?;

          final userKeyPrefix = 'user_${cleanEmail}_module_$mId';
          await prefs.setBool('${userKeyPrefix}_history', h);
          await prefs.setBool('${userKeyPrefix}_character', c);
          await prefs.setBool('${userKeyPrefix}_gallery', g);
          await prefs.setBool('${userKeyPrefix}_quiz', q);
          await prefs.setBool('${userKeyPrefix}_practice', p);
          if (qS != null) await prefs.setInt('${userKeyPrefix}_quizScore', qS);
          if (pS != null) await prefs.setInt('${userKeyPrefix}_practiceScore', pS);
        } else {
          final userKeyPrefix = 'user_${cleanEmail}_module_$mId';
          h = prefs.getBool('${userKeyPrefix}_history');
          c = prefs.getBool('${userKeyPrefix}_character');
          g = prefs.getBool('${userKeyPrefix}_gallery');
          q = prefs.getBool('${userKeyPrefix}_quiz');
          p = prefs.getBool('${userKeyPrefix}_practice');
          qS = prefs.getInt('${userKeyPrefix}_quizScore');
          pS = prefs.getInt('${userKeyPrefix}_practiceScore');
        }

        final tempMod = _modules[i].copyWith(
          historyDone: h ?? false,
          characterDone: c ?? false,
          galleryDone: g ?? false,
          quizDone: q ?? false,
          practiceDone: p ?? false,
          quizScore: qS,
          practiceScore: pS,
        );
        final computedPercent = tempMod.calculateProgressPercent();
        _modules[i] = tempMod.copyWith(progressPercent: computedPercent);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Dipanggil dari ModuleDetailScreen saat user menyelesaikan satu page/pillar
  Future<void> updatePillarProgress(
    int moduleId,
    String pillar, {
    required int userId,
    required String? userEmail,
  }) async {
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

      final tempMod = old.copyWith(
        historyDone: h,
        characterDone: c,
        galleryDone: g,
      );
      final int percent = tempMod.calculateProgressPercent();
      final bool isPassed = tempMod.isCompleted;

      _modules[index] = tempMod.copyWith(progressPercent: percent);
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        final userKey = userEmail?.trim().toLowerCase() ?? 'guest';
        final userKeyPrefix = 'user_${userKey}_module_$moduleId';
        await prefs.setInt('${userKeyPrefix}_progress', percent);
        await prefs.setBool('${userKeyPrefix}_history', h);
        await prefs.setBool('${userKeyPrefix}_character', c);
        await prefs.setBool('${userKeyPrefix}_gallery', g);
        await prefs.setBool('${userKeyPrefix}_quiz', q);
        await prefs.setBool('${userKeyPrefix}_practice', p);

        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: h,
          characterDone: c,
          galleryDone: g,
          quizDone: q,
          practiceDone: p,
          quizScore: old.quizScore,
          practiceScore: old.practiceScore,
          passingScore: old.passingScore,
          isPassed: isPassed,
        );

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
            quizScore: old.quizScore,
            practiceScore: old.practiceScore,
            passingScore: old.passingScore,
            isPassed: isPassed,
          ).then((success) {
            if (success) {
              DatabaseHelper.instance.markUserModuleProgressSynced(userId, moduleId);
            }
          }).catchError((e) {
            debugPrint('Cloud sync pillar fallback: $e');
          });
        }
      } catch (_) {}
    }
  }

  /// Memperbarui skor kuis pada modul in-memory
  void updateModuleQuizResult(int moduleId, int score, bool passed) {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      final existingScore = old.quizScore ?? 0;
      final bestScore = score > existingScore ? score : existingScore;
      final tempMod = old.copyWith(
        quizDone: true,
        quizScore: bestScore,
      );
      final int percent = tempMod.calculateProgressPercent();
      _modules[index] = tempMod.copyWith(progressPercent: percent);
      notifyListeners();
    }
  }

  /// Memperbarui skor praktikum pada modul in-memory
  void updateModulePracticeResult(int moduleId, int intScore, bool passed) {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      final tempMod = old.copyWith(
        practiceDone: passed,
        practiceScore: intScore,
      );
      final int percent = tempMod.calculateProgressPercent();
      _modules[index] = tempMod.copyWith(progressPercent: percent);
      notifyListeners();
    }
  }
}
