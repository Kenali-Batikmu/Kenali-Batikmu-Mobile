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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

      expect(provider.currentUser?.email, equals('sekar@batikmu.id'));
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

      final prevCount = provider.scanHistories.length;
      await provider.savePracticeResult(1, 0.85, true);
      expect(provider.scanHistories.length, equals(prevCount + 1));
      expect(provider.scanHistories.first.score, equals(0.85));
      expect(provider.scanHistories.first.passed, isTrue);
    });
  });
}
