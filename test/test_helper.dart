import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:batikmu/core/database/database_helper.dart';

/// Helper konfigurasi environment bersama untuk seluruh suite pengujian otomatis.
void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
