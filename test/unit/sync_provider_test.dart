import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:batikmu/core/config/env_config.dart';
import 'package:batikmu/core/database/database_helper.dart';
import 'package:batikmu/models/app_models.dart';
import 'package:batikmu/providers/sync_provider.dart';
import '../test_helper.dart';

void main() {
  setupTestEnvironment();

  group('QC Unit Tests: SyncProvider (Offline Guards & Connectivity Lifecycle)', () {
    const connectivityMethodChannel =
        MethodChannel('dev.fluttercommunity.plus/connectivity');
    const connectivityEventChannelName =
        'dev.fluttercommunity.plus/connectivity_status';

    late SyncProvider syncProvider;

    setUp(() {
      EnvConfig.resetForTest();
      syncProvider = SyncProvider();
    });

    tearDown(() {
      syncProvider.disposeListener();
      EnvConfig.resetForTest();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectivityMethodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(connectivityEventChannelName),
        null,
      );
    });

    test('syncMasterDataFromCloud fail-safe saat Supabase belum aktif dan tidak memanggil callback', () async {
      bool callbackCalled = false;
      final ok = await syncProvider.syncMasterDataFromCloud(
        onMasterDataUpdated: (_, _) => callbackCalled = true,
        userId: 1,
        userEmail: 'sekar@batikmu.id',
      );

      expect(ok, isFalse);
      expect(callbackCalled, isFalse);
    });

    test('syncUserProgressFromServer fail-safe saat offline/unconfigured tanpa crash', () async {
      final user = UserModel(
        id: 1,
        name: 'Sekar Ayu Kinanti',
        email: 'sekar@batikmu.id',
      );

      bool reloadCalled = false;
      bool historiesCalled = false;

      final ok = await syncProvider.syncUserProgressFromServer(
        currentUser: user,
        onReloadProgress: (_) async => reloadCalled = true,
        onHistoriesUpdated: (_) => historiesCalled = true,
      );

      expect(ok, isFalse);
      expect(reloadCalled, isFalse);
      expect(historiesCalled, isFalse);
    });

    test('processOfflineQueue mempertahankan seluruh antrean lokal saat cloud belum siap (zero data loss)', () async {
      final user = UserModel(
        id: 1,
        name: 'Sekar Ayu Kinanti',
        email: 'sekar@batikmu.id',
      );

      await DatabaseHelper.instance.saveQuizAttempt(
        userId: 1,
        moduleId: 1,
        score: 85,
        passed: true,
        isSynced: false,
      );
      await DatabaseHelper.instance.savePracticeAttempt(
        userId: 1,
        moduleId: 1,
        confidence: 0.90,
        passed: true,
        isSynced: false,
      );

      final syncedCount = await syncProvider.processOfflineQueue(currentUser: user);
      expect(syncedCount, equals(0));

      // Pastikan data antrean offline TIDAK hilang atau ditandai synced palsu
      final unsyncedQuizzes = await DatabaseHelper.instance.getUnsyncedQuizAttempts(
        1,
        userEmail: user.email,
      );
      final unsyncedScans = await DatabaseHelper.instance.getUnsyncedScans(
        1,
        userEmail: user.email,
      );
      expect(unsyncedQuizzes.length, greaterThanOrEqualTo(1));
      expect(unsyncedScans.length, greaterThanOrEqualTo(1));
    });

    test('[Lifecycle & Transition QC] connectivity listener hanya memicu onReconnect saat pulih dari offline dan berhenti setelah disposeListener', () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      // Kondisi awal: online (wifi)
      messenger.setMockMethodCallHandler(connectivityMethodChannel, (call) async {
        if (call.method == 'check') return ['wifi'];
        return null;
      });
      messenger.setMockMethodCallHandler(
        const MethodChannel(connectivityEventChannelName),
        (call) async => null,
      );

      int reconnectCount = 0;
      syncProvider.setupConnectivityListener(() async {
        reconnectCount++;
      });

      // Beri waktu checkConnectivity awal selesai
      await Future<void>.delayed(const Duration(milliseconds: 50));

      Future<void> emitConnectivity(List<String> values) async {
        final encoded = const StandardMethodCodec().encodeSuccessEnvelope(values);
        await messenger.handlePlatformMessage(
          connectivityEventChannelName,
          encoded,
          (_) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }

      // 1. Transisi wifi -> wifi (belum pernah offline):
      // Standar efisiensi jaringan/baterai mobile: tidak boleh memicu sync berulang saat status tetap online.
      await emitConnectivity(['wifi']);
      final countAfterRedundantOnline = reconnectCount;

      // 2. Transisi wifi -> none (menjadi offline): tidak boleh memicu sync.
      await emitConnectivity(['none']);
      final countAfterOffline = reconnectCount;

      // 3. Transisi none -> wifi (pulih dari offline): WAJIB memicu onReconnect tepat 1 kali.
      await emitConnectivity(['wifi']);
      final countAfterReconnect = reconnectCount;

      // 4. Setelah disposeListener(), event baru tidak boleh lagi memicu callback.
      syncProvider.disposeListener();
      await emitConnectivity(['none']);
      await emitConnectivity(['wifi']);
      final countAfterDispose = reconnectCount;

      expect(
        countAfterRedundantOnline,
        equals(0),
        reason:
            'Status tetap online (wifi -> wifi tanpa pernah offline) tidak boleh memicu redundant reconnect sync',
      );
      expect(countAfterOffline, equals(countAfterRedundantOnline));
      expect(countAfterReconnect, equals(countAfterOffline + 1));
      expect(countAfterDispose, equals(countAfterReconnect));
    });
  });
}
