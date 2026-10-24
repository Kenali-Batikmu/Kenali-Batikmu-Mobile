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
}
