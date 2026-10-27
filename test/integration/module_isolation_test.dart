import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/providers/app_provider.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

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
}
