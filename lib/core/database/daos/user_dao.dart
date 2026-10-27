import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object (DAO) untuk pengelolaan akun dan profil pengguna di SQLite lokal
class UserDao {
  final Future<Database?> Function() _getDb;

  UserDao(this._getDb);

  /// Cek apakah email terdaftar dalam tabel users
  Future<bool> checkEmailExists(String email) async {
    final clean = email.trim().toLowerCase();
    final db = await _getDb();
    if (db == null) return false;
    try {
      final res = await db.query(
        'users',
        columns: ['id'],
        where: 'LOWER(email) = ?',
        whereArgs: [clean],
        limit: 1,
      );
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Ambil data user berdasarkan email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final clean = email.trim().toLowerCase();
    final db = await _getDb();
    if (db != null) {
      try {
        final res = await db.query(
          'users',
          where: 'LOWER(email) = ?',
          whereArgs: [clean],
          limit: 1,
        );
        if (res.isNotEmpty) return res.first;
      } catch (_) {}
    }
    return null;
  }

  /// Perbarui kata sandi pengguna (password hash)
  Future<bool> updateUserPassword(String email, String newPasswordHash) async {
    final db = await _getDb();
    if (db == null) return false;
    try {
      final clean = email.trim().toLowerCase();
      final now = DateTime.now().toIso8601String();
      final count = await db.update(
        'users',
        {
          'password_hash': newPasswordHash,
          'updated_at': now,
        },
        where: 'LOWER(email) = ?',
        whereArgs: [clean],
      );
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  /// Menambahkan akun pengguna baru ke SQLite lokal
  Future<int> insertUser({
    int? id,
    required String name,
    required String email,
    required String passwordHash,
    String? phone,
    String? profileImagePath,
  }) async {
    final db = await _getDb();
    if (db == null) return -1;
    try {
      final cleanEmail = email.trim().toLowerCase();
      final now = DateTime.now().toIso8601String();
      final data = <String, dynamic>{
        'name': name.trim(),
        'email': cleanEmail,
        'phone': phone?.trim(),
        'password_hash': passwordHash,
        'profile_image_path': profileImagePath,
        'created_at': now,
        'updated_at': now,
      };
      if (id != null) {
        data['id'] = id;
      }

      // Cek apakah user dengan email ini sudah ada di SQLite
      final existing = await db.query(
        'users',
        columns: ['id'],
        where: 'LOWER(email) = ?',
        whereArgs: [cleanEmail],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        await db.update('users', data, where: 'LOWER(email) = ?', whereArgs: [cleanEmail]);
        return id ?? existingId;
      } else {
        final newId = await db.insert(
          'users',
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return newId;
      }
    } catch (e) {
      debugPrint('UserDao insertUser error: $e');
      return -1;
    }
  }

  /// Memperbarui informasi profil pengguna di SQLite lokal
  Future<bool> updateUserProfile({
    required int userId,
    required String name,
    required String email,
    String? phone,
    String? profileImagePath,
  }) async {
    final db = await _getDb();
    if (db == null) return false;
    try {
      final now = DateTime.now().toIso8601String();
      final map = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'updated_at': now,
      };
      if (phone != null) map['phone'] = phone.trim();
      if (profileImagePath != null) map['profile_image_path'] = profileImagePath;

      final count = await db.update(
        'users',
        map,
        where: 'id = ?',
        whereArgs: [userId],
      );
      return count > 0;
    } catch (e) {
      debugPrint('UserDao updateUserProfile error: $e');
      return false;
    }
  }
}
