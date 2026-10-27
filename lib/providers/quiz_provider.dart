import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/supabase_service.dart';
import '../models/app_models.dart';

/// Provider pengelola kuis teori, pindaian praktikum AI, dan riwayat pindaian
class QuizProvider with ChangeNotifier {
  List<ScanHistoryModel> _scanHistories = [];

  List<ScanHistoryModel> get scanHistories => _scanHistories;
  int get scannedMotifsCount => _scanHistories.length;

  void setScanHistories(List<ScanHistoryModel> histories) {
    _scanHistories = histories;
    notifyListeners();
  }

  void clearHistories() {
    _scanHistories = [];
    notifyListeners();
  }

  /// Memuat riwayat pindaian dari SQLite lokal
  Future<void> loadScanHistories(int? userId, {String? userEmail}) async {
    try {
      final histories = await DatabaseHelper.instance.getScanHistories(
        userId,
        userEmail: userEmail,
      );
      _scanHistories = histories;
      notifyListeners();
    } catch (e) {
      debugPrint('QuizProvider loadScanHistories error: $e');
    }
  }

  /// Simpan hasil kuis pilihan ganda ke SQLite lokal dan sinkronkan ke Supabase
  Future<void> saveQuizResult({
    required int moduleId,
    required int score,
    required bool passed,
    required int userId,
    required String? userEmail,
    required ModuleModel? module,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = userEmail?.trim().toLowerCase() ?? 'guest';
      final userKeyPrefix = 'user_${userKey}_module_$moduleId';
      await prefs.setBool('${userKeyPrefix}_quiz', true);
      await prefs.setInt('${userKeyPrefix}_quizScore', score);

      await prefs.setBool('module_${moduleId}_quiz', true);
      await prefs.setInt('module_${moduleId}_quizScore', score);

      final existingScore = module?.quizScore ?? 0;
      final bestScore = score > existingScore ? score : existingScore;

      if (module != null) {
        final tempMod = module.copyWith(
          quizDone: true,
          quizScore: bestScore,
        );
        final int percent = tempMod.calculateProgressPercent();
        final bool isPassed = tempMod.isCompleted;

        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: module.historyDone,
          characterDone: module.characterDone,
          galleryDone: module.galleryDone,
          quizDone: true,
          practiceDone: module.practiceDone,
          quizScore: bestScore,
          practiceScore: module.practiceScore,
          passingScore: module.passingScore,
          isPassed: isPassed,
        );
      }

      await DatabaseHelper.instance.saveQuizAttempt(
        userId: userId,
        moduleId: moduleId,
        score: score,
        passed: passed,
        totalQuestions: 10,
      );

      if (userEmail != null) {
        SupabaseService.instance.saveQuizAttempt(
          userEmail: userEmail,
          moduleId: moduleId,
          score: score,
          passed: passed,
        ).then((success) {
          if (success) {
            DatabaseHelper.instance.getUnsyncedQuizAttempts(userId, userEmail: userEmail).then((list) {
              if (list.isNotEmpty) {
                DatabaseHelper.instance.markQuizAttemptSynced(list.last['id'] as int);
              }
            }).catchError((_) {});
          }
        }).catchError((e) {
          debugPrint('Cloud sync quiz attempt fallback: $e');
        });

        if (module != null) {
          final tempMod = module.copyWith(
            quizDone: true,
            quizScore: bestScore,
          );
          final int percent = tempMod.calculateProgressPercent();
          final bool isPassed = tempMod.isCompleted;

          SupabaseService.instance.syncUserModuleProgress(
            userEmail: userEmail,
            moduleId: moduleId,
            progressPercent: percent,
            historyDone: module.historyDone,
            characterDone: module.characterDone,
            galleryDone: module.galleryDone,
            quizDone: true,
            practiceDone: module.practiceDone,
            quizScore: bestScore,
            practiceScore: module.practiceScore,
            passingScore: module.passingScore,
            isPassed: isPassed,
          ).then((success) {
            if (success) {
              DatabaseHelper.instance.markUserModuleProgressSynced(userId, moduleId);
            }
          }).catchError((e) {
            debugPrint('Cloud sync quiz progress fallback: $e');
          });
        }
      }
    } catch (e) {
      debugPrint('QuizProvider saveQuizResult error: $e');
    }
  }

  /// Simpan hasil evaluasi praktikum AI membatik (1 rekaman per modul)
  Future<void> savePracticeResult({
    required int moduleId,
    required double fitScore,
    required bool passed,
    required int userId,
    required String? userEmail,
    required ModuleModel? module,
    String? imagePath,
  }) async {
    final int intScore = (fitScore > 1.0 ? fitScore : fitScore * 100).round().clamp(0, 100);
    final double normalizedScore = intScore / 100.0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = userEmail?.trim().toLowerCase() ?? 'guest';
      final userKeyPrefix = 'user_${userKey}_module_$moduleId';
      await prefs.setBool('${userKeyPrefix}_practice', passed);
      await prefs.setInt('${userKeyPrefix}_practiceScore', intScore);

      await prefs.setBool('module_${moduleId}_practice', passed);
      await prefs.setInt('module_${moduleId}_practiceScore', intScore);

      if (module != null) {
        final tempMod = module.copyWith(
          practiceDone: passed,
          practiceScore: intScore,
        );
        final int percent = tempMod.calculateProgressPercent();
        final bool isPassed = tempMod.isCompleted;

        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: module.historyDone,
          characterDone: module.characterDone,
          galleryDone: module.galleryDone,
          quizDone: module.quizDone,
          practiceDone: passed,
          quizScore: module.quizScore,
          practiceScore: intScore,
          passingScore: module.passingScore,
          isPassed: isPassed,
        );
      }

      await DatabaseHelper.instance.savePracticeAttempt(
        userId: userId,
        moduleId: moduleId,
        topMotifId: module?.motifId,
        confidence: normalizedScore,
        passed: passed,
        imagePath: imagePath,
      );

      final updatedHistories = await DatabaseHelper.instance.getScanHistories(userId, userEmail: userEmail);
      if (updatedHistories.isNotEmpty) {
        _scanHistories = updatedHistories;
      } else {
        _scanHistories.removeWhere((s) => s.moduleId == moduleId && s.scanType == 'kuismu');
        _scanHistories.insert(
          0,
          ScanHistoryModel(
            id: DateTime.now().millisecondsSinceEpoch,
            scanType: 'kuismu',
            motifName: module?.title.replaceAll('\n', ' ') ?? 'Batik Praktikum',
            score: normalizedScore,
            passed: passed,
            createdAt: 'Baru saja',
            imagePath: imagePath,
            moduleId: moduleId,
          ),
        );
      }
      notifyListeners();

      if (userEmail != null) {
        if (imagePath != null && imagePath.isNotEmpty) {
          SupabaseService.instance.uploadPracticeImage(
            filePath: imagePath,
            email: userEmail,
            moduleId: moduleId,
          ).then((publicUrl) {
            SupabaseService.instance.savePracticeScan(
              userEmail: userEmail,
              moduleId: moduleId,
              confidence: normalizedScore,
              passed: passed,
              imageUrl: publicUrl,
            ).then((success) {
              if (success) {
                DatabaseHelper.instance.getUnsyncedScans(userId).then((list) {
                  if (list.isNotEmpty) {
                    DatabaseHelper.instance.markScanSynced(list.last['id'] as int);
                  }
                }).catchError((_) {});
              }
            }).catchError((e) {
              debugPrint('Cloud sync practice scan fallback: $e');
            });
          }).catchError((_) {
            SupabaseService.instance.savePracticeScan(
              userEmail: userEmail,
              moduleId: moduleId,
              confidence: normalizedScore,
              passed: passed,
              imageUrl: null,
            ).then((success) {
              if (success) {
                DatabaseHelper.instance.getUnsyncedScans(userId).then((list) {
                  if (list.isNotEmpty) {
                    DatabaseHelper.instance.markScanSynced(list.last['id'] as int);
                  }
                }).catchError((_) {});
              }
            }).catchError((e) {
              debugPrint('Cloud sync practice scan fallback: $e');
            });
          });
        } else {
          SupabaseService.instance.savePracticeScan(
            userEmail: userEmail,
            moduleId: moduleId,
            confidence: normalizedScore,
            passed: passed,
            imageUrl: null,
          ).then((success) {
            if (success) {
              DatabaseHelper.instance.getUnsyncedScans(userId).then((list) {
                if (list.isNotEmpty) {
                  DatabaseHelper.instance.markScanSynced(list.last['id'] as int);
                }
              }).catchError((_) {});
            }
          }).catchError((e) {
            debugPrint('Cloud sync practice scan fallback: $e');
          });
        }

        if (module != null) {
          final tempMod = module.copyWith(
            practiceDone: passed,
            practiceScore: intScore,
          );
          final int percent = tempMod.calculateProgressPercent();
          final bool isPassed = tempMod.isCompleted;

          SupabaseService.instance.syncUserModuleProgress(
            userEmail: userEmail,
            moduleId: moduleId,
            progressPercent: percent,
            historyDone: module.historyDone,
            characterDone: module.characterDone,
            galleryDone: module.galleryDone,
            quizDone: module.quizDone,
            practiceDone: passed,
            quizScore: module.quizScore,
            practiceScore: intScore,
            passingScore: module.passingScore,
            isPassed: isPassed,
          ).then((success) {
            if (success) {
              DatabaseHelper.instance.markUserModuleProgressSynced(userId, moduleId);
            }
          }).catchError((e) {
            debugPrint('Cloud sync practice progress fallback: $e');
          });
        }
      }
    } catch (_) {
      _scanHistories.removeWhere((s) => s.moduleId == moduleId && s.scanType == 'kuismu');
      _scanHistories.insert(
        0,
        ScanHistoryModel(
          id: DateTime.now().millisecondsSinceEpoch,
          scanType: 'kuismu',
          motifName: module?.title.replaceAll('\n', ' ') ?? 'Batik Praktikum',
          score: normalizedScore,
          passed: passed,
          createdAt: 'Baru saja',
          imagePath: imagePath,
          moduleId: moduleId,
        ),
      );
      notifyListeners();
    }
  }

  /// Mengambil riwayat percobaan praktikum dari SQLite lokal
  Future<List<Map<String, dynamic>>> getPracticeAttempts(int moduleId, {int? userId}) async {
    final effectiveUserId = userId ?? 1;
    return await DatabaseHelper.instance.getPracticeAttempts(userId: effectiveUserId, moduleId: moduleId);
  }

  /// Menambahkan riwayat hasil pindaian universal
  void addUniversalScanResult({required String motifName, required double confidence}) {
    _scanHistories.insert(
      0,
      ScanHistoryModel(
        id: DateTime.now().millisecondsSinceEpoch,
        scanType: 'universal',
        motifName: motifName,
        score: confidence,
        passed: confidence >= 0.70,
        createdAt: 'Baru saja',
      ),
    );
    notifyListeners();
  }
}
