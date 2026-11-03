import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/providers/auth_provider.dart';
import 'package:batikmu/providers/module_provider.dart';
import 'package:batikmu/providers/quiz_provider.dart';
import 'package:batikmu/providers/theme_provider.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('Phase 3 Domain Providers Architecture & Isolation Tests (TC-PROV-01 to TC-PROV-04)', () {
    test('TC-PROV-01: ThemeProvider toggles dark mode and notifies listeners', () async {
      final themeProvider = ThemeProvider(initialDarkMode: false);
      bool notified = false;
      themeProvider.addListener(() => notified = true);

      themeProvider.toggleDarkMode(true);
      expect(themeProvider.isDarkMode, isTrue);
      expect(notified, isTrue);
    });

    test('TC-PROV-02: AuthProvider manages login failure and success cleanly', () async {
      final authProvider = AuthProvider();

      final passHash = PasswordHasher.hashPassword('SekarPass123#');
      await DatabaseHelper.instance.insertUser(
        id: 10,
        name: 'Sekar Test',
        email: 'sekar.test@batikmu.id',
        passwordHash: passHash,
      );

      // Login dengan kredensial salah ditolak
      final fail = await authProvider.login('sekar.test@batikmu.id', 'wrongpass123');
      expect(fail, isFalse);
      expect(authProvider.errorMessage, isNotNull);

      // Login sukses memuat data UserModel asli
      final ok = await authProvider.login('sekar.test@batikmu.id', 'SekarPass123#');
      expect(ok, isTrue);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.email, equals('sekar.test@batikmu.id'));
    });

    test('TC-PROV-03: ModuleProvider calculates completion and total metrics dynamically', () async {
      final moduleProvider = ModuleProvider();
      await moduleProvider.loadMasterData(userId: 1, userEmail: 'sekar@batikmu.id');

      expect(moduleProvider.modules.length, equals(20));
      expect(moduleProvider.motifs.length, equals(20));
      expect(moduleProvider.totalModulesCount, equals(20));
      expect(moduleProvider.completedModulesCount, isA<int>());
      expect(moduleProvider.overallProgressPercent, isA<int>());
    });

    test('TC-PROV-04: QuizProvider manages scan histories and practice attempts', () async {
      final quizProvider = QuizProvider();
      await quizProvider.loadScanHistories(1, userEmail: 'sekar@batikmu.id');

      quizProvider.addUniversalScanResult(
        motifName: 'Batik Parang Test',
        confidence: 0.92,
      );

      expect(quizProvider.scanHistories.isNotEmpty, isTrue);
      expect(quizProvider.scanHistories.first.motifName, equals('Batik Parang Test'));
      expect(quizProvider.scannedMotifsCount, equals(quizProvider.scanHistories.length));
    });
  });
}
