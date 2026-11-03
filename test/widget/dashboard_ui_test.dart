import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:batikmu/providers/app_provider.dart';
import 'package:batikmu/screens/dashboard/dashboard_screen.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  void setupPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Pure Black-Box UI Widget Tests: Dashboard Screen Startup & Offline Guard', () {
    testWidgets('Dashboard renders safely without "Bad state: No element" error during initial frame / empty modules', (WidgetTester tester) async {
      setupPhoneViewport(tester);

      final appProvider = AppProvider();



      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>.value(
          value: appProvider,
          child: MaterialApp(
            home: DashboardScreen(
              onOpenModules: () {},
              onOpenScan: () {},
              onOpenProfile: () {},
            ),
          ),
        ),
      );


      // Verify that the first frame does not throw "Bad state: No element"
      expect(tester.takeException(), isNull);
      expect(find.text('Riwayat Belajar'), findsOneWidget);

      // Settle background timers
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
