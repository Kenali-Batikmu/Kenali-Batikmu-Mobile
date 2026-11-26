import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batikmu/core/tour/app_tour.dart';
import 'package:batikmu/widgets/kb_coach_overlay.dart';
import '../test_helper.dart';

void _setViewport(WidgetTester tester, {Size size = const Size(1080, 2400), double dpr = 3.0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Halaman palsu dengan satu target di atas dan satu di bawah, ditutup overlay tur.
class _Harness extends StatelessWidget {
  final GlobalKey topKey;
  final GlobalKey bottomKey;
  final List<KbCoachStep> steps;
  final void Function(bool) onFinish;
  final VoidCallback onBehindTap;

  const _Harness({
    required this.topKey,
    required this.bottomKey,
    required this.steps,
    required this.onFinish,
    required this.onBehindTap,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 60,
                  right: 16,
                  child: GestureDetector(
                    onTap: onBehindTap,
                    child: Container(key: topKey, width: 48, height: 48, color: Colors.brown),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 40,
                  child: Container(key: bottomKey, width: 80, height: 60, color: Colors.amber),
                ),
              ],
            ),
          ),
          Positioned.fill(child: KbCoachOverlay(steps: steps, onFinish: onFinish)),
        ],
      ),
    );
  }
}

void main() {
  setupTestEnvironment();

  group('KbCoachOverlay', () {
    late GlobalKey topKey;
    late GlobalKey bottomKey;
    late List<KbCoachStep> steps;
    bool? finished;
    var behindTaps = 0;

    setUp(() {
      topKey = GlobalKey();
      bottomKey = GlobalKey();
      finished = null;
      behindTaps = 0;
      steps = [
        const KbCoachStep(
          icon: Icons.waving_hand_rounded,
          title: 'Selamat Datang',
          body: 'Sambutan',
        ),
        KbCoachStep(
          targetKey: bottomKey,
          icon: Icons.home_rounded,
          title: 'Langkah Bawah',
          body: 'Menjelaskan elemen bawah',
        ),
        KbCoachStep(
          targetKey: topKey,
          icon: Icons.person_rounded,
          title: 'Langkah Atas',
          body: 'Menjelaskan elemen atas',
          shape: KbCoachShape.circle,
        ),
      ];
    });

    Future<void> pumpTour(WidgetTester tester) async {
      _setViewport(tester);
      await tester.pumpWidget(_Harness(
        topKey: topKey,
        bottomKey: bottomKey,
        steps: steps,
        onFinish: (completed) => finished = completed,
        onBehindTap: () => behindTaps++,
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('dimulai dari sambutan lalu berurutan sampai selesai', (tester) async {
      await pumpTour(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.text('1 dari 3'), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);

      await tester.tap(find.byKey(const Key('kb_coach_next')));
      await tester.pumpAndSettle();
      expect(find.text('Langkah Bawah'), findsOneWidget);
      expect(find.text('2 dari 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('kb_coach_next')));
      await tester.pumpAndSettle();
      expect(find.text('Langkah Atas'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      // Tombol Lewati tidak ada di langkah terakhir
      expect(find.byKey(const Key('kb_coach_skip')), findsNothing);

      await tester.tap(find.byKey(const Key('kb_coach_next')));
      await tester.pumpAndSettle();
      expect(finished, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lewati menutup tur dengan completed = false', (tester) async {
      await pumpTour(tester);

      await tester.tap(find.byKey(const Key('kb_coach_skip')));
      await tester.pumpAndSettle();

      expect(finished, isFalse);
    });

    testWidgets('Kembali membuka langkah sebelumnya dan tidak ada di langkah pertama', (tester) async {
      await pumpTour(tester);
      expect(find.byKey(const Key('kb_coach_back')), findsNothing);

      await tester.tap(find.byKey(const Key('kb_coach_next')));
      await tester.pumpAndSettle();
      expect(find.text('Langkah Bawah'), findsOneWidget);

      await tester.tap(find.byKey(const Key('kb_coach_back')));
      await tester.pumpAndSettle();
      expect(find.text('Selamat Datang'), findsOneWidget);
    });

    testWidgets('ketukan pada elemen di balik lapisan gelap diserap', (tester) async {
      await pumpTour(tester);

      // Pindah ke langkah yang menyorot elemen atas, lalu coba ketuk elemennya
      await tester.tap(find.byKey(const Key('kb_coach_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('kb_coach_next')));
      await tester.pumpAndSettle();

      await tester.tapAt(tester.getCenter(find.byKey(topKey)));
      await tester.pumpAndSettle();

      expect(behindTaps, 0);
      expect(find.text('Langkah Atas'), findsOneWidget);
    });

    testWidgets('tombol kembali sistem mundur satu langkah, bukan menutup halaman', (tester) async {
      await pumpTour(tester);

      await tester.tap(find.byKey(const Key('kb_coach_next')));
      await tester.pumpAndSettle();
      expect(find.text('Langkah Bawah'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(finished, isNull);
    });
  });

  group('AppTourStore', () {
    test('belum selesai secara default, lalu tersimpan setelah markDone', () async {
      expect(await AppTourStore.isDone('budi@batikmu.id'), isFalse);
      await AppTourStore.markDone('budi@batikmu.id');
      expect(await AppTourStore.isDone('budi@batikmu.id'), isTrue);
    });

    test('status dicatat per akun dan tidak peka huruf besar-kecil', () async {
      await AppTourStore.markDone('Budi@Batikmu.id');
      expect(await AppTourStore.isDone('budi@batikmu.id'), isTrue);
      expect(await AppTourStore.isDone('sekar@batikmu.id'), isFalse);
    });

    test('reset membuat tur tampil lagi', () async {
      await AppTourStore.markDone('budi@batikmu.id');
      await AppTourStore.reset('budi@batikmu.id');
      expect(await AppTourStore.isDone('budi@batikmu.id'), isFalse);
    });

    test('tidak mengganggu flag onboarding lain', () async {
      SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
      await AppTourStore.markDone('budi@batikmu.id');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_onboarding'), isTrue);
    });
  });
}
