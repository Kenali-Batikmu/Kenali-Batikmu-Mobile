import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:batikmu/models/app_models.dart';
import 'package:batikmu/providers/app_provider.dart';
import 'package:batikmu/screens/modules/module_detail_screen.dart';
import 'package:batikmu/screens/modules/modules_list_screen.dart';
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

  group('QC Widget Tests: ModulesListScreen', () {
    testWidgets('menampilkan 20 modul dari SQLite lokal, mendukung pencarian valid dan empty state', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);
      expect(provider.modules.length, equals(20));

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: ModulesListScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);

      // Pencarian valid
      await tester.enterText(find.byType(TextField), 'Parang');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Parang'), findsWidgets);

      // Pencarian tidak cocok -> tampil pesan empty state yang rapi
      await tester.enterText(find.byType(TextField), 'MotifTidakAda999');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tidak ada modul yang cocok dengan filter.'), findsOneWidget);

      // Kosongkan pencarian -> daftar modul pulih kembali
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tidak ada modul yang cocok dengan filter.'), findsNothing);
    });

    testWidgets('[Search UX QC] pencarian kata kunci tanpa spasi "Megamendung" tetap menemukan "Mega Mendung"', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: ModulesListScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Standar UX pencarian modern: normalisasi spasi agar "Megamendung" menemukan "Batik Mega Mendung"
      await tester.enterText(find.byType(TextField), 'Megamendung');
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Mega Mendung'),
        findsWidgets,
        reason:
            'Pencarian "Megamendung" (tanpa spasi) seharusnya menemukan modul "Batik Mega Mendung"',
      );
    });

    testWidgets('modal filter modul menampilkan opsi status dan memfilter modul selesai (100%)', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: const MaterialApp(home: ModulesListScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Buka modal filter (chip tombol 'Urutkan')
      final filterBtn = find.byIcon(Icons.tune);
      if (filterBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(filterBtn.first);
        await tester.tap(filterBtn.first);
      } else {
        final textBtn = find.textContaining('Urutkan');
        await tester.ensureVisible(textBtn.first);
        await tester.tap(textBtn.first);
      }
      await tester.pumpAndSettle();

      expect(find.text('Filter & Urutkan Modul'), findsOneWidget);

      // Pilih Modul Selesai (100%) -> saat progres awal 0%, daftar harus menampilkan empty state
      await tester.tap(find.text('Modul Selesai (100%)'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada modul yang cocok dengan filter.'), findsOneWidget);
    });
  });

  group('QC Widget Tests: ModuleDetailScreen (3 Pilar & Progres)', () {
    testWidgets('merender Detail Modul (tanpa WebView native) dan menggeser 3 pilar memperbarui progres 20% -> 40% -> 60%', (tester) async {
      _setPhoneViewport(tester);
      final provider = await _readyAppProvider(tester);
      final orig = provider.modules.first;

      // Salinan modul tanpa URL WebView YouTube agar komponen 3 pilar teruji murni di headless test
      final c = orig.content!;
      final modForHeadless = ModuleModel(
        id: orig.id,
        motifId: orig.motifId,
        orderNo: orig.orderNo,
        title: orig.title,
        description: orig.description,
        coverImage: orig.coverImage,
        passingScore: orig.passingScore,
        content: ModuleContentModel(
          origin: c.origin,
          sejarahDanFilosofi: SejarahFilosofiModel(
            youtubeUrl: '',
            deskripsiUtama: c.sejarahDanFilosofi.deskripsiUtama,
            asalDaerah: c.sejarahDanFilosofi.asalDaerah,
            maknaFilosofis: c.sejarahDanFilosofi.maknaFilosofis,
            penggunaan: c.sejarahDanFilosofi.penggunaan,
          ),
          karakteristik: c.karakteristik,
          galeri: c.galeri,
          sumberRujukan: c.sumberRujukan,
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: provider,
          child: MaterialApp(home: ModuleDetailScreen(module: modForHeadless)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.text('Detail Modul'), findsOneWidget);

      // Geser dari Pilar 1 (Sejarah) ke Pilar 2 (Ciri Khas) -> historyDone = true (20%)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();

      var updated = provider.modules.firstWhere((m) => m.id == orig.id);
      expect(updated.historyDone, isTrue);
      expect(updated.progressPercent, equals(20));

      // Geser ke Pilar 3 (Galeri) -> characterDone = true (40%)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();

      updated = provider.modules.firstWhere((m) => m.id == orig.id);
      expect(updated.characterDone, isTrue);
      expect(updated.progressPercent, equals(40));

      // Geser ke Halaman 4 (Kuis) -> galleryDone = true (60%)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();

      updated = provider.modules.firstWhere((m) => m.id == orig.id);
      expect(updated.galleryDone, isTrue);
      expect(updated.progressPercent, equals(60));
    });
  });
}
