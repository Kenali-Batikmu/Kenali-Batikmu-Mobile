import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:batikmu/core/database/database_helper.dart';

/// Helper konfigurasi environment bersama untuk seluruh suite pengujian otomatis.
void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => call.method == 'check' ? ['none'] : null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final args = call.arguments;
        if (call.method == 'create' && args is Map && args['playerId'] is String) {
          messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/${args['playerId']}'),
            (_) async => null,
          );
        }
        return null;
      },
    );

    final db = await DatabaseHelper.instance.database;
    if (db != null) {
      await db.delete('scans');
      await db.delete('user_module_progress');
      await db.delete('quiz_attempts');
      await db.delete('users', where: 'id != ?', whereArgs: [1]);
      final u1 = await db.query('users', where: 'id = ?', whereArgs: [1]);
      if (u1.isEmpty) {
        await db.insert('users', {
          'id': 1,
          'name': 'Sekar Ayu Kinanti',
          'email': 'sekar@batikmu.id',
          'password_hash': 'demo_hash',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }
  });
}
