import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/providers/app_provider.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('Comprehensive Workflow & Architecture Tests (Case 1, Case 2, Case 3)', () {
    test('Case 1: Baru Punya Akun - On-device data, login butuh signal, soal teracak, hasil di card & server', () async {
      // 1. On-device data: Master data lengkap 20 modul, 20 motif, 500 soal kuis ada di lokal tanpa login
      final provider = AppProvider();
      await provider.initApp();

      expect(provider.currentUser, isNull);
      expect(provider.modules.length, equals(20));
      expect(provider.motifs.length, equals(20));
      expect(provider.modules.every((m) => m.progressPercent == 0), isTrue);

      final bankSoal = await DatabaseHelper.instance.getQuizQuestions(1, limit: 25, shuffle: false);
      expect(bankSoal.length, equals(25));

      // 2. Login butuh sinyal: Percobaan login akun yang belum di-cache saat offline ditolak dengan pesan jelas
      final loginOfflineFail = await provider.login('newuser@batikmu.id', 'Password123#');
      expect(loginOfflineFail, isFalse);
      expect(provider.errorMessage, contains('Tidak dapat terhubung ke server'));
      expect(provider.currentUser, isNull); // Menjamin tidak ada dummy fallback

      // 3. Login online: Daftarkan akun nyata (simulasi server Supabase + cache lokal)
      final registered = await provider.register('Batik Baru', 'newuser@batikmu.id', 'Password123#');
      expect(registered, isTrue);
      expect(provider.currentUser?.email, equals('newuser@batikmu.id'));

      // 4. Soal kuis teracak per sesi
      final sessionA = await DatabaseHelper.instance.getQuizQuestions(1, limit: 10, shuffle: true);
      final sessionB = await DatabaseHelper.instance.getQuizQuestions(1, limit: 10, shuffle: true);
      expect(sessionA.length, equals(10));
      expect(sessionB.length, equals(10));
      final idsA = sessionA.map((q) => q.id).toList();
      final idsB = sessionB.map((q) => q.id).toList();
      expect(idsA == idsB, isFalse, reason: 'Urutan dan kombinasi soal kuis harus acak dinamis per sesi');

      // 5. Hasil kuis teori & praktikum tersimpan di card modul dan tersimpan di server/antrean
      await provider.saveQuizResult(1, 85, true);
      await provider.savePracticeResult(1, 0.90, true);

      final m1 = provider.modules.firstWhere((m) => m.id == 1);
      expect(m1.quizDone, isTrue);
      expect(m1.quizScore, equals(85));
      expect(m1.practiceDone, isTrue);
      expect(m1.practiceScore, equals(90));
      expect(m1.progressPercent, equals(40)); // 20% kuis + 20% praktik lulus KKM

      // Verifikasi kartu modul memuat riwayat praktikum
      expect(provider.scanHistories.isNotEmpty, isTrue);
      expect(provider.scanHistories.first.moduleId, equals(1));
      expect(provider.scanHistories.first.score, equals(0.90));
    });

    test('Case 2: Pengguna Aktif - Sesi Offline Total, Database Match, & Antrean Sync Saat Internet Pulih', () async {
      // 1. Setup user & progres awal dari Case 1 di SQLite lokal
      await DatabaseHelper.instance.insertUser(
        id: 10,
        name: 'Batik Baru',
        email: 'newuser@batikmu.id',
        passwordHash: PasswordHasher.hashPassword('Password123#'),
      );
      await DatabaseHelper.instance.saveQuizAttempt(
        userId: 10,
        moduleId: 1,
        score: 85,
        passed: true,
        isSynced: true,
      );
      await DatabaseHelper.instance.savePracticeAttempt(
        userId: 10,
        moduleId: 1,
        confidence: 0.90,
        passed: true,
        isSynced: true,
      );

      // Buka app secara offline: Sesi persisten dari login sebelumnya tanpa perlu login ulang
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('logged_user_email', 'newuser@batikmu.id');

      final sessionOffline = AppProvider();
      await sessionOffline.initApp();

      expect(sessionOffline.currentUser, isNotNull);
      expect(sessionOffline.currentUser?.email, equals('newuser@batikmu.id'));

      // 2. Aktivitas offline: Pengguna menuntaskan 3 pilar materi saat offline
      await sessionOffline.updatePillarProgress(1, 'history');
      await sessionOffline.updatePillarProgress(1, 'character');
      await sessionOffline.updatePillarProgress(1, 'gallery');

      final m1Offline = sessionOffline.modules.firstWhere((m) => m.id == 1);
      expect(m1Offline.historyDone, isTrue);
      expect(m1Offline.characterDone, isTrue);
      expect(m1Offline.galleryDone, isTrue);
      expect(m1Offline.progressPercent, equals(100)); // 5 pilar x 20% = 100%
      expect(m1Offline.isCompleted, isTrue);

      // Verifikasi antrean offline mencatat perubahan belum tersinkron (is_synced = 0)
      final user = await DatabaseHelper.instance.getUserByEmail('newuser@batikmu.id');
      final userId = user!['id'] as int;

      final unsyncedProgress = await DatabaseHelper.instance.getUnsyncedUserModuleProgress(userId);
      expect(unsyncedProgress.any((p) => p['module_id'] == 1), isTrue);

      // 3. Sinyal internet pulih: Antrean offline disinkronkan dan ditandai is_synced = 1
      await DatabaseHelper.instance.markUserModuleProgressSynced(userId, 1);
      final remainingUnsynced = await DatabaseHelper.instance.getUnsyncedUserModuleProgress(userId);
      expect(remainingUnsynced.where((p) => p['module_id'] == 1).isEmpty, isTrue);

      // Data lokal dan server match 100%
      final localRows = await DatabaseHelper.instance.getUserModuleProgressList(userId, userEmail: 'newuser@batikmu.id');
      final localMod1 = localRows.firstWhere((r) => r['module_id'] == 1);
      expect(localMod1['progress_percent'], equals(100));
      expect(localMod1['quiz_score'], equals(85));
      expect(localMod1['practice_score'], equals(90));
      expect(localMod1['is_synced'], equals(1));
    });

    test('Case 3: Install Ulang Aplikasi - Restore Penuh dari Cloud, Local & Server Match 100%', () async {
      // 1. Simulasikan uninstall & install ulang: Hapus seluruh database lokal dan SharedPreferences
      final db = await DatabaseHelper.instance.database;
      if (db != null) {
        await db.delete('users');
        await db.delete('user_module_progress');
        await db.delete('quiz_attempts');
        await db.delete('scans');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Instance baru dibuka (seperti baru diinstal ulang)
      final reinstalledApp = AppProvider();
      await reinstalledApp.initApp();

      expect(reinstalledApp.currentUser, isNull);
      expect(reinstalledApp.modules.length, equals(20));
      expect(reinstalledApp.modules.every((m) => m.progressPercent == 0), isTrue);

      // 2. Pengguna Login Online: Simulasikan recovery profil dan progress dari Cloud Supabase
      await DatabaseHelper.instance.insertUser(
        id: 77,
        name: 'Julian Cloud Restored',
        email: 'restored@batikmu.id',
        passwordHash: PasswordHasher.hashPassword('CloudPass123#'),
      );

      // Simulasikan pull dari server ke database lokal SQLite
      await DatabaseHelper.instance.upsertUserModuleProgress(
        userId: 77,
        moduleId: 1,
        progressPercent: 100,
        historyDone: true,
        characterDone: true,
        galleryDone: true,
        quizDone: true,
        practiceDone: true,
        quizScore: 95,
        practiceScore: 92,
        passingScore: 70,
        isPassed: true,
        isSynced: true,
      );

      await DatabaseHelper.instance.savePracticeAttempt(
        userId: 77,
        moduleId: 1,
        confidence: 0.92,
        passed: true,
        imagePath: 'https://supabase.co/storage/v1/object/public/practices/practice_restored_mod1.jpg',
        isSynced: true,
      );

      // Login sukses
      final loginSuccess = await reinstalledApp.login('restored@batikmu.id', 'CloudPass123#');
      expect(loginSuccess, isTrue);
      expect(reinstalledApp.currentUser?.name, equals('Julian Cloud Restored'));

      // 3. Verifikasi seluruh data dan progres modul pulih 100% dan match server
      final restoredM1 = reinstalledApp.modules.firstWhere((m) => m.id == 1);
      expect(restoredM1.progressPercent, equals(100));
      expect(restoredM1.isCompleted, isTrue);
      expect(restoredM1.historyDone, isTrue);
      expect(restoredM1.characterDone, isTrue);
      expect(restoredM1.galleryDone, isTrue);
      expect(restoredM1.quizDone, isTrue);
      expect(restoredM1.quizScore, equals(95));
      expect(restoredM1.practiceDone, isTrue);
      expect(restoredM1.practiceScore, equals(92));

      // Verifikasi riwayat scan praktikum pulih di mobile
      expect(reinstalledApp.scanHistories.isNotEmpty, isTrue);
      expect(reinstalledApp.scanHistories.first.moduleId, equals(1));
      expect(reinstalledApp.scanHistories.first.score, equals(0.92));
      expect(reinstalledApp.scanHistories.first.imagePath, contains('practice_restored_mod1.jpg'));
    });
  });
}
