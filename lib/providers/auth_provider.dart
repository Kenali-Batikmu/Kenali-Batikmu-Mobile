import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/email_service.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/password_hasher.dart';
import '../models/app_models.dart';

/// Provider pengelola otentikasi akun, profil pengguna, dan pemulihan kata sandi
class AuthProvider with ChangeNotifier {
  static const String _photoPrefKey = 'profile_image_path';

  UserModel? _currentUser;
  String? _savedPhotoPath;
  bool _isLoading = false;
  String? _errorMessage;

  String? _resetTargetEmail;
  String? _resetOtpCode;
  DateTime? _resetOtpExpiresAt;
  final Map<String, String> _inMemoryPasswordHashes = {};

  UserModel? get currentUser => _currentUser;
  String? get savedPhotoPath => _savedPhotoPath;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get resetTargetEmail => _resetTargetEmail;
  String? get activeResetOtp => _resetOtpCode;
  bool get hasActiveResetOtp => _resetOtpCode != null;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setErrorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  /// Inisialisasi sesi login dan foto profil dari preferensi lokal / database
  Future<void> initSession({String? savedEmail}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (isLoggedIn && savedEmail != null && savedEmail.isNotEmpty) {
        final cleanEmail = savedEmail.trim().toLowerCase();
        final safeEmail = cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

        // 1. Cek apakah ada file foto avatar permanen di direktori lokal perangkat
        if (!kIsWeb) {
          try {
            final docsDir = await getApplicationDocumentsDirectory();
            final localAvatarFile = File('${docsDir.path}/avatar_$safeEmail.jpg');
            if (localAvatarFile.existsSync()) {
              _savedPhotoPath = localAvatarFile.path;
            }
          } catch (_) {}
        }

        final dbUser = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
        if (dbUser != null) {
          _currentUser = UserModel.fromMap(dbUser);
          if (_savedPhotoPath != null) {
            _currentUser = _currentUser!.copyWith(profileImagePath: _savedPhotoPath);
          } else if (_currentUser?.profileImagePath != null && _currentUser!.profileImagePath!.isNotEmpty) {
            _savedPhotoPath = _currentUser!.profileImagePath;
          }
        } else {
          // Coba ambil dari cloud Supabase jika terhubung
          final supaUser = await SupabaseService.instance.getUserByEmail(cleanEmail);
          if (supaUser != null) {
            _currentUser = UserModel.fromMap(supaUser);
            if (_savedPhotoPath != null) {
              _currentUser = _currentUser!.copyWith(profileImagePath: _savedPhotoPath);
            } else if (_currentUser?.profileImagePath != null && _currentUser!.profileImagePath!.isNotEmpty) {
              _savedPhotoPath = _currentUser!.profileImagePath;
            }
            await DatabaseHelper.instance.insertUser(
              id: supaUser['id'] as int?,
              name: supaUser['name'] ?? '',
              email: cleanEmail,
              passwordHash: supaUser['password_hash'] ?? '',
              phone: supaUser['phone'],
              profileImagePath: _savedPhotoPath ?? supaUser['profile_image_path'],
            );
          } else {
            _currentUser = null;
            await prefs.setBool('is_logged_in', false);
            await prefs.remove('logged_user_email');
            await prefs.remove('logged_user_name');
            await prefs.remove('logged_user_id');
          }
        }

        // 2. Jika foto berupa URL cloud dan belum tersimpan di lokal HP, unduh di background
        if (!kIsWeb && _savedPhotoPath != null && _savedPhotoPath!.startsWith('http')) {
          _cacheRemoteAvatarLocally(_savedPhotoPath!, safeEmail);
        }
      } else {
        _currentUser = null;
      }

      _applySavedPhoto();
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider initSession error: $e');
    }
  }

  /// Unduh foto avatar dari cloud ke disk lokal agar selalu bisa dibuka saat offline
  Future<void> _cacheRemoteAvatarLocally(String remoteUrl, String safeEmail) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final localFile = File('${docsDir.path}/avatar_$safeEmail.jpg');
      final response = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await localFile.writeAsBytes(response.bodyBytes);
        _savedPhotoPath = localFile.path;
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(profileImagePath: localFile.path);
          await DatabaseHelper.instance.updateUserProfile(
            userId: _currentUser!.id,
            name: _currentUser!.name,
            email: _currentUser!.email,
            phone: _currentUser!.phone,
            profileImagePath: localFile.path,
          );
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  void _applySavedPhoto() {
    if (_currentUser != null && _savedPhotoPath != null) {
      _currentUser = _currentUser!.copyWith(profileImagePath: _savedPhotoPath);
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 250));

    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Format email tidak valid';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (cleanPass.length < 8) {
      _errorMessage = 'Kata sandi minimal 8 karakter';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    Map<String, dynamic>? userRecord;

    // 1. Jika terhubung ke Cloud Supabase: Utamakan cek ke Server (Single Source of Truth)
    if (SupabaseService.instance.isReady) {
      final supaUser = await SupabaseService.instance.getUserByEmail(cleanEmail);
      if (supaUser != null) {
        userRecord = Map<String, dynamic>.from(supaUser);
        if (!kIsWeb) {
          await DatabaseHelper.instance.insertUser(
            id: supaUser['id'] as int?,
            name: supaUser['name'] ?? '',
            email: cleanEmail,
            passwordHash: supaUser['password_hash'] ?? PasswordHasher.hashPassword(cleanPass),
            phone: supaUser['phone'],
            profileImagePath: supaUser['profile_image_path'],
          );
        }
      }
    }

    // 2. Jika offline atau belum ditemukan di server: Cek ke SQLite lokal
    if (userRecord == null && !kIsWeb) {
      userRecord = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
    }

    // 3. Jika user TIDAK ADA di server maupun di SQLite lokal: Tolak login!
    if (userRecord == null) {
      if (!SupabaseService.instance.isReady) {
        _errorMessage = 'Tidak dapat terhubung ke server. Pastikan kamu punya koneksi internet untuk login pertama kali.';
      } else {
        _errorMessage = 'Akun belum terdaftar. Silakan registrasi terlebih dahulu.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // 4. Validasi Password Asli (Salted SHA-256)
    final storedHash = userRecord['password_hash'] as String?;
    if (storedHash == null || storedHash.isEmpty || !PasswordHasher.verify(cleanPass, storedHash)) {
      _errorMessage = 'Kata sandi salah. Silakan periksa kembali.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final rawName = (userRecord['name'] as String? ?? '').trim();
    final userName = rawName.isNotEmpty ? rawName : cleanEmail.split('@').first;

    final dbPhoto = userRecord['profile_image_path'] as String?;
    final userPhoto = (dbPhoto != null && dbPhoto.isNotEmpty) ? dbPhoto : _savedPhotoPath;
    if (userPhoto != null && userPhoto.isNotEmpty) {
      _savedPhotoPath = userPhoto;
    }

    _currentUser = UserModel(
      id: userRecord['id'] as int? ?? 1,
      name: userName,
      email: cleanEmail,
      phone: userRecord['phone'] as String?,
      profileImagePath: userPhoto,
      createdAt: userRecord['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );

    // Sinkronkan data terbaru dari Supabase jika ada pembaruan di cloud
    SupabaseService.instance.getUserByEmail(cleanEmail).then((supaUser) {
      if (supaUser != null) {
        final cloudName = supaUser['name'] as String?;
        final cloudPhoto = supaUser['profile_image_path'] as String?;
        final cloudPhone = supaUser['phone'] as String?;
        bool changed = false;
        String currentName = _currentUser?.name ?? '';
        if (cloudName != null && cloudName.trim().isNotEmpty && currentName != cloudName) {
          currentName = cloudName.trim();
          changed = true;
        }
        if (cloudPhoto != null && cloudPhoto.isNotEmpty && cloudPhoto != _savedPhotoPath) {
          _savedPhotoPath = cloudPhoto;
          changed = true;
        }
        if (cloudPhone != null && cloudPhone.isNotEmpty) {
          changed = true;
        }
        if (changed) {
          _currentUser = _currentUser?.copyWith(
            name: currentName,
            profileImagePath: _savedPhotoPath,
            phone: cloudPhone,
          );
          DatabaseHelper.instance.updateUserProfile(
            userId: _currentUser?.id ?? 1,
            name: currentName,
            email: cleanEmail,
            phone: cloudPhone,
            profileImagePath: _savedPhotoPath,
          );
          SharedPreferences.getInstance().then((p) => p.setString('logged_user_name', currentName));
          notifyListeners();
        }
      }
    }).catchError((_) {});

    _isLoading = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      if (rememberMe) {
        await prefs.setInt('logged_user_id', _currentUser?.id ?? 1);
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('logged_user_email', cleanEmail);
      } else {
        await prefs.remove('logged_user_id');
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('logged_user_email');
      }
    } catch (_) {}

    return true;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 250));

    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      _errorMessage = 'Nama lengkap wajib diisi';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Format email tidak valid';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final cleanPass = password.trim();
    if (cleanPass.length < 8) {
      _errorMessage = 'Kata sandi minimal 8 karakter';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final passwordHash = PasswordHasher.hashPassword(cleanPass);
    _inMemoryPasswordHashes[cleanEmail] = passwordHash;

    int newId = await DatabaseHelper.instance.insertUser(
      name: cleanName,
      email: cleanEmail,
      passwordHash: passwordHash,
      profileImagePath: _savedPhotoPath,
    );
    if (newId <= 0) {
      newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    SupabaseService.instance.registerUser(
      name: cleanName,
      email: cleanEmail,
      passwordHash: passwordHash,
    ).then((ok) {
      if (ok) debugPrint('Cloud sync register: $cleanEmail berhasil disimpan ke Supabase');
    }).catchError((e) {
      debugPrint('Cloud sync register fallback: $e');
    });

    _currentUser = UserModel(
      id: newId,
      name: cleanName,
      email: cleanEmail,
      profileImagePath: _savedPhotoPath,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      await prefs.setBool('is_logged_in', true);
      await prefs.setInt('logged_user_id', newId);
      await prefs.setString('logged_user_email', cleanEmail);
      await prefs.setString('logged_user_name', cleanName);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_user_id');
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('logged_user_email');
    } catch (_) {}
    _currentUser = null;
    notifyListeners();
  }

  Future<EmailSendResult> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(cleanEmail)) {
      _errorMessage = 'Format email tidak valid';
      _isLoading = false;
      notifyListeners();
      return const EmailSendResult(
        isSuccess: false,
        isDemoSimulated: false,
        message: 'Format email tidak valid',
      );
    }

    bool isRegistered = false;
    String recipientName = cleanEmail.split('@').first;

    final dbUser = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
    if (dbUser != null) {
      isRegistered = true;
      final raw = (dbUser['name'] as String? ?? '').trim();
      if (raw.isNotEmpty) recipientName = raw;
    } else {
      final supaUser = await SupabaseService.instance.getUserByEmail(cleanEmail);
      if (supaUser != null) {
        isRegistered = true;
        final raw = (supaUser['name'] as String? ?? '').trim();
        if (raw.isNotEmpty) recipientName = raw;
      }
    }

    if (!isRegistered) {
      _errorMessage = 'Email tidak terdaftar dalam sistem';
      _isLoading = false;
      notifyListeners();
      return const EmailSendResult(
        isSuccess: false,
        isDemoSimulated: false,
        message: 'Email belum terdaftar di Kenali Batikmu',
      );
    }

    final otp = (1000 + Random().nextInt(9000)).toString();
    _resetTargetEmail = cleanEmail;
    _resetOtpCode = otp;
    _resetOtpExpiresAt = DateTime.now().add(const Duration(minutes: 5));

    final result = await EmailService.sendPasswordResetOtp(
      recipientEmail: cleanEmail,
      recipientName: recipientName,
      otpCode: otp,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  bool verifyResetOtp(String inputOtp) {
    if (_resetOtpCode == null || _resetOtpExpiresAt == null) {
      _errorMessage = 'Sesi pemulihan tidak valid. Silakan minta kode baru.';
      notifyListeners();
      return false;
    }

    if (DateTime.now().isAfter(_resetOtpExpiresAt!)) {
      _errorMessage = 'Kode OTP telah kedaluwarsa. Silakan kirim ulang.';
      notifyListeners();
      return false;
    }

    if (inputOtp.trim() != _resetOtpCode) {
      _errorMessage = 'Kode verifikasi salah. Periksa kembali kode Anda.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> finalizePasswordReset(String newPassword) async {
    if (_resetTargetEmail == null) {
      _errorMessage = 'Sesi pemulihan telah berakhir';
      notifyListeners();
      return false;
    }

    final cleanPass = newPassword.trim();
    if (cleanPass.length < 8) {
      _errorMessage = 'Kata sandi baru minimal 8 karakter';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newHash = PasswordHasher.hashPassword(cleanPass);
    final targetEmail = _resetTargetEmail!;

    await DatabaseHelper.instance.updateUserPassword(targetEmail, newHash);
    _inMemoryPasswordHashes[targetEmail] = newHash;

    _resetTargetEmail = null;
    _resetOtpCode = null;
    _resetOtpExpiresAt = null;

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        name: cleanName,
        email: cleanEmail,
        phone: cleanPhone,
      );
      notifyListeners();

      await DatabaseHelper.instance.updateUserProfile(
        userId: _currentUser!.id,
        name: cleanName,
        email: cleanEmail,
        phone: cleanPhone,
        profileImagePath: _savedPhotoPath,
      );

      if (password.isNotEmpty && password.length >= 8) {
        final newHash = PasswordHasher.hashPassword(password);
        _inMemoryPasswordHashes[cleanEmail] = newHash;
        await DatabaseHelper.instance.updateUserPassword(cleanEmail, newHash);
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_user_name', cleanName);
        await prefs.setString('logged_user_email', cleanEmail);
        await prefs.setString('logged_user_phone', cleanPhone);
      } catch (_) {}

      SupabaseService.instance.updateUserProfile(
        email: cleanEmail,
        name: cleanName,
        phone: cleanPhone,
        profileImagePath: _savedPhotoPath,
      ).catchError((e) {
        debugPrint('Cloud sync profile update fallback: $e');
        return false;
      });
    }
  }

  Future<bool> setProfilePhoto(String path) async {
    try {
      final userEmail = _currentUser?.email;
      String localPermanentPath = path;

      // 1. Simpan foto ke direktori permanen lokal (1 file per pengguna: menimpa yang lama)
      if (!kIsWeb && userEmail != null) {
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final safeEmail = userEmail.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
          final permanentFile = File('${docsDir.path}/avatar_$safeEmail.jpg');
          final fileBytes = await File(path).readAsBytes();
          await permanentFile.writeAsBytes(fileBytes);
          localPermanentPath = permanentFile.path;
        } catch (e) {
          debugPrint('Gagal menyalin avatar ke direktori lokal: $e');
        }
      }

      _savedPhotoPath = localPermanentPath;
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImagePath: localPermanentPath);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoPrefKey, localPermanentPath);
      notifyListeners();

      if (_currentUser != null) {
        await DatabaseHelper.instance.updateUserProfile(
          userId: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          profileImagePath: localPermanentPath,
        );
      }

      // 2. Upload ke Supabase Storage (menimpa file lama di cloud)
      if (userEmail != null) {
        SupabaseService.instance.uploadAvatar(
          filePath: localPermanentPath,
          email: userEmail,
        ).then((publicUrl) async {
          if (publicUrl != null) {
            await SupabaseService.instance.updateUserProfile(
              email: userEmail,
              name: _currentUser?.name ?? '',
              phone: _currentUser?.phone,
              profileImagePath: publicUrl,
            );
          }
        }).catchError((e) {
          debugPrint('Cloud sync avatar fallback: $e');
        });
      }

      return true;
    } catch (e) {
      debugPrint('setProfilePhoto error: $e');
      return false;
    }
  }

  Future<void> removeProfilePhoto() async {
    final userEmail = _currentUser?.email;
    _savedPhotoPath = null;

    // Hapus file avatar lokal jika ada
    if (!kIsWeb && userEmail != null) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final safeEmail = userEmail.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final localFile = File('${docsDir.path}/avatar_$safeEmail.jpg');
        if (localFile.existsSync()) {
          localFile.deleteSync();
        }
      } catch (_) {}
    }

    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        profileImagePath: null,
        createdAt: _currentUser!.createdAt,
      );

      await DatabaseHelper.instance.updateUserProfile(
        userId: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        profileImagePath: null,
      );

      if (userEmail != null) {
        SupabaseService.instance.deleteAvatar(userEmail).catchError((_) => false);
        SupabaseService.instance.updateUserProfile(
          email: userEmail,
          name: _currentUser!.name,
          phone: _currentUser!.phone,
          profileImagePath: null,
        ).catchError((_) => false);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPrefKey);
    notifyListeners();
  }
}
