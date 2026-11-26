import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:batikmu/core/config/env_config.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/core/utils/password_hasher.dart';
import 'package:batikmu/providers/app_provider.dart';
import 'package:batikmu/screens/auth/forgot_password_screen.dart';
import '../test_helper.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2.0;
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

void main() {
  setupTestEnvironment();

  group('QC Widget Tests: ForgotPasswordScreen (Alur 3 Tahap OTP)', () {
    setUp(() {
      EnvConfig.resetForTest();
    });

    tearDown(() {
      EnvConfig.resetForTest();
    });

    testWidgets('[Step 1 Negative] menolak email kosong dan email tidak terdaftar', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _createReadyProvider(tester);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: ForgotPasswordScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Langkah 1 dari 3'), findsOneWidget);

      // Submit kosong
      final sendBtn = find.textContaining('Kirim').last;
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();
      expect(find.text('Langkah 1 dari 3'), findsOneWidget);

      // Submit email tidak terdaftar
      await tester.enterText(find.byType(TextFormField).first, 'tidak.terdaftar@batikmu.id');
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
      await tester.pump();

      expect(find.text('Langkah 1 dari 3'), findsOneWidget);
    });

    testWidgets('[End-to-End 3 Tahap] Step 1 Email -> Step 2 Tolak OTP Salah & Terima OTP Benar -> Step 3 Simpan Sandi Baru', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _createReadyProvider(tester);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ForgotPasswordScreen(initialEmail: 'sekar@batikmu.id'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // STEP 1: Kirim OTP untuk akun terdaftar
      final sendBtn = find.textContaining('Kirim').last;
      await tester.ensureVisible(sendBtn);
      await tester.tap(sendBtn);
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Langkah 2 dari 3'), findsOneWidget);
      final activeOtp = provider.activeResetOtp;
      expect(activeOtp, isNotNull);
      expect(activeOtp!.length, equals(4));

      // STEP 2 NEGATIVE: Masukkan OTP salah -> tetap di Langkah 2
      final wrongOtp = activeOtp == '0000' ? '1111' : '0000';
      final otpFields = find.byType(TextField);
      expect(otpFields, findsNWidgets(4));
      for (int i = 0; i < 4; i++) {
        await tester.enterText(otpFields.at(i), wrongOtp[i]);
      }
      await tester.pump();

      final verifyBtn = find.textContaining('Verifikasi').last;
      await tester.ensureVisible(verifyBtn);
      await tester.tap(verifyBtn);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Langkah 2 dari 3'), findsOneWidget);

      // STEP 2 POSITIVE: Masukkan OTP benar -> lanjut ke Langkah 3 (auto-submit saat digit ke-4 atau via tombol)
      for (int i = 0; i < 4; i++) {
        await tester.enterText(otpFields.at(i), activeOtp[i]);
      }
      await tester.pump(const Duration(milliseconds: 300));
      final verifyCandidates = find.textContaining('Verifikasi');
      if (verifyCandidates.evaluate().isNotEmpty) {
        await tester.ensureVisible(verifyCandidates.last);
        await tester.tap(verifyCandidates.last);
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(find.text('Langkah 3 dari 3'), findsOneWidget);

      // STEP 3 NEGATIVE: Konfirmasi sandi tidak cocok -> tetap di Langkah 3
      final passFields = find.byType(TextFormField);
      expect(passFields, findsNWidgets(2));
      await tester.enterText(passFields.at(0), 'SandiBaru2026!');
      await tester.enterText(passFields.at(1), 'Berbeda2026!');
      final saveBtn = find.text('Simpan & Masuk');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Langkah 3 dari 3'), findsOneWidget);

      // STEP 3 POSITIVE: Sandi baru cocok -> tersimpan ter-hash di SQLite & dialog sukses tampil
      await tester.enterText(passFields.at(1), 'SandiBaru2026!');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('berhasil diubah'), findsOneWidget);

      final updatedRow = await tester.runAsync(
        () => DatabaseHelper.instance.getUserByEmail('sekar@batikmu.id'),
      );
      expect(updatedRow, isNotNull);
      expect(
        PasswordHasher.verify('SandiBaru2026!', updatedRow!['password_hash'] as String),
        isTrue,
      );
    });
  });
}
