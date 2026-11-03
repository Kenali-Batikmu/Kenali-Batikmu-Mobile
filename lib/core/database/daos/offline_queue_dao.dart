import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object (DAO) untuk pengelolaan antrean sinkronisasi offline ke cloud Supabase
class OfflineQueueDao {
  final Future<Database?> Function() _getDb;

  OfflineQueueDao(this._getDb);

  /// Ambil seluruh riwayat kuis teori yang belum tersinkronkan ke cloud
  Future<List<Map<String, dynamic>>> getUnsyncedQuizAttempts(int userId, {String? userEmail}) async {
    final db = await _getDb();
    if (db == null) return [];
    try {
      if (userEmail != null && userEmail.trim().isNotEmpty) {
        return await db.rawQuery('''
          SELECT * FROM quiz_attempts 
          WHERE is_synced = 0 
            AND (user_id = ? OR user_id IN (SELECT id FROM users WHERE LOWER(email) = ?))
          ORDER BY id ASC
        ''', [userId, userEmail.trim().toLowerCase()]);
      }
      return await db.query(
        'quiz_attempts',
        where: 'user_id = ? AND is_synced = 0',
        whereArgs: [userId],
        orderBy: 'id ASC',
      );
    } catch (e) {
      debugPrint('OfflineQueueDao getUnsyncedQuizAttempts error: $e');
      return [];
    }
  }

  /// Tandai riwayat kuis teori sebagai sudah tersinkronkan
  Future<void> markQuizAttemptSynced(int id) async {
    final db = await _getDb();
    if (db == null) return;
    try {
      await db.update(
        'quiz_attempts',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('OfflineQueueDao markQuizAttemptSynced error: $e');
    }
  }

  /// Ambil seluruh pindaian/praktikum yang belum tersinkronkan ke cloud
  Future<List<Map<String, dynamic>>> getUnsyncedScans(int userId, {String? userEmail}) async {
    final db = await _getDb();
    if (db == null) return [];
    try {
      if (userEmail != null && userEmail.trim().isNotEmpty) {
        return await db.rawQuery('''
          SELECT * FROM scans 
          WHERE is_synced = 0 
            AND (user_id = ? OR user_id IN (SELECT id FROM users WHERE LOWER(email) = ?))
          ORDER BY id ASC
        ''', [userId, userEmail.trim().toLowerCase()]);
      }
      return await db.query(
        'scans',
        where: 'user_id = ? AND is_synced = 0',
        whereArgs: [userId],
        orderBy: 'id ASC',
      );
    } catch (e) {
      debugPrint('OfflineQueueDao getUnsyncedScans error: $e');
      return [];
    }
  }

  /// Tandai pindaian/praktikum sebagai sudah tersinkronkan
  Future<void> markScanSynced(int id) async {
    final db = await _getDb();
    if (db == null) return;
    try {
      await db.update(
        'scans',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('OfflineQueueDao markScanSynced error: $e');
    }
  }

  /// Ambil progres modul yang belum tersinkronkan ke cloud
  Future<List<Map<String, dynamic>>> getUnsyncedUserModuleProgress(int userId, {String? userEmail}) async {
    final db = await _getDb();
    if (db == null) return [];
    try {
      if (userEmail != null && userEmail.trim().isNotEmpty) {
        return await db.rawQuery('''
          SELECT * FROM user_module_progress 
          WHERE is_synced = 0 
            AND (user_id = ? OR user_id IN (SELECT id FROM users WHERE LOWER(email) = ?))
        ''', [userId, userEmail.trim().toLowerCase()]);
      }
      return await db.query(
        'user_module_progress',
        where: 'user_id = ? AND is_synced = 0',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('OfflineQueueDao getUnsyncedUserModuleProgress error: $e');
      return [];
    }
  }

  /// Tandai progres modul sebagai sudah tersinkronkan
  Future<void> markUserModuleProgressSynced(int userId, int moduleId) async {
    final db = await _getDb();
    if (db == null) return;
    try {
      await db.update(
        'user_module_progress',
        {'is_synced': 1},
        where: 'user_id = ? AND module_id = ?',
        whereArgs: [userId, moduleId],
      );
    } catch (e) {
      debugPrint('OfflineQueueDao markUserModuleProgressSynced error: $e');
    }
  }
}
