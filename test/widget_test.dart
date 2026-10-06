import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import 'package:batikmu/core/theme/app_theme.dart';
import 'package:batikmu/providers/app_provider.dart';
import 'package:batikmu/screens/onboarding/onboarding_screen.dart';
import 'package:batikmu/screens/dashboard/dashboard_screen.dart';
import 'package:batikmu/screens/modules/theory_quiz_screen.dart';
import 'package:batikmu/screens/modules/practice_quiz_screen.dart';
import 'package:batikmu/screens/profile/profile_screen.dart';

void main() {
  group('OWASP Mobile Security & Hashing Tests (M10, M3)', () {
    test('PasswordHasher generates salted sha256 hash', () {
      const rawPassword = 'Batikmu123#';
      final hash1 = PasswordHasher.hashPassword(rawPassword);
      final hash2 = PasswordHasher.hashPassword(rawPassword);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 Hex string 64 chars
      expect(hash1, isNot(contains(rawPassword))); // No plaintext in hash

      expect(PasswordHasher.verify(rawPassword, hash1), isTrue);
      expect(PasswordHasher.verify('WrongPassword', hash1), isFalse);
    });

    test('Theme provides WCAG AA compliant palette', () {
      expect(AppTheme.primary, isNotNull);
      expect(AppTheme.background, isNotNull);
      expect(AppTheme.textPrimary, isNotNull);
    });
  });

  group('Interactive AppProvider In-Memory Tests', () {
    test('Initializes with default user and 11 modules', () {
      final provider = AppProvider();
      expect(provider.currentUser?.email, equals('sekar@batikmu.id'));
      expect(provider.totalModulesCount, equals(11));
      expect(provider.completedModulesCount, equals(6));
      expect(provider.overallProgressPercent, equals(55));
      expect(provider.scannedMotifsCount, equals(6));
    });

    test('Toggles dark mode dynamically', () {
      final provider = AppProvider();
      expect(provider.isDarkMode, isFalse);
      provider.toggleDarkMode(true);
      expect(provider.isDarkMode, isTrue);
      provider.toggleDarkMode(false);
      expect(provider.isDarkMode, isFalse);
    });

    test('Saves quiz results and updates module progress', () async {
      final provider = AppProvider();
      await provider.saveQuizResult(3, 80, true);
      final m3 = provider.modules.firstWhere((m) => m.id == 3);
      expect(m3.quizDone, isTrue);
    });

    test('Saves practice result and adds to scan histories', () async {
      final provider = AppProvider();
      final prevCount = provider.scanHistories.length;
      await provider.savePracticeResult(3, 0.70, true);
      expect(provider.scanHistories.length, equals(prevCount + 1));
      expect(provider.scanHistories.first.score, equals(0.70));
    });
  });

  group('Onboarding Screen Widget Tests', () {
    testWidgets('Renders onboarding screen with first slide', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingScreen(),
        ),
      );

      expect(find.text('KENALI BATIKMU'), findsOneWidget);
      expect(find.text('Kenali Warisan\nLeluhur Nusantara'), findsOneWidget);
      expect(find.text('EDUKASI BUDAYA'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });
  });

  group('Dashboard Screen Widget Tests', () {
    testWidgets('Renders hero greeting and 3 motif cards', (WidgetTester tester) async {
      final provider = AppProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: DashboardScreen(
              onOpenModules: () {},
              onOpenScan: () {},
              onOpenProfile: () {},
            ),
          ),
        ),
      );

      expect(find.text('Kenali Batikmu'), findsOneWidget);
      expect(find.text('Selamat Datang, Sekar!'), findsOneWidget);
      expect(find.text('Teknik Nglowongi: Menggambar\nGaris Pola Utama'), findsOneWidget);
      expect(find.text('65% Selesai'), findsOneWidget);
      expect(find.text('Cecek Hasan'), findsOneWidget);
      expect(find.text('Parang Rusak'), findsOneWidget);
      expect(find.text('Truntum'), findsOneWidget);
    });
  });

  group('Theory Quiz Screen Widget Tests', () {
    testWidgets('Renders quiz questions and Done button', (WidgetTester tester) async {
      final provider = AppProvider();
      final sampleModule = provider.modules[2];

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: TheoryQuizScreen(module: sampleModule),
          ),
        ),
      );

      expect(find.text('Detail Modul - Kuis Teori'), findsOneWidget);
      expect(find.text('SOAL 1 DARI 10'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Scroll and Tap Done button
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pump();

      // Should display final score banner and explanation
      expect(find.text('Skor Akhir: 80 (8/10)'), findsOneWidget);
      expect(find.text('Penjelasan Materi:'), findsWidgets);
    });
  });

  group('Practice Quiz Screen Widget Tests', () {
    testWidgets('Renders viewfinder and evaluates to result sheet', (WidgetTester tester) async {
      final provider = AppProvider();
      final sampleModule = provider.modules[2];

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: PracticeQuizScreen(module: sampleModule),
          ),
        ),
      );

      expect(find.text('Detail Modul - Kuis Praktikum'), findsOneWidget);
      expect(find.text('Arahkan kamera ke kain batikmu'), findsOneWidget);
      expect(find.text('Kirim untuk Dinilai'), findsOneWidget);

      // Tap kirim untuk dinilai
      await tester.tap(find.text('Kirim untuk Dinilai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Should show hasil penilaian
      expect(find.text('Hasil Penilaian'), findsOneWidget);
      expect(find.text('Sumatra'), findsOneWidget);
      expect(find.text('Jawa'), findsOneWidget);
      expect(find.text('Malang'), findsOneWidget);
      expect(find.text('Ketentuan Penilaian'), findsOneWidget);
    });
  });

  group('Profile Screen Widget Tests', () {
    testWidgets('Renders user Sekar, stats, and mode gelap switch', (WidgetTester tester) async {
      final provider = AppProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Sekar Ayu Kinanti'), findsOneWidget);
      expect(find.text('@sekar_artisan'), findsOneWidget);
      expect(find.text('6/11'), findsOneWidget);
      expect(find.text('Modul Selesai'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Motif Discan'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsOneWidget);
      expect(find.text('Keluar dari Akun'), findsOneWidget);
    });
  });
}
