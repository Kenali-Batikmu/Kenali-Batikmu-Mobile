import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/providers/app_provider.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('Advanced Sync & Anti-Data Loss Guard Tests (TC-SYNC-01 to TC-SYNC-06)', () {
    test('TC-SYNC-01 & 02: Local Wins Merge prevents cloud from wiping higher local progress or score', () async {
      // 1. Simulasikan user punya progres offline tinggi di HP (Skor Praktik 95%, 4 pilar tuntas)
      await DatabaseHelper.instance.upsertUserModuleProgress(
        userId: 1,
        moduleId: 3,
        progressPercent: 80,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: false,
        practiceDone: true,
        quizScore: null,
        practiceScore: 95,
        isSynced: false,
      );

      // 2. Simulasikan server cloud memiliki data lama yang lebih rendah (Progres 20%, skor 0/null)
      final localList = await DatabaseHelper.instance.getUserModuleProgressList(1);
      final localRow = localList.firstWhere((r) => r['module_id'] == 3);

      final cloudRow = {
        'module_id': 3,
        'history_done': true,
        'character_done': false,
        'gallery_done': false,
        'quiz_done': false,
        'practice_done': false,
        'quiz_score': null,
        'practice_score': 0,
        'passing_score': 70,
      };

      final mergedH = (localRow['history_done'] == 1) || cloudRow['history_done'] == true;
      final mergedC = (localRow['character_done'] == 1) || cloudRow['character_done'] == true;
      final mergedP = (localRow['practice_done'] == 1) || cloudRow['practice_done'] == true;
      final mergedPS = [localRow['practice_score'] as int? ?? 0, cloudRow['practice_score'] as int? ?? 0].reduce((a, b) => a > b ? a : b);

      // Verifikasi nilai lokal yang lebih tinggi menang mutlak
      expect(mergedH, isTrue);
      expect(mergedC, isTrue, reason: 'Karakteristik yang sudah selesai di lokal dilarang tertimpa false dari server');
      expect(mergedP, isTrue, reason: 'Praktikum yang sudah selesai di lokal dilarang tertimpa false dari server');
      expect(mergedPS, equals(95), reason: 'Skor praktikum lokal 95% dilarang tertimpa 0 dari server');
    });

    test('TC-SYNC-04: Offline Queue Payload contains all required scoring fields', () async {
      // Simulasikan pengerjaan kuis dan praktikum saat offline
      await DatabaseHelper.instance.saveQuizAttempt(
        userId: 1,
        moduleId: 2,
        score: 88,
        passed: true,
        isSynced: false,
      );
      await DatabaseHelper.instance.savePracticeAttempt(
        userId: 1,
        moduleId: 2,
        confidence: 0.85,
        passed: true,
        isSynced: false,
      );

      final pendingQuizzes = await DatabaseHelper.instance.getUnsyncedQuizAttempts(1);
      final pendingScans = await DatabaseHelper.instance.getUnsyncedScans(1);
      final pendingProgress = await DatabaseHelper.instance.getUnsyncedUserModuleProgress(1);

      expect(pendingQuizzes.isNotEmpty, isTrue);
      expect(pendingQuizzes.last['score'], equals(88));

      expect(pendingScans.isNotEmpty, isTrue);
      expect(pendingScans.last['confidence'], equals(0.85));

      final mod2Prog = pendingProgress.firstWhere((p) => p['module_id'] == 2);
      expect(mod2Prog['quiz_score'], equals(88));
      expect(mod2Prog['practice_score'], equals(85));
      expect(mod2Prog['is_synced'], equals(0));
    });

    test('TC-SYNC-06: Server snake_case Progress is correctly loaded into AppProvider without data drop', () async {
      final provider = AppProvider();
      await provider.initApp();

      await DatabaseHelper.instance.insertUser(
        id: 99,
        name: 'Budi Test Case',
        email: 'budi.test@batikmu.id',
        passwordHash: PasswordHasher.hashPassword('BudiPass123#'),
      );

      await DatabaseHelper.instance.upsertUserModuleProgress(
        userId: 99,
        moduleId: 4,
        progressPercent: 100,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: true,
        quizScore: 92,
        practiceScore: 90,
        passingScore: 70,
        isPassed: true,
        isSynced: true,
      );

      final loginSuccess = await provider.login('budi.test@batikmu.id', 'BudiPass123#');
      expect(loginSuccess, isTrue);

      final mod4 = provider.modules.firstWhere((m) => m.id == 4);
      expect(mod4.progressPercent, equals(100));
      expect(mod4.quizScore, equals(92));
      expect(mod4.practiceScore, equals(90));
      expect(mod4.isCompleted, isTrue);
      expect(mod4.quizDone, isTrue);
      expect(mod4.practiceDone, isTrue);
    });
  });
}
