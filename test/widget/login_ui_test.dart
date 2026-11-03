import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:batikmu/providers/app_provider.dart';
import 'package:batikmu/screens/auth/login_screen.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  Widget createLoginTestWidget() {
    return ChangeNotifierProvider<AppProvider>(
      create: (_) => AppProvider(),
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  void setupPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Pure Black-Box UI Widget Tests: Login Screen', () {
    testWidgets('Layar Login menampilkan elemen formulir dan tombol Masuk', (WidgetTester tester) async {
      setupPhoneViewport(tester);
      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      // Verifikasi elemen visual di layar (Black-Box: apa yang terlihat)
      expect(find.byType(TextField), findsNWidgets(2)); // Kolom Email & Sandi
      expect(find.text('Masuk'), findsWidgets); // Tombol Masuk
    });

    testWidgets('Validasi formulir muncul di layar saat menekan Masuk dengan kolom kosong', (WidgetTester tester) async {
      setupPhoneViewport(tester);
      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      // Jari virtual mencari tombol Masuk dan menekannya
      final masukFinder = find.text('Masuk').last;
      await tester.ensureVisible(masukFinder);
      await tester.tap(masukFinder);
      await tester.pumpAndSettle();

      // Verifikasi pesan validasi muncul di layar
      expect(find.textContaining('Email'), findsWidgets);
    });

    testWidgets('Jari virtual mengetikkan email dan sandi ke kolom input', (WidgetTester tester) async {
      setupPhoneViewport(tester);
      await tester.pumpWidget(createLoginTestWidget());
      await tester.pumpAndSettle();

      // Ketik email pada TextField pertama
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'budi@batikmu.id');
      await tester.pumpAndSettle();

      // Ketik kata sandi pada TextField kedua
      await tester.enterText(textFields.last, 'Password123#');
      await tester.pumpAndSettle();

      // Verifikasi teks tampil di kolom
      expect(find.text('budi@batikmu.id'), findsOneWidget);
    });
  });
}
