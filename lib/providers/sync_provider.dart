import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../core/services/supabase_service.dart';
import '../models/app_models.dart';

/// Provider pengelola sinkronisasi data awan (Supabase), antrean offline, dan pendengar koneksi jaringan
class SyncProvider with ChangeNotifier {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOffline = false;

  void setupConnectivityListener(Future<void> Function() onReconnect) {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final isOffline = results.every((r) => r == ConnectivityResult.none);
      if (_wasOffline && !isOffline) {
        debugPrint('SyncProvider: Sinyal internet aktif kembali, memicu background sync antrean offline...');
        await onReconnect();
      }
      _wasOffline = isOffline;
    });
  }

  void disposeListener() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Sinkronkan master data (motif dan modul) dari Cloud Supabase ke SQLite lokal
  Future<bool> syncMasterDataFromCloud({
    required Function(List<BatikMotifModel> motifs, List<ModuleModel> modules) onMasterDataUpdated,
    int? userId,
    String? userEmail,
  }) async {
    if (!SupabaseService.instance.isReady) return false;
    try {
      final cloudMotifs = await SupabaseService.instance.fetchMotifs();
      if (cloudMotifs.isNotEmpty) {
        await DatabaseHelper.instance.upsertMotifs(cloudMotifs);
      }

      final cloudModules = await SupabaseService.instance.fetchModules();
      if (cloudModules.isNotEmpty) {
        await DatabaseHelper.instance.upsertModules(cloudModules);
      }

      final updatedMotifs = await DatabaseHelper.instance.getAllMotifs();
      final updatedModules = await DatabaseHelper.instance.getAllModules(
        userId: userId,
        userEmail: userEmail,
      );

      onMasterDataUpdated(updatedMotifs, updatedModules);
      debugPrint('SyncProvider: Berhasil sinkronisasi master data (${cloudMotifs.length} motif, ${cloudModules.length} modul)');
      return true;
    } catch (e) {
      debugPrint('SyncProvider syncMasterDataFromCloud error: $e');
      return false;
    }
  }

  /// Sinkronkan progres modul, riwayat praktikum, dan kuis dari Cloud Supabase ke SQLite lokal (Server-First)
  Future<bool> syncUserProgressFromServer({
    required UserModel currentUser,
    required Future<void> Function(String email) onReloadProgress,
    required Function(List<ScanHistoryModel> updatedHistories) onHistoriesUpdated,
  }) async {
    if (!SupabaseService.instance.isReady) return false;

    final userId = currentUser.id;
    final userEmail = currentUser.email;

    try {
      // 1. Tarik seluruh progres modul dari Supabase
      final cloudProgressList = await SupabaseService.instance.fetchUserModuleProgress(userEmail);
      if (cloudProgressList.isNotEmpty) {
        final localList = await DatabaseHelper.instance.getUserModuleProgressList(userId, userEmail: userEmail);
        final Map<int, Map<String, dynamic>> localMap = {
          for (final r in localList) r['module_id'] as int: r
        };

        for (final row in cloudProgressList) {
          final mId = row['module_id'] as int? ?? 0;
          if (mId <= 0) continue;

          final localRow = localMap[mId];
          final localH = (localRow?['history_done'] as int? ?? 0) == 1;
          final localC = (localRow?['character_done'] as int? ?? 0) == 1;
          final localG = (localRow?['gallery_done'] as int? ?? 0) == 1;
          final localQ = (localRow?['quiz_done'] as int? ?? 0) == 1;
          final localP = (localRow?['practice_done'] as int? ?? 0) == 1;
          final localQS = localRow?['quiz_score'] as int?;
          final localPS = localRow?['practice_score'] as int?;

          // Local Wins Merge: Nilai lokal yang lebih tinggi menang mutlak
          final h = localH || row['history_done'] == true;
          final c = localC || row['character_done'] == true;
          final g = localG || row['gallery_done'] == true;
          final q = localQ || row['quiz_done'] == true;
          final p = localP || row['practice_done'] == true;
          final int? qS = max(localQS ?? 0, row['quiz_score'] as int? ?? 0) > 0 ? max(localQS ?? 0, row['quiz_score'] as int? ?? 0) : null;
          final int? pS = max(localPS ?? 0, row['practice_score'] as int? ?? 0) > 0 ? max(localPS ?? 0, row['practice_score'] as int? ?? 0) : null;
          final passScore = row['passing_score'] as int? ?? 70;

          final int completedComponents = (h ? 1 : 0) +
              (c ? 1 : 0) +
              (g ? 1 : 0) +
              (q && (qS ?? 0) >= passScore ? 1 : 0) +
              (p && (pS ?? 0) >= passScore ? 1 : 0);
          final percent = (completedComponents * 20).clamp(0, 100);
          final isPass = percent >= 100;

          await DatabaseHelper.instance.upsertUserModuleProgress(
            userId: userId,
            moduleId: mId,
            progressPercent: percent,
            historyDone: h,
            characterDone: c,
            galleryDone: g,
            quizDone: q,
            practiceDone: p,
            quizScore: qS,
            practiceScore: pS,
            passingScore: passScore,
            isPassed: isPass,
            isSynced: true,
          );
        }
      }

      // 2. Tarik riwayat praktikum dari tabel scans Supabase
      final cloudPracticeScans = await SupabaseService.instance.fetchPracticeScans(userEmail);
      if (cloudPracticeScans.isNotEmpty) {
        for (final scan in cloudPracticeScans) {
          final mId = scan['module_id'] as int? ?? 1;
          final conf = (scan['confidence'] as num? ?? 0.70).toDouble();
          final passed = scan['passed'] == true;
          final imgUrl = scan['image_path'] as String?;

          await DatabaseHelper.instance.savePracticeAttempt(
            userId: userId,
            moduleId: mId,
            confidence: conf,
            passed: passed,
            imagePath: imgUrl,
            isSynced: true,
          );
        }
      }

      // 3. Muat ulang progres dan riwayat lokal
      await onReloadProgress(userEmail);
      final updatedHistories = await DatabaseHelper.instance.getScanHistories(userId, userEmail: userEmail);
      if (updatedHistories.isNotEmpty) {
        onHistoriesUpdated(updatedHistories);
      }

      debugPrint('SyncProvider: Progres pengguna ($userEmail) berhasil disinkronkan dari Cloud');
      return true;
    } catch (e) {
      debugPrint('SyncProvider syncUserProgressFromServer error: $e');
      return false;
    }
  }

  /// Memproses antrean sinkronisasi riwayat pindaian dan kuis offline ke Cloud Supabase
  Future<int> processOfflineQueue({required UserModel currentUser}) async {
    if (!SupabaseService.instance.isReady) return 0;

    final userId = currentUser.id;
    final userEmail = currentUser.email;
    int syncedCount = 0;

    try {
      // 1. Sinkronkan riwayat kuis teori yang belum tersinkronkan
      final pendingQuizzes = await DatabaseHelper.instance.getUnsyncedQuizAttempts(userId);
      for (var q in pendingQuizzes) {
        final success = await SupabaseService.instance.saveQuizAttempt(
          userEmail: userEmail,
          moduleId: q['module_id'] as int,
          score: q['score'] as int,
          passed: (q['passed'] as int) == 1,
        );
        if (success) {
          await DatabaseHelper.instance.markQuizAttemptSynced(q['id'] as int);
          syncedCount++;
        }
      }

      // 2. Sinkronkan riwayat pindaian/praktikum yang belum tersinkronkan
      final pendingScans = await DatabaseHelper.instance.getUnsyncedScans(userId);
      for (var s in pendingScans) {
        final success = await SupabaseService.instance.savePracticeScan(
          userEmail: userEmail,
          moduleId: s['module_id'] as int? ?? 1,
          confidence: (s['confidence'] as num? ?? 0.0).toDouble(),
          passed: (s['passed'] as int? ?? 0) == 1,
          imageUrl: s['image_path'] as String?,
        );
        if (success) {
          await DatabaseHelper.instance.markScanSynced(s['id'] as int);
          syncedCount++;
        }
      }

      // 3. Sinkronkan progres modul yang belum tersinkronkan
      final pendingProgress = await DatabaseHelper.instance.getUnsyncedUserModuleProgress(userId);
      for (var p in pendingProgress) {
        final success = await SupabaseService.instance.syncUserModuleProgress(
          userEmail: userEmail,
          moduleId: p['module_id'] as int,
          progressPercent: p['progress_percent'] as int,
          historyDone: (p['history_done'] as int) == 1,
          characterDone: (p['character_done'] as int) == 1,
          galleryDone: (p['gallery_done'] as int) == 1,
          quizDone: (p['quiz_done'] as int) == 1,
          practiceDone: (p['practice_done'] as int) == 1,
          quizScore: p['quiz_score'] as int?,
          practiceScore: p['practice_score'] as int?,
          passingScore: p['passing_score'] as int? ?? 70,
          isPassed: (p['is_passed'] as int? ?? 0) == 1,
        );
        if (success) {
          await DatabaseHelper.instance.markUserModuleProgressSynced(userId, p['module_id'] as int);
          syncedCount++;
        }
      }

      if (syncedCount > 0) {
        debugPrint('SyncProvider: Berhasil memproses $syncedCount rekaman antrean offline ke Supabase');
      }
    } catch (e) {
      debugPrint('SyncProvider processOfflineQueue error: $e');
    }

    return syncedCount;
  }
}
