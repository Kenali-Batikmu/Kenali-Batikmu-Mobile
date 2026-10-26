import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

      final savedPhoto = prefs.getString(_photoPrefKey);
      if (savedPhoto != null && (savedPhoto.startsWith('http') || kIsWeb || File(savedPhoto).existsSync())) {
        _savedPhotoPath = savedPhoto;
      }

      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (isLoggedIn && savedEmail != null && savedEmail.isNotEmpty) {
        final dbUser = await DatabaseHelper.instance.getUserByEmail(savedEmail);
        if (dbUser != null) {
          _currentUser = UserModel.fromMap(dbUser);
          if (_currentUser?.profileImagePath != null && _currentUser!.profileImagePath!.isNotEmpty) {
            _savedPhotoPath = _currentUser!.profileImagePath;
          }
        } else {
          // Coba ambil dari cloud Supabase jika terhubung
          final supaUser = await SupabaseService.instance.getUserByEmail(savedEmail);
          if (supaUser != null) {
            _currentUser = UserModel.fromMap(supaUser);
            if (_currentUser?.profileImagePath != null && _currentUser!.profileImagePath!.isNotEmpty) {
              _savedPhotoPath = _currentUser!.profileImagePath;
            }
            await DatabaseHelper.instance.insertUser(
              id: supaUser['id'] as int?,
              name: supaUser['name'] ?? '',
              email: savedEmail,
              passwordHash: supaUser['password_hash'] ?? '',
              phone: supaUser['phone'],
              profileImagePath: supaUser['profile_image_path'],
            );
          } else {
            _currentUser = null;
            await prefs.setBool('is_logged_in', false);
            await prefs.remove('logged_user_email');
            await prefs.remove('logged_user_name');
            await prefs.remove('logged_user_id');
          }
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
      _savedPhotoPath = path;
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImagePath: path);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoPrefKey, path);
      notifyListeners();

      if (_currentUser != null) {
        await DatabaseHelper.instance.updateUserProfile(
          userId: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          profileImagePath: path,
        );
      }

      final userEmail = _currentUser?.email;
      if (userEmail != null) {
        SupabaseService.instance.uploadAvatar(
          filePath: path,
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
    _savedPhotoPath = null;
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

      SupabaseService.instance.updateUserProfile(
        email: _currentUser!.email,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        profileImagePath: null,
      ).catchError((_) => false);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPrefKey);
    notifyListeners();
  }
}
