import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/providers/app_provider.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

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

      // 4. Kuis Teori di bawah KKM (< 70) -> quizDone true (agar tombol jadi Kerjakan Ulang), namun bobot tetap 60% karena belum lulus KKM
      await provider.saveQuizResult(2, 60, false);
      final mAfterFailQuiz = provider.modules.firstWhere((m) => m.id == 2);
      expect(mAfterFailQuiz.quizDone, isTrue, reason: 'Kuis yang sudah dikerjakan harus tercatat selesai agar UI menampilkan tombol Kerjakan Ulang');
      expect(mAfterFailQuiz.quizScore, equals(60));
      expect(mAfterFailQuiz.progressPercent, equals(60), reason: 'Progres tetap 60% karena skor belum memenuhi KKM 70%');

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
}
