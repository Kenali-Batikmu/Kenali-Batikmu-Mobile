import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batikmu/providers/app_provider.dart';
import 'package:batikmu/screens/auth/login_screen.dart';
import 'package:batikmu/screens/profile/profile_screen.dart';
import '../test_helper.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<AppProvider> _loggedInProvider(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'is_logged_in': true,
    'logged_user_email': 'sekar@batikmu.id',
  });
  final p = await tester.runAsync(() async {
    final provider = AppProvider(
      initialIsLoggedIn: true,
      initialEmail: 'sekar@batikmu.id',
    );
    await provider.initApp(savedEmail: 'sekar@batikmu.id');
    return provider;
  });
  return p!;
}

void main() {
  setupTestEnvironment();

  group('QC Widget Tests: ProfileScreen', () {
    testWidgets('menampilkan data profil akun aktif dan berhasil mengubah nama via bottom sheet', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _loggedInProvider(tester);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.text('Sekar Ayu Kinanti'), findsWidgets);
      expect(find.text('sekar@batikmu.id'), findsOneWidget);

      // Buka modal Ubah Nama (ikon edit baris pertama)
      final editIcons = find.byIcon(Icons.edit_outlined);
      expect(editIcons, findsNWidgets(4));
      await tester.ensureVisible(editIcons.at(0));
      await tester.tap(editIcons.at(0));
      await tester.pumpAndSettle();
      expect(find.text('Ubah Nama'), findsOneWidget);

      // Negatif: nama kosong ditolak
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pump();
      expect(find.text('Nama tidak boleh kosong'), findsOneWidget);

      // Positif: ubah ke nama baru valid
      await tester.enterText(find.byType(TextField), 'Sekar QC Updated');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();

      expect(provider.currentUser?.name, equals('Sekar QC Updated'));
    });

    testWidgets('[OWASP Security QC] ubah kata sandi pada Profil wajib menolak sandi terlalu pendek (< 8 karakter)', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _loggedInProvider(tester);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final editIcons = find.byIcon(Icons.edit_outlined);
      await tester.ensureVisible(editIcons.at(1));
      await tester.tap(editIcons.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);

      // Masukkan sandi 2 karakter yang sangat lemah
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pumpAndSettle();

      // Standar keamanan OWASP: perubahan kata sandi ke 'ab' (< 8 karakter) wajib ditolak
      // sehingga modal edit tetap terbuka menampilkan pesan error, bukan langsung tertutup dan tersimpan.
      expect(
        find.text('Ubah Kata Sandi'),
        findsOneWidget,
        reason:
            'Ubah kata sandi di ProfileScreen seharusnya menolak kata sandi 2 karakter "ab" (< 8 karakter)',
      );
    });

    testWidgets('[Feature Parity QC] ProfileScreen menyediakan sakelar Mode Gelap untuk mengaktifkan ThemeProvider', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _loggedInProvider(tester);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Karena aplikasi mendeklarasikan AppTheme.darkTheme & ThemeProvider,
      // standar paritas fitur mengharuskan kontrol Mode Gelap dapat diakses pengguna di Profil/Pengaturan.
      final hasDarkModeControl = find.byType(Switch).evaluate().isNotEmpty ||
          find.textContaining('Gelap').evaluate().isNotEmpty ||
          find.textContaining('Dark').evaluate().isNotEmpty;

      expect(
        hasDarkModeControl,
        isTrue,
        reason: 'Kontrol UI Mode Gelap (Switch/Menu) belum tersedia di ProfileScreen',
      );
    });

    testWidgets('dialog konfirmasi keluar menghapus sesi dan mengarahkan ke LoginScreen', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _loggedInProvider(tester);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final logoutBtn = find.byIcon(Icons.logout);
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Akun?'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Keluar'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(provider.currentUser, isNull);
    });
  });
}
