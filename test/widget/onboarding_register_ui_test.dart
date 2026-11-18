import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/providers/app_provider.dart';
import 'package:batikmu/screens/auth/login_screen.dart';
import 'package:batikmu/screens/auth/register_screen.dart';
import 'package:batikmu/screens/onboarding/onboarding_screen.dart';
import '../test_helper.dart';

void _setViewport(WidgetTester tester, {Size size = const Size(1080, 2400), double dpr = 2.0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<AppProvider> _createReadyProvider(WidgetTester tester) async {
  final p = await tester.runAsync(() async {
    final provider = AppProvider();
    await provider.initApp();
    return provider;
  });
  return p!;
}

Widget _wrapWithAppProvider(Widget child, AppProvider provider) {
  return ChangeNotifierProvider<AppProvider>.value(
    value: provider,
    child: MaterialApp(home: child),
  );
}

void main() {
  setupTestEnvironment();

  group('QC Widget Tests: OnboardingScreen', () {
    testWidgets('merender 3 slide onboarding tanpa overflow dan tombol Lewati hilang di slide terakhir', (tester) async {
      _setViewport(tester);
      final provider = await _createReadyProvider(tester);
      await tester.pumpWidget(_wrapWithAppProvider(const OnboardingScreen(), provider));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('KENALI BUDAYA'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);

      // Geser ke slide 2
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();
      expect(find.text('BELAJAR & MENGGAMBAR'), findsOneWidget);

      // Geser ke slide 3 (terakhir): tombol Lewati seharusnya tersembunyi
      await tester.drag(find.byType(PageView), const Offset(-450, 0));
      await tester.pumpAndSettle();
      expect(find.text('DETEKSI REALTIME'), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('menekan tombol Lewati menyimpan flag has_seen_onboarding dan membuka LoginScreen', (tester) async {
      _setViewport(tester);
      final provider = await _createReadyProvider(tester);
      await tester.pumpWidget(_wrapWithAppProvider(const OnboardingScreen(), provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lewati'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      final prefs = await tester.runAsync(() => SharedPreferences.getInstance());
      expect(prefs?.getBool('has_seen_onboarding'), isTrue);
    });
  });

  group('QC Widget Tests: RegisterScreen', () {
    testWidgets('menampilkan 3 kolom input, persetujuan syarat, dan menolak form kosong', (tester) async {
      _setViewport(tester);
      final provider = await _createReadyProvider(tester);
      await tester.pumpWidget(_wrapWithAppProvider(const RegisterScreen(), provider));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(3));

      // Tekan tombol submit tanpa mengisi data
      final submitBtn = find.textContaining('Daftar').last;
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Tetap berada di RegisterScreen dengan pesan validasi
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.textContaining('Nama'), findsWidgets);
    });

    testWidgets('[Negative QC] menolak pendaftaran bila email tidak valid atau checkbox Syarat belum dicentang', (tester) async {
      _setViewport(tester);
      final provider = await _createReadyProvider(tester);
      await tester.pumpWidget(_wrapWithAppProvider(const RegisterScreen(), provider));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Siti Rahma');
      await tester.enterText(fields.at(1), 'siti.rahma@batikmu.id');
      await tester.enterText(fields.at(2), 'BatikKuat123!');
      await tester.pumpAndSettle();

      // Jangan centang syarat & ketentuan, langsung klik Daftar
      final submitBtn = find.textContaining('Daftar').last;
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(
        find.textContaining('Syarat'),
        findsWidgets,
      );
    });

    testWidgets('[OWASP Password Policy QC] menolak kata sandi lemah (kurang dari 8 karakter / hanya angka)', (tester) async {
      _setViewport(tester);
      final provider = await _createReadyProvider(tester);
      await tester.pumpWidget(_wrapWithAppProvider(const RegisterScreen(), provider));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Siti Rahma');
      await tester.enterText(fields.at(1), 'lemah.qc@batikmu.id');
      await tester.enterText(fields.at(2), '123456'); // Hanya 6 digit angka (lemah menurut NIST/OWASP)

      // Centang persetujuan syarat
      final termsText = find.text('Saya menyetujui ');
      await tester.ensureVisible(termsText);
      await tester.tap(termsText);
      await tester.pumpAndSettle();

      final submitBtn = find.textContaining('Daftar').last;
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await tester.pump();

      // Standar OWASP ASVS / NIST SP 800-63B: minimal 8 karakter, akun lemah '123456' harus ditolak
      final created = await tester.runAsync(
        () => DatabaseHelper.instance.getUserByEmail('lemah.qc@batikmu.id'),
      );
      expect(
        created,
        isNull,
        reason: 'Kata sandi lemah 6 digit angka "123456" seharusnya ditolak oleh kebijakan keamanan registrasi',
      );
    });

    testWidgets('[Positive QC] registrasi lengkap dengan sandi kuat menyimpan akun nyata ke SQLite', (tester) async {
      _setViewport(tester);
      final appProvider = await _createReadyProvider(tester);
      await tester.pumpWidget(_wrapWithAppProvider(const RegisterScreen(), appProvider));
      await tester.pump(const Duration(milliseconds: 300));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Raka Pratama');
      await tester.enterText(fields.at(1), 'raka.qc@batikmu.id');
      await tester.enterText(fields.at(2), 'BatikAman2026!');

      final termsText = find.text('Saya menyetujui ');
      await tester.ensureVisible(termsText);
      await tester.tap(termsText);
      await tester.pump(const Duration(milliseconds: 200));

      final submitBtn = find.text('Daftar Sekarang');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      // Majukan FakeAsync > 250ms agar Future.delayed di AuthProvider.register selesai sebelum I/O SQLite
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
      await tester.pump(const Duration(milliseconds: 300));

      final user = await tester.runAsync(
        () => DatabaseHelper.instance.getUserByEmail('raka.qc@batikmu.id'),
      );
      expect(user, isNotNull);
      expect(user!['name'], equals('Raka Pratama'));
    });
  });
}
