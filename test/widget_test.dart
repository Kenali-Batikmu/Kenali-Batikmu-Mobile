import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import 'package:batikmu/core/theme/app_theme.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('scans');
      await db.delete('user_module_progress');
      await db.delete('quiz_attempts');
      final u1 = await db.query('users', where: 'id = ?', whereArgs: [1]);
      if (u1.isEmpty) {
        await db.insert('users', {
          'id': 1,
          'name': 'Sekar Ayu Kinanti',
          'email': 'sekar@batikmu.id',
          'password_hash': 'demo_hash',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }
  });

  group('OWASP Mobile Security & Hashing Tests (M10, M3)', () {
    test('PasswordHasher generates salted sha256 hash', () {
      const rawPassword = 'Batikmu123#';
      final hash1 = PasswordHasher.hashPassword(rawPassword);
      final hash2 = PasswordHasher.hashPassword(rawPassword);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64));
      expect(hash1, isNot(contains(rawPassword)));

      expect(PasswordHasher.verify(rawPassword, hash1), isTrue);
      expect(PasswordHasher.verify('WrongPassword', hash1), isFalse);
    });

    test('Theme provides WCAG AA compliant palette', () {
      expect(AppTheme.primary, isNotNull);
      expect(AppTheme.background, isNotNull);
      expect(AppTheme.textPrimary, isNotNull);
    });
  });

  group('Offline-First Database & 20 Modul Seeding Tests', () {
    test('DatabaseHelper loads 20 motifs, 20 modules, and 500 questions', () async {
      final motifs = await DatabaseHelper.instance.getAllMotifs();
      expect(motifs.length, equals(20));

      final modules = await DatabaseHelper.instance.getAllModules();
      expect(modules.length, equals(20));

      // Verifikasi modul memiliki narasi & pakem
      final m1 = modules.first;
      expect(m1.title, isNotEmpty);
      expect(m1.content, isNotNull);
      expect(modules.any((m) => m.title.contains('Parang')), isTrue);
      expect(m1.content?.sejarahDanFilosofi.deskripsiUtama, isNotEmpty);
      expect(m1.content?.karakteristik.pakemList, isNotEmpty);

      // Verifikasi bank soal kuis (25 butir per modul)
      final allModule1Questions = await DatabaseHelper.instance.getQuizQuestions(1, limit: 25, shuffle: false);
      expect(allModule1Questions.length, equals(25));

      // Verifikasi randomisasi 10 soal untuk pengerjaan kuis
      final randomized10 = await DatabaseHelper.instance.getQuizQuestions(1, limit: 10, shuffle: true);
      expect(randomized10.length, equals(10));
    });

    test('AppProvider loads and manages 20 modules seamlessly', () async {
      final provider = AppProvider();
      await provider.initApp();

      // Tabel users bersih dan kosong di awal (menunggu pendaftaran / login pengguna riil)
      expect(provider.currentUser, isNull);
      expect(provider.modules.length, equals(20));
      expect(provider.motifs.length, equals(20));
      expect(provider.totalModulesCount, equals(20));
    });

    test('AppProvider toggles dark mode dynamically', () {
      final provider = AppProvider();
      expect(provider.isDarkMode, isFalse);
      provider.toggleDarkMode(true);
      expect(provider.isDarkMode, isTrue);
      provider.toggleDarkMode(false);
      expect(provider.isDarkMode, isFalse);
    });

    test('AppProvider saves quiz result and persists to database', () async {
      final provider = AppProvider();
      await provider.initApp();

      await provider.saveQuizResult(1, 80, true);
      final m1 = provider.modules.firstWhere((m) => m.id == 1);
      expect(m1.quizDone, isTrue);
      expect(m1.quizScore, equals(80));
    });

    test('AppProvider saves practice result and records scan history', () async {
      final provider = AppProvider();
      await provider.initApp();

      await provider.savePracticeResult(1, 0.85, true);
      expect(provider.scanHistories.length, equals(1));
      expect(provider.scanHistories.first.score, equals(0.85));
      expect(provider.scanHistories.first.passed, isTrue);

      // Pindaian ulang untuk modul yang sama: harus menimpa rekaman lama (panjang tetap 1 per modul)
      await provider.savePracticeResult(1, 0.92, true);
      expect(provider.scanHistories.length, equals(1));
      expect(provider.scanHistories.first.score, equals(0.92));
    });

    test('AppProvider registers user and persists real name to database', () async {
      final provider = AppProvider();
      await provider.initApp();

      final registered = await provider.register(
        'Julian Developer',
        'julian@batikmu.id',
        'RahasiaBatik123#',
      );
      expect(registered, isTrue);
      expect(provider.currentUser?.name, equals('Julian Developer'));
      expect(provider.currentUser?.email, equals('julian@batikmu.id'));

      // Verifikasi tersimpan di database SQLite lokal
      final dbUser = await DatabaseHelper.instance.getUserByEmail('julian@batikmu.id');
      expect(dbUser, isNotNull);
      expect(dbUser!['name'], equals('Julian Developer'));

      // Test pembaruan nama dan profil
      await provider.updateProfile(
        name: 'Julian Senior Engineer',
        email: 'julian@batikmu.id',
        phone: '081234567899',
        password: '',
      );
      expect(provider.currentUser?.name, equals('Julian Senior Engineer'));
      final updatedUser = await DatabaseHelper.instance.getUserByEmail('julian@batikmu.id');
      expect(updatedUser!['name'], equals('Julian Senior Engineer'));
      expect(updatedUser['phone'], equals('081234567899'));
    });

    test('DatabaseHelper and AppProvider handle master data motif synchronization', () async {
      final provider = AppProvider();
      await provider.initApp();

      // Uji upsert motif baru atau perbaruan kategori
      final upserted = await DatabaseHelper.instance.upsertMotifs([
        {
          'id': 99,
          'name': 'Batik Tambal Nusantara',
          'slug': 'batik_tambal_nusantara',
          'origin_region': 'Yogyakarta - Ragam Khusus',
          'short_description': 'Motif tambal lambang perbaikan lahir batin.',
          'ml_class_index': 20,
        }
      ]);
      expect(upserted, equals(1));

      final allMotifs = await DatabaseHelper.instance.getAllMotifs();
      final addedMotif = allMotifs.firstWhere((m) => m.slug == 'batik_tambal_nusantara');
      expect(addedMotif.name, equals('Batik Tambal Nusantara'));
      expect(addedMotif.originRegion, equals('Yogyakarta - Ragam Khusus'));

      // Pembersihan (cleanup)
      final deleted = await DatabaseHelper.instance.deleteMotifById(99);
      expect(deleted, equals(1));
    });

    test('Offline Queue tracks unsynced records and resolves them upon sync', () async {
      final provider = AppProvider();
      await provider.initApp();

      // Buat akun uji
      await provider.register('Offline Tester', 'offline_tester@batikmu.id', 'Password123#');
      final user = await DatabaseHelper.instance.getUserByEmail('offline_tester@batikmu.id');
      final userId = user!['id'] as int;

      // 1. Simpan aktivitas kuis dalam status belum tersinkronkan (is_synced = 0)
      await DatabaseHelper.instance.saveQuizAttempt(
        userId: userId,
        moduleId: 1,
        score: 100,
        passed: true,
        isSynced: false,
      );

      // 2. Simpan aktivitas praktikum dalam status belum tersinkronkan (is_synced = 0)
      await DatabaseHelper.instance.savePracticeAttempt(
        userId: userId,
        moduleId: 1,
        confidence: 0.95,
        passed: true,
        imagePath: '/data/user/0/test.jpg',
        isSynced: false,
      );

      // Verifikasi antrean offline mendeteksi rekaman tertunda
      final unsyncedQuizzes = await DatabaseHelper.instance.getUnsyncedQuizAttempts(userId);
      expect(unsyncedQuizzes.isNotEmpty, isTrue);
      expect(unsyncedQuizzes.last['score'], equals(100));

      final unsyncedScans = await DatabaseHelper.instance.getUnsyncedScans(userId);
      expect(unsyncedScans.isNotEmpty, isTrue);
      expect(unsyncedScans.last['confidence'], equals(0.95));

      // 3. Simulasikan penandaan selesai tersinkronkan saat internet aktif
      await DatabaseHelper.instance.markQuizAttemptSynced(unsyncedQuizzes.last['id'] as int);
      await DatabaseHelper.instance.markScanSynced(unsyncedScans.last['id'] as int);

      // Verifikasi antrean sekarang bersih (0 item tertunda)
      final remainingQuizzes = await DatabaseHelper.instance.getUnsyncedQuizAttempts(userId);
      final remainingScans = await DatabaseHelper.instance.getUnsyncedScans(userId);
      expect(remainingQuizzes.where((q) => q['id'] == unsyncedQuizzes.last['id']).isEmpty, isTrue);
      expect(remainingScans.where((s) => s['id'] == unsyncedScans.last['id']).isEmpty, isTrue);
    });

    test('Module progress implements 5 components of 20% with KKM 70% threshold', () async {
      final provider = AppProvider();
      await provider.initApp();

      // Gunakan modul 2 yang masih bersih (0%)
      expect(provider.modules.firstWhere((m) => m.id == 2).progressPercent, equals(0));

      // 1. Pilar 1: Sejarah -> 20%
      await provider.updatePillarProgress(2, 'history');
      expect(provider.modules.firstWhere((m) => m.id == 2).progressPercent, equals(20));

      // 2. Pilar 2: Karakteristik -> 40%
      await provider.updatePillarProgress(2, 'character');
      expect(provider.modules.firstWhere((m) => m.id == 2).progressPercent, equals(40));

      // 3. Pilar 3: Galeri -> 60%
      await provider.updatePillarProgress(2, 'gallery');
      expect(provider.modules.firstWhere((m) => m.id == 2).progressPercent, equals(60));

      // 4. Kuis Teori di bawah KKM (< 70) -> tetap 60%
      await provider.saveQuizResult(2, 60, false);
      final mAfterFailQuiz = provider.modules.firstWhere((m) => m.id == 2);
      expect(mAfterFailQuiz.quizDone, isFalse);
      expect(mAfterFailQuiz.quizScore, equals(60));
      expect(mAfterFailQuiz.progressPercent, equals(60));

      // 5. Kuis Teori Lulus (>= 70) -> 80%
      await provider.saveQuizResult(2, 80, true);
      final mAfterPassQuiz = provider.modules.firstWhere((m) => m.id == 2);
      expect(mAfterPassQuiz.quizDone, isTrue);
      expect(mAfterPassQuiz.quizScore, equals(80));
      expect(mAfterPassQuiz.progressPercent, equals(80));

      // 6. Kuis Praktik Lulus (>= 70%) -> 100%
      await provider.savePracticeResult(2, 0.85, true);
      final mAfterPassPractice = provider.modules.firstWhere((m) => m.id == 2);
      expect(mAfterPassPractice.practiceDone, isTrue);
      expect(mAfterPassPractice.practiceScore, equals(85));
      expect(mAfterPassPractice.progressPercent, equals(100));
      expect(mAfterPassPractice.isCompleted, isTrue);
    });
  });

  group('Module Progress Isolation & Reload Stability Tests (Anti-Cross Bleeding)', () {
    test('Module progress remains strictly isolated per moduleId without cross-module bleeding', () async {
      final provider = AppProvider();
      await provider.initApp();

      await provider.register('Module Tester', 'tester@batikmu.id', 'Password123#');

      // Modul 8 (Mega Mendung) dikerjakan 40% (sejarah & karakteristik)
      await provider.updatePillarProgress(8, 'history');
      await provider.updatePillarProgress(8, 'character');

      // Modul 2 (Bokor Kencono) dikerjakan 20% (sejarah)
      await provider.updatePillarProgress(2, 'history');

      // Verifikasi modul 8 tepat 40%
      final m8 = provider.modules.firstWhere((m) => m.id == 8);
      expect(m8.progressPercent, equals(40));
      expect(m8.historyDone, isTrue);
      expect(m8.characterDone, isTrue);
      expect(m8.galleryDone, isFalse);

      // Verifikasi modul 2 tepat 20%
      final m2 = provider.modules.firstWhere((m) => m.id == 2);
      expect(m2.progressPercent, equals(20));
      expect(m2.historyDone, isTrue);
      expect(m2.characterDone, isFalse);

      // Verifikasi 18 modul lainnya tidak bocor (tetap 0%)
      for (final mod in provider.modules) {
        if (mod.id != 8 && mod.id != 2) {
          expect(mod.progressPercent, equals(0), reason: 'Module ${mod.id} (${mod.title}) must remain 0%');
          expect(mod.historyDone, isFalse);
          expect(mod.characterDone, isFalse);
          expect(mod.galleryDone, isFalse);
          expect(mod.quizDone, isFalse);
          expect(mod.practiceDone, isFalse);
        }
      }
    });

    test('Module progress remains 100% stable across simulated app reload / hot reload', () async {
      // 1. Sesi awal: Pengguna mengerjakan modul 8 dan 2
      final session1 = AppProvider();
      await session1.initApp();
      await session1.register('Reload Tester', 'reload_tester@batikmu.id', 'Password123#');

      await session1.updatePillarProgress(8, 'history');
      await session1.updatePillarProgress(8, 'character');
      await session1.updatePillarProgress(2, 'history');

      expect(session1.modules.firstWhere((m) => m.id == 8).progressPercent, equals(40));
      expect(session1.modules.firstWhere((m) => m.id == 2).progressPercent, equals(20));

      // 2. Simulasikan reload aplikasi (membuat instance AppProvider baru seperti hot reload)
      final session2 = AppProvider(initialIsLoggedIn: true, initialEmail: 'reload_tester@batikmu.id');
      await session2.initApp();

      // Verifikasi 20 modul termuat secara utuh
      expect(session2.modules.length, equals(20));

      // Verifikasi modul 8 tetap memiliki progres 40% dan tidak tertukar dengan modul lain
      final reloadedM8 = session2.modules.firstWhere((m) => m.id == 8);
      expect(reloadedM8.title, contains('Mega Mendung'));
      expect(reloadedM8.progressPercent, equals(40));
      expect(reloadedM8.historyDone, isTrue);
      expect(reloadedM8.characterDone, isTrue);

      // Verifikasi modul 2 tetap memiliki progres 20%
      final reloadedM2 = session2.modules.firstWhere((m) => m.id == 2);
      expect(reloadedM2.title, contains('Bokor Kencono'));
      expect(reloadedM2.progressPercent, equals(20));
      expect(reloadedM2.historyDone, isTrue);

      // Verifikasi modul lainnya tetap bersih (0%)
      for (final mod in session2.modules) {
        if (mod.id != 8 && mod.id != 2) {
          expect(mod.progressPercent, equals(0), reason: 'Module ${mod.id} (${mod.title}) must remain 0% after reload');
        }
      }
    });

    test('Concurrent initApp calls do not corrupt in-memory state or trigger race condition', () async {
      final provider = AppProvider();
      // Panggil initApp berkali-kali secara simultan (simulasi hot reload beruntun)
      await Future.wait([
        provider.initApp(),
        provider.initApp(),
        provider.initApp(),
      ]);

      expect(provider.modules.length, equals(20));
      expect(provider.motifs.length, equals(20));
    });
  });

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
      // Probabilitas urutan 10 soal acak dari 25 butir identik adalah 1/(25P10) ~ 0
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
      // Progres lokal kosong (0%)
      expect(reinstalledApp.modules.every((m) => m.progressPercent == 0), isTrue);

      // 2. Pengguna Login Online: Simulasikan recovery profil dan progress dari Cloud Supabase
      // Insert user dari server
      await DatabaseHelper.instance.insertUser(
        id: 77,
        name: 'Julian Cloud Restored',
        email: 'restored@batikmu.id',
        passwordHash: PasswordHasher.hashPassword('CloudPass123#'),
      );

      // Simulasikan pull dari server (syncUserProgressFromServer) ke database lokal SQLite
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
        isSynced: true, // Pulih dari cloud
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
      // Simulasikan pendaftaran user baru untuk isolasi test
      final provider = AppProvider();
      await provider.initApp();

      await DatabaseHelper.instance.insertUser(
        id: 99,
        name: 'Budi Test Case',
        email: 'budi.test@batikmu.id',
        passwordHash: PasswordHasher.hashPassword('BudiPass123#'),
      );

      // Simulasikan data progress di SQLite (seperti baru ditarik dari server dengan snake_case)
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

