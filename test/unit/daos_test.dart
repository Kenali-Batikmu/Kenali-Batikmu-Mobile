import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/database/database_helper.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('Phase 2 DAO Architecture & Isolation Tests (TC-DAO-01 to TC-DAO-04)', () {
    test('TC-DAO-01: UserDao correctly manages accounts and queries', () async {
      final exists = await DatabaseHelper.instance.userDao.checkEmailExists('sekar@batikmu.id');
      expect(exists, isTrue);

      final user = await DatabaseHelper.instance.userDao.getUserByEmail('sekar@batikmu.id');
      expect(user, isNotNull);
      expect(user!['name'], equals('Sekar Ayu Kinanti'));
    });

    test('TC-DAO-02: ModuleDao loads motifs, modules, and 3-pillar content', () async {
      final motifs = await DatabaseHelper.instance.moduleDao.getAllMotifs();
      expect(motifs.length, equals(20));

      final modules = await DatabaseHelper.instance.moduleDao.getAllModules();
      expect(modules.length, equals(20));

      final content = await DatabaseHelper.instance.moduleDao.getModuleContent(1);
      expect(content, isNotNull);
      expect(content!.sejarahDanFilosofi.deskripsiUtama, isNotEmpty);
    });

    test('TC-DAO-03: QuizDao queries questions and records practice attempts', () async {
      final questions = await DatabaseHelper.instance.quizDao.getQuizQuestions(1, limit: 10);
      expect(questions.length, equals(10));

      await DatabaseHelper.instance.quizDao.saveQuizAttempt(
        userId: 1,
        moduleId: 1,
        score: 90,
        passed: true,
      );

      final attempts = await DatabaseHelper.instance.quizDao.getPracticeAttempts(userId: 1);
      expect(attempts, isA<List>());
    });

    test('TC-DAO-04: OfflineQueueDao isolates unsynced records and handles sync marking', () async {
      await DatabaseHelper.instance.quizDao.saveQuizAttempt(
        userId: 1,
        moduleId: 2,
        score: 80,
        passed: true,
        isSynced: false,
      );

      final unsynced = await DatabaseHelper.instance.offlineQueueDao.getUnsyncedQuizAttempts(1);
      expect(unsynced.isNotEmpty, isTrue);

      final firstId = unsynced.first['id'] as int;
      await DatabaseHelper.instance.offlineQueueDao.markQuizAttemptSynced(firstId);

      final unsyncedAfter = await DatabaseHelper.instance.offlineQueueDao.getUnsyncedQuizAttempts(1);
      expect(unsyncedAfter.any((q) => q['id'] == firstId), isFalse);
    });
  });
}
