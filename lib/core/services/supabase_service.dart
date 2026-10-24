import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Layanan integrasi Cloud Supabase
/// Menangani sinkronisasi data pengguna, modul, dan kuis secara non-blocking
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isReady => _isInitialized && SupabaseConfig.isConfigured;

  SupabaseClient? get client => isReady ? Supabase.instance.client : null;

  /// Inisialisasi Supabase saat bootstrap aplikasi
  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('Supabase info: Anon key belum dikonfigurasi. Berjalan dalam mode SQLite lokal.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
      );
      _isInitialized = true;
      debugPrint('Supabase info: Berhasil terhubung ke cloud Supabase (${SupabaseConfig.url})');
    } catch (e) {
      _isInitialized = false;
      debugPrint('Supabase init warning: Gagal inisialisasi cloud Supabase: $e. Fallback ke SQLite lokal.');
    }
  }

  /// Sinkronisasi akun baru ke tabel users Supabase
  Future<bool> registerUser({
    required String name,
    required String email,
    required String passwordHash,
    String? phone,
  }) async {
    if (!isReady || client == null) return false;
    try {
      final now = DateTime.now().toIso8601String();
      await client!.from('users').insert({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone?.trim(),
        'password_hash': passwordHash,
        'created_at': now,
        'updated_at': now,
      });
      debugPrint('Supabase sync: Akun $email berhasil didaftarkan ke cloud Supabase');
      return true;
    } catch (e) {
      debugPrint('Supabase register error: $e');
      return false;
    }
  }

  /// Ambil data pengguna dari Supabase berdasarkan email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    if (!isReady || client == null) return null;
    try {
      final res = await client!
          .from('users')
          .select()
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Supabase getUserByEmail error: $e');
      return null;
    }
  }

  /// Perbarui profil pengguna di Supabase
  Future<bool> updateUserProfile({
    required String email,
    required String name,
    String? phone,
    String? profileImagePath,
  }) async {
    if (!isReady || client == null) return false;
    try {
      final now = DateTime.now().toIso8601String();
      final data = <String, dynamic>{
        'name': name.trim(),
        'updated_at': now,
      };
      if (phone != null) data['phone'] = phone.trim();
      if (profileImagePath != null) data['profile_image_path'] = profileImagePath;

      await client!
          .from('users')
          .update(data)
          .eq('email', email.trim().toLowerCase());
      debugPrint('Supabase sync: Profil $email berhasil diperbarui di cloud');
      return true;
    } catch (e) {
      debugPrint('Supabase updateUserProfile error: $e');
      return false;
    }
  }

  /// Upload foto profil ke bucket 'avatars' di Supabase Storage
  Future<String?> uploadAvatar({
    required String filePath,
    required String email,
  }) async {
    if (!isReady || client == null) return null;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final ext = filePath.split('.').last.toLowerCase();
      final cleanEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = 'avatar_${cleanEmail}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final fileBytes = await file.readAsBytes();
      await client!.storage.from('avatars').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(
          contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          upsert: true,
        ),
      );

      final publicUrl = client!.storage.from('avatars').getPublicUrl(fileName);
      debugPrint('Supabase Storage: Foto profil berhasil diupload: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase uploadAvatar error: $e');
      return null;
    }
  }

  /// Upload foto pengerjaan praktikum ke bucket 'practices' di Supabase Storage
  Future<String?> uploadPracticeImage({
    required String filePath,
    required String email,
    required int moduleId,
  }) async {
    if (!isReady || client == null) return null;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final ext = filePath.split('.').last.toLowerCase();
      final cleanEmail = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = 'practice_${cleanEmail}_mod${moduleId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final fileBytes = await file.readAsBytes();
      await client!.storage.from('practices').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(
          contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          upsert: true,
        ),
      );

      final publicUrl = client!.storage.from('practices').getPublicUrl(fileName);
      debugPrint('Supabase Storage: Foto praktikum modul $moduleId berhasil diupload: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase uploadPracticeImage error: $e');
      return null;
    }
  }

  /// Simpan riwayat kuis teori ke tabel quiz_attempts di Supabase
  Future<bool> saveQuizAttempt({
    required String userEmail,
    required int moduleId,
    required int score,
    required bool passed,
  }) async {
    if (!isReady || client == null) return false;
    try {
      final supaUser = await getUserByEmail(userEmail);
      if (supaUser == null) return false;
      final userId = supaUser['id'] as int;

      await client!.from('quiz_attempts').insert({
        'user_id': userId,
        'module_id': moduleId,
        'score': score,
        'passed': passed,
        'attempted_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Supabase sync: Kuis teori modul $moduleId berhasil disimpan ke cloud');
      return true;
    } catch (e) {
      debugPrint('Supabase saveQuizAttempt error: $e');
      return false;
    }
  }

  /// Simpan hasil praktikum kuis ke tabel scans di Supabase
  Future<bool> savePracticeScan({
    required String userEmail,
    required int moduleId,
    required double confidence,
    required bool passed,
    String? imageUrl,
  }) async {
    if (!isReady || client == null) return false;
    try {
      final supaUser = await getUserByEmail(userEmail);
      if (supaUser == null) return false;
      final userId = supaUser['id'] as int;

      await client!.from('scans').insert({
        'user_id': userId,
        'scan_type': 'kuismu',
        'module_id': moduleId,
        'image_path': imageUrl,
        'confidence': confidence,
        'fit_score': confidence,
        'passed': passed,
        'inference_time_ms': 120,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Supabase sync: Praktikum modul $moduleId berhasil disimpan ke cloud');
      return true;
    } catch (e) {
      debugPrint('Supabase savePracticeScan error: $e');
      return false;
    }
  }

  /// Sinkronkan status dan progres modul pengguna ke tabel user_module_progress di Supabase
  Future<bool> syncUserModuleProgress({
    required String userEmail,
    required int moduleId,
    required int progressPercent,
    required bool historyDone,
    required bool characterDone,
    required bool galleryDone,
    required bool quizDone,
    required bool practiceDone,
  }) async {
    if (!isReady || client == null) return false;
    try {
      final supaUser = await getUserByEmail(userEmail);
      if (supaUser == null) return false;
      final userId = supaUser['id'] as int;
      final now = DateTime.now().toIso8601String();
      final status = progressPercent >= 100
          ? 'completed'
          : (progressPercent > 0 ? 'in_progress' : 'not_started');

      await client!.from('user_module_progress').upsert(
        {
          'user_id': userId,
          'module_id': moduleId,
          'status': status,
          'progress_percent': progressPercent,
          'history_done': historyDone,
          'character_done': characterDone,
          'gallery_done': galleryDone,
          'quiz_done': quizDone,
          'practice_done': practiceDone,
          'completed_at': progressPercent >= 100 ? now : null,
          'last_accessed_at': now,
        },
        onConflict: 'user_id,module_id',
      );
      debugPrint('Supabase sync: Progres modul $moduleId ($progressPercent%) berhasil disinkronkan');
      return true;
    } catch (e) {
      debugPrint('Supabase syncUserModuleProgress error: $e');
      return false;
    }
  }
}
