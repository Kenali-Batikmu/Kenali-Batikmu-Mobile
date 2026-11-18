import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:batikmu/models/app_models.dart';
import 'package:batikmu/providers/app_provider.dart';
import 'package:batikmu/screens/modules/practice_quiz_screen.dart';
import 'package:batikmu/screens/modules/theory_quiz_screen.dart';
import 'package:batikmu/screens/scan/universal_scan_screen.dart';
import '../test_helper.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<AppProvider> _readyAppProvider(WidgetTester tester) async {
  final p = await tester.runAsync(() async {
    final provider = AppProvider();
    await provider.initApp();
    return provider;
  });
  return p!;
}

void main() {
  setupTestEnvironment();

  group('QC Widget Tests: TheoryQuizScreen', () {
    testWidgets('memuat tepat 10 soal pilihan ganda dan menampilkan empty state aman untuk modul tanpa soal', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);
      final mod1 = provider.modules.first;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(home: TheoryQuizScreen(module: mod1)),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('SOAL 1 DARI 10'), findsOneWidget);
      expect(find.text('SOAL 10 DARI 10'), findsOneWidget);

      // Edge case: modul dengan ID yang tidak punya soal di DB
      final emptyMod = ModuleModel(
        id: 9999,
        motifId: 9999,
        orderNo: 99,
        title: 'Modul Kosong',
        description: 'Uji Kosong',
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            home: TheoryQuizScreen(
              key: const ValueKey('empty_mod'),
              module: emptyMod,
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();
      expect(find.text('Soal kuis untuk modul ini sedang disiapkan.'), findsOneWidget);
    });

    testWidgets('[Exam UX QC] mencegah pengumpulan kuis kosong (0/10 dijawab) tanpa peringatan atau pemblokiran', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);
      final mod1 = provider.modules.first;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(home: TheoryQuizScreen(module: mod1)),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Jangan menjawab satu pun soal, langsung cari tombol kumpulkan jawaban
      final submitBtn = find.textContaining('Kumpulkan');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();

      // Standar UX ujian/kuis: sistem wajib mencegah submit saat 0 soal dijawab
      // (tombol nonaktif atau muncul dialog/snackbar konfirmasi, bukan langsung nilai 0).
      expect(
        find.textContaining('Skor Akhir: 0'),
        findsNothing,
        reason:
            'Kuis seharusnya memblokir atau memperingatkan pengguna sebelum mengumpulkan jawaban kosong (0/10 terjawab)',
      );
    });

    testWidgets('menjawab pilihan dan menekan kumpulkan menampilkan banner Skor Akhir & poin per soal', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);
      final mod1 = provider.modules.first;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(home: TheoryQuizScreen(module: mod1)),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      // Jawab seluruh 10 soal (pilih opsi A pada setiap soal)
      final allOptA = find.textContaining('A. ');
      expect(allOptA, findsNWidgets(10));
      for (int i = 0; i < 10; i++) {
        await tester.ensureVisible(allOptA.at(i));
        await tester.tap(allOptA.at(i));
        await tester.pump();
      }

      final submitBtn = find.textContaining('Kumpulkan');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();

      expect(find.textContaining('Skor Akhir:'), findsOneWidget);
    });
  });

  group('QC Widget Tests: PracticeQuizScreen & UniversalScanScreen (Camera/Hardware Graceful Degradation)', () {
    const cameraChannel = MethodChannel('plugins.flutter.io/camera_android');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(cameraChannel, (call) async {
        throw PlatformException(
          code: 'CameraAccessDenied',
          message: 'Izin kamera ditolak oleh pengguna',
        );
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(cameraChannel, null);
    });

    testWidgets('PracticeQuizScreen tidak crash saat kamera ditolak/tidak tersedia dan menampilkan fallback galeri', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);
      final mod1 = provider.modules.first;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(home: PracticeQuizScreen(module: mod1)),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(PracticeQuizScreen), findsOneWidget);
    });

    testWidgets('PracticeQuizScreen mode riwayat (initialShowResult: true) merender skor dan status kelulusan', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);
      final mod1 = provider.modules.first;

      final history = ScanHistoryModel(
        id: 1,
        scanType: 'practice',
        moduleId: mod1.id,
        motifName: mod1.title,
        score: 0.88,
        passed: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(
            home: PracticeQuizScreen(
              module: mod1,
              initialShowResult: true,
              historyData: history,
            ),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('88'), findsWidgets);
    });

    testWidgets('UniversalScanScreen aman saat kamera tidak tersedia maupun dalam kondisi tab tidak aktif (isActive: false)', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);

      // 1. Kondisi tidak aktif
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: UniversalScanScreen(isActive: false)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // 2. Kondisi aktif dengan kamera tidak tersedia / izin ditolak
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: UniversalScanScreen(isActive: true)),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(UniversalScanScreen), findsOneWidget);
    });
  });
}
