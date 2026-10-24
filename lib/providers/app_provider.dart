import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/email_service.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/password_hasher.dart';
import '../models/app_models.dart';

class AppProvider with ChangeNotifier {
  static const String _photoPrefKey = 'profile_image_path';

  UserModel? _currentUser;
  String? _savedPhotoPath; // path foto profil tersimpan (file lokal di folder aplikasi)
  bool _isLoading = false;
  String? _errorMessage;

  String? _resetTargetEmail;
  String? _resetOtpCode;
  DateTime? _resetOtpExpiresAt;
  final Map<String, String> _inMemoryPasswordHashes = {};

  List<ModuleModel> _modules = [];
  List<BatikMotifModel> _motifs = [];
  List<ScanHistoryModel> _scanHistories = [];
  bool _isDarkMode = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOffline = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ModuleModel> get modules => _modules;
  List<BatikMotifModel> get motifs => _motifs;
  List<ScanHistoryModel> get scanHistories => _scanHistories;
  bool get isDarkMode => _isDarkMode;

  // Getters Pemulihan Kata Sandi
  String? get resetTargetEmail => _resetTargetEmail;
  String? get activeResetOtp => _resetOtpCode;
  bool get hasActiveResetOtp => _resetOtpCode != null;

  // Stats kalkulasi dinamis sesuai PDF Page 3 & Page 12
  int get completedModulesCount => _modules.where((m) => m.progressPercent >= 100).length;
  int get totalModulesCount => _modules.length;
  int get overallProgressPercent => totalModulesCount > 0 ? ((completedModulesCount / totalModulesCount) * 100).round() : 0;
  int get scannedMotifsCount => _scanHistories.length;

  AppProvider({bool initialIsLoggedIn = false, String? initialEmail}) {
    _initInMemoryDefaultData(isLoggedIn: initialIsLoggedIn, userEmail: initialEmail);
    initApp();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
    _saveThemePref(value);
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Pasang listener koneksi: saat internet kembali aktif setelah offline,
  /// jalankan background sync dan proses antrian offline secara otomatis.
  void _setupConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
      final isOffline = results.every((r) => r == ConnectivityResult.none);
      if (_wasOffline && !isOffline) {
        debugPrint('Connectivity: sinyal kembali aktif, mulai background sync antrian offline');
        await _syncBackground();
      }
      _wasOffline = isOffline;
    });
  }

  Future<void> _saveThemePref(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', value);
    } catch (_) {}
  }

  void _initInMemoryDefaultData({bool isLoggedIn = false, String? userEmail}) {
    _currentUser = null;
    _motifs = [];
    _modules = [];
    _scanHistories = [];
  }

  Future<void>? _initFuture;

  Future<void> initApp() {
    _initFuture ??= _runInitApp().whenComplete(() {
      _initFuture = null;
    });
    return _initFuture!;
  }

  Future<void> _runInitApp() async {
    _isLoading = false; // Memastikan UI instan tidak terhalang
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;

      // Muat foto profil tersimpan (hanya jika filenya masih ada atau URL cloud)
      final savedPhoto = prefs.getString(_photoPrefKey);
      if (savedPhoto != null && (savedPhoto.startsWith('http') || kIsWeb || File(savedPhoto).existsSync())) {
        _savedPhotoPath = savedPhoto;
      }

      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      String? savedEmail;
      if (isLoggedIn) {
        savedEmail = prefs.getString('logged_user_email');
        if (savedEmail != null && savedEmail.isNotEmpty) {
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
              // Cache ke SQLite lokal dengan data aslinya
              await DatabaseHelper.instance.insertUser(
                id: supaUser['id'] as int?,
                name: supaUser['name'] ?? '',
                email: savedEmail,
                passwordHash: supaUser['password_hash'] ?? '',
                phone: supaUser['phone'],
                profileImagePath: supaUser['profile_image_path'],
              );
            } else {
              // Jika data user tidak ditemukan di SQLite maupun Supabase, batalkan sesi (jangan fabrikasi akun palsu)
              _currentUser = null;
              await prefs.setBool('is_logged_in', false);
              await prefs.remove('logged_user_email');
              await prefs.remove('logged_user_name');
              await prefs.remove('logged_user_id');
            }
          }
        } else {
          _currentUser = null;
          await prefs.setBool('is_logged_in', false);
        }
      } else {
        _currentUser = null;
      }

      // 3. Muat data master dari SQLite lokal (20 Modul & 20 Motif)
      final db = await DatabaseHelper.instance.database;
      if (db != null) {
        final dbMotifs = await DatabaseHelper.instance.getAllMotifs();
        if (dbMotifs.isNotEmpty) {
          _motifs = dbMotifs;
        }

        final dbModules = await DatabaseHelper.instance.getAllModules(
          userId: _currentUser?.id,
          userEmail: _currentUser?.email,
        );
        if (dbModules.isNotEmpty) {
          _modules = dbModules;
        }

        final histories = await DatabaseHelper.instance.getScanHistories(
          _currentUser?.id,
          userEmail: _currentUser?.email,
        );
        _scanHistories = histories;
      }

      // 4. Rekonsiliasi progres modul khusus milik user yang login
      if (_currentUser != null && savedEmail != null) {
        await _loadUserModuleProgress(savedEmail);
      } else {
        _resetModuleProgressInMemory();
      }
    } catch (e) {
      debugPrint('Info sync SQLite: $e');
    } finally {
      _applySavedPhoto();
      notifyListeners();
      // Sinkronisasi background terurut tanpa race condition
      _syncBackground();
      // Pasang listener koneksi setelah init selesai
      _setupConnectivityListener();
    }
  }

  /// Sinkronisasi background berurutan (sequential) untuk mencegah race condition
  Future<void> _syncBackground() async {
    try {
      await syncMasterDataFromCloud();
      // 1. Upload antrean aktivitas offline ke cloud terlebih dahulu (Local-First Push)
      await processOfflineQueue();
      // 2. Baru kemudian tarik data terbaru dari cloud jika ada (dengan proteksi anti-timpa)
      if (_currentUser != null) {
        await syncUserProgressFromServer();
      }
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  /// Sinkronkan master data (motif dan modul) dari Cloud Supabase ke SQLite lokal
  Future<bool> syncMasterDataFromCloud() async {
    if (!SupabaseService.instance.isReady) return false;
    try {
      final cloudMotifs = await SupabaseService.instance.fetchMotifs();
      if (cloudMotifs.isNotEmpty) {
        await DatabaseHelper.instance.upsertMotifs(cloudMotifs);
        final updatedMotifs = await DatabaseHelper.instance.getAllMotifs();
        if (updatedMotifs.isNotEmpty) {
          _motifs = updatedMotifs;
        }
      }

      final cloudModules = await SupabaseService.instance.fetchModules();
      if (cloudModules.isNotEmpty) {
        await DatabaseHelper.instance.upsertModules(cloudModules);
        final updatedModules = await DatabaseHelper.instance.getAllModules(
          userId: _currentUser?.id,
          userEmail: _currentUser?.email,
        );
        if (updatedModules.isNotEmpty) {
          // Preservasi progres modul yang sedang aktif di memori agar tidak tertimpa race condition
          _modules = updatedModules.map((newMod) {
            final existingIndex = _modules.indexWhere((m) => m.id == newMod.id);
            if (existingIndex == -1) return newMod;
            final existing = _modules[existingIndex];
            final merged = newMod.copyWith(
              historyDone: existing.historyDone || newMod.historyDone,
              characterDone: existing.characterDone || newMod.characterDone,
              galleryDone: existing.galleryDone || newMod.galleryDone,
              quizDone: existing.quizDone || newMod.quizDone,
              practiceDone: existing.practiceDone || newMod.practiceDone,
              quizScore: existing.quizScore ?? newMod.quizScore,
              practiceScore: existing.practiceScore ?? newMod.practiceScore,
            );
            return merged.copyWith(
              progressPercent: merged.calculateProgressPercent(),
            );
          }).toList();
        }
      }

      notifyListeners();
      debugPrint('AppProvider sync: Berhasil sinkronisasi master data (${cloudMotifs.length} motif, ${cloudModules.length} modul)');
      return true;
    } catch (e) {
      debugPrint('AppProvider syncMasterData error: $e');
      return false;
    }
  }

  /// Sinkronkan progres modul, riwayat praktikum, dan kuis dari Cloud Supabase ke SQLite lokal
  Future<bool> syncUserProgressFromServer() async {
    if (_currentUser == null || !SupabaseService.instance.isReady) {
      return false;
    }

    final userId = _currentUser!.id;
    final userEmail = _currentUser!.email;

    try {
      // 1. Tarik seluruh progres modul dari tabel user_module_progress Supabase
      final cloudProgressList = await SupabaseService.instance.fetchUserModuleProgress(userEmail);
      if (cloudProgressList.isNotEmpty) {
        // Ambil data lokal SQLite saat ini untuk proteksi anti-overwrite (Local Wins)
        final localList = await DatabaseHelper.instance.getUserModuleProgressList(userId, userEmail: userEmail);
        final Map<int, Map<String, dynamic>> localMap = {
          for (final r in localList) r['module_id'] as int: r
        };

        for (final row in cloudProgressList) {
          final mId = row['module_id'] as int? ?? 0;
          if (mId <= 0) continue;

          final localRow = localMap[mId];
          final localH = (localRow?['history_done'] as int? ?? 0) == 1;
          final localC = (localRow?['character_done'] as int? ?? 0) == 1;
          final localG = (localRow?['gallery_done'] as int? ?? 0) == 1;
          final localQ = (localRow?['quiz_done'] as int? ?? 0) == 1;
          final localP = (localRow?['practice_done'] as int? ?? 0) == 1;
          final localQS = localRow?['quiz_score'] as int?;
          final localPS = localRow?['practice_score'] as int?;

          // Merge: Nilai lokal yang lebih maju tidak boleh tertimpa nilai server yang kosong/lebih rendah
          final h = localH || row['history_done'] == true;
          final c = localC || row['character_done'] == true;
          final g = localG || row['gallery_done'] == true;
          final q = localQ || row['quiz_done'] == true;
          final p = localP || row['practice_done'] == true;
          final int? qS = max(localQS ?? 0, row['quiz_score'] as int? ?? 0) > 0 ? max(localQS ?? 0, row['quiz_score'] as int? ?? 0) : null;
          final int? pS = max(localPS ?? 0, row['practice_score'] as int? ?? 0) > 0 ? max(localPS ?? 0, row['practice_score'] as int? ?? 0) : null;
          final passScore = row['passing_score'] as int? ?? 70;

          final int completedComponents = (h ? 1 : 0) +
              (c ? 1 : 0) +
              (g ? 1 : 0) +
              (q && (qS ?? 0) >= passScore ? 1 : 0) +
              (p && (pS ?? 0) >= passScore ? 1 : 0);
          final percent = (completedComponents * 20).clamp(0, 100);
          final isPass = percent >= 100;

          await DatabaseHelper.instance.upsertUserModuleProgress(
            userId: userId,
            moduleId: mId,
            progressPercent: percent,
            historyDone: h,
            characterDone: c,
            galleryDone: g,
            quizDone: q,
            practiceDone: p,
            quizScore: qS,
            practiceScore: pS,
            passingScore: passScore,
            isPassed: isPass,
            isSynced: true,
          );
        }
      }

      // 2. Tarik riwayat praktikum dari tabel scans Supabase (scan_type = 'kuismu')
      final cloudPracticeScans = await SupabaseService.instance.fetchPracticeScans(userEmail);
      if (cloudPracticeScans.isNotEmpty) {
        for (final scan in cloudPracticeScans) {
          final mId = scan['module_id'] as int? ?? 1;
          final conf = (scan['confidence'] as num? ?? 0.70).toDouble();
          final passed = scan['passed'] == true;
          final imgUrl = scan['image_path'] as String?;

          await DatabaseHelper.instance.savePracticeAttempt(
            userId: userId,
            moduleId: mId,
            confidence: conf,
            passed: passed,
            imagePath: imgUrl,
            isSynced: true,
          );
        }
      }

      // 3. Muat ulang ke memori lokal
      await _loadUserModuleProgress(userEmail);
      final updatedHistories = await DatabaseHelper.instance.getScanHistories(userId, userEmail: userEmail);
      if (updatedHistories.isNotEmpty) {
        _scanHistories = updatedHistories;
      }

      notifyListeners();
      debugPrint('AppProvider sync: Progres pengguna ($userEmail) berhasil ditarik dari Cloud');
      return true;
    } catch (e) {
      debugPrint('AppProvider syncUserProgressFromServer error: $e');
      return false;
    }
  }

  /// Memproses antrean sinkronisasi riwayat pindaian dan kuis offline ke Cloud Supabase
  Future<int> processOfflineQueue() async {
    if (_currentUser == null || !SupabaseService.instance.isReady) {
      return 0;
    }

    final userId = _currentUser!.id;
    final userEmail = _currentUser!.email;
    int syncedCount = 0;

    try {
      // 1. Sinkronkan riwayat kuis teori yang belum tersinkronkan
      final pendingQuizzes = await DatabaseHelper.instance.getUnsyncedQuizAttempts(userId);
      for (var q in pendingQuizzes) {
        final success = await SupabaseService.instance.saveQuizAttempt(
          userEmail: userEmail,
          moduleId: q['module_id'] as int,
          score: q['score'] as int,
          passed: (q['passed'] as int) == 1,
        );
        if (success) {
          await DatabaseHelper.instance.markQuizAttemptSynced(q['id'] as int);
          syncedCount++;
        }
      }

      // 2. Sinkronkan riwayat pindaian/praktikum yang belum tersinkronkan
      final pendingScans = await DatabaseHelper.instance.getUnsyncedScans(userId);
      for (var s in pendingScans) {
        final success = await SupabaseService.instance.savePracticeScan(
          userEmail: userEmail,
          moduleId: s['module_id'] as int? ?? 1,
          confidence: (s['confidence'] as num? ?? 0.0).toDouble(),
          passed: (s['passed'] as int? ?? 0) == 1,
          imageUrl: s['image_path'] as String?,
        );
        if (success) {
          await DatabaseHelper.instance.markScanSynced(s['id'] as int);
          syncedCount++;
        }
      }

      // 3. Sinkronkan progres modul yang belum tersinkronkan
      final pendingProgress = await DatabaseHelper.instance.getUnsyncedUserModuleProgress(userId);
      for (var p in pendingProgress) {
        final success = await SupabaseService.instance.syncUserModuleProgress(
          userEmail: userEmail,
          moduleId: p['module_id'] as int,
          progressPercent: p['progress_percent'] as int,
          historyDone: (p['history_done'] as int) == 1,
          characterDone: (p['character_done'] as int) == 1,
          galleryDone: (p['gallery_done'] as int) == 1,
          quizDone: (p['quiz_done'] as int) == 1,
          practiceDone: (p['practice_done'] as int) == 1,
          quizScore: p['quiz_score'] as int?,
          practiceScore: p['practice_score'] as int?,
          passingScore: p['passing_score'] as int? ?? 70,
          isPassed: (p['is_passed'] as int? ?? 0) == 1,
        );
        if (success) {
          await DatabaseHelper.instance.markUserModuleProgressSynced(userId, p['module_id'] as int);
          syncedCount++;
        }
      }

      if (syncedCount > 0) {
        debugPrint('Offline Queue: Berhasil menyinkronkan $syncedCount rekaman tertunda ke Cloud Supabase');
      }
    } catch (e) {
      debugPrint('Offline Queue sync error: $e');
    }

    return syncedCount;
  }

  /// Reset progres seluruh modul di memori ke kondisi awal (0%)
  void _resetModuleProgressInMemory() {
    for (int i = 0; i < _modules.length; i++) {
      _modules[i] = _modules[i].copyWith(
        historyDone: false,
        characterDone: false,
        galleryDone: false,
        quizDone: false,
        practiceDone: false,
        quizScore: null,
        practiceScore: null,
        progressPercent: 0,
      );
    }
  }

  /// Memuat progres modul khusus untuk user tertentu (berdasarkan email & SQLite)
  Future<void> _loadUserModuleProgress(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final dbUser = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
      final userId = _currentUser?.id ?? dbUser?['id'] as int? ?? 1;

      // 1. Ambil data dari tabel relasional SQLite jika user terdaftar (dengan fallback email)
      Map<int, Map<String, dynamic>> sqliteProgressMap = {};
      final list = await DatabaseHelper.instance.getUserModuleProgressList(userId, userEmail: cleanEmail);
      for (final row in list) {
        final mId = row['module_id'] as int;
        sqliteProgressMap[mId] = row;
      }

      final prefs = await SharedPreferences.getInstance();

      for (int i = 0; i < _modules.length; i++) {
        final mId = _modules[i].id;
        final sqlRow = sqliteProgressMap[mId];

        bool? h;
        bool? c;
        bool? g;
        bool? q;
        bool? p;
        int? qS;
        int? pS;

        if (sqlRow != null) {
          h = (sqlRow['history_done'] as int? ?? 0) == 1;
          c = (sqlRow['character_done'] as int? ?? 0) == 1;
          g = (sqlRow['gallery_done'] as int? ?? 0) == 1;
          q = (sqlRow['quiz_done'] as int? ?? 0) == 1;
          p = (sqlRow['practice_done'] as int? ?? 0) == 1;
          qS = sqlRow['quiz_score'] as int?;
          pS = sqlRow['practice_score'] as int?;

          // Sinkronkan cache SharedPreferences agar tetap konsisten saat offline/hot reload
          final userKeyPrefix = 'user_${cleanEmail}_module_$mId';
          await prefs.setBool('${userKeyPrefix}_history', h);
          await prefs.setBool('${userKeyPrefix}_character', c);
          await prefs.setBool('${userKeyPrefix}_gallery', g);
          await prefs.setBool('${userKeyPrefix}_quiz', q);
          await prefs.setBool('${userKeyPrefix}_practice', p);
          if (qS != null) await prefs.setInt('${userKeyPrefix}_quizScore', qS);
          if (pS != null) await prefs.setInt('${userKeyPrefix}_practiceScore', pS);
        } else {
          // Fallback ke SharedPreferences cache
          final userKeyPrefix = 'user_${cleanEmail}_module_$mId';
          h = prefs.getBool('${userKeyPrefix}_history');
          c = prefs.getBool('${userKeyPrefix}_character');
          g = prefs.getBool('${userKeyPrefix}_gallery');
          q = prefs.getBool('${userKeyPrefix}_quiz');
          p = prefs.getBool('${userKeyPrefix}_practice');
          qS = prefs.getInt('${userKeyPrefix}_quizScore');
          pS = prefs.getInt('${userKeyPrefix}_practiceScore');
        }

        final tempMod = _modules[i].copyWith(
          historyDone: h ?? false,
          characterDone: c ?? false,
          galleryDone: g ?? false,
          quizDone: q ?? false,
          practiceDone: p ?? false,
          quizScore: qS,
          practiceScore: pS,
        );
        final computedPercent = tempMod.calculateProgressPercent();
        _modules[i] = tempMod.copyWith(progressPercent: computedPercent);
      }
    } catch (_) {}
  }

  // Tempelkan foto tersimpan ke pengguna aktif (dipakai setelah data pengguna dimuat dari DB)
  void _applySavedPhoto() {
    if (_currentUser != null && _savedPhotoPath != null) {
      _currentUser = _currentUser!.copyWith(profileImagePath: _savedPhotoPath);
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulasi delay autentikasi cepat & responsif
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

    // 1. Jika terhubung ke Cloud Supabase (Online / Web): Utamakan cek ke Server (Single Source of Truth)
    if (SupabaseService.instance.isReady) {
      final supaUser = await SupabaseService.instance.getUserByEmail(cleanEmail);
      if (supaUser != null) {
        userRecord = Map<String, dynamic>.from(supaUser);
        // Cache user dari cloud ke SQLite lokal HP (khusus non-web) agar siap jika offline nanti
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

    // 2. Jika offline atau belum ditemukan di server: Cek ke SQLite lokal HP (khusus non-web)
    if (userRecord == null && !kIsWeb) {
      userRecord = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
    }

    // 3. Jika user TIDAK ADA di server maupun di SQLite lokal: Tolak login!
    if (userRecord == null) {
      // Bedakan: jika offline DAN Supabase tidak ready, kemungkinan user perlu internet
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

    // Ambil data profil asli dari database
    final rawName = (userRecord['name'] as String? ?? '').trim();
    final userName = rawName.isNotEmpty ? rawName : cleanEmail.split('@').first;

    // Ambil foto profil dari database lokal jika tersedia
    final dbPhoto = userRecord['profile_image_path'] as String?;
    final userPhoto = (dbPhoto != null && dbPhoto.isNotEmpty) ? dbPhoto : _savedPhotoPath;
    if (userPhoto != null && userPhoto.isNotEmpty) {
      _savedPhotoPath = userPhoto;
    }

    // Login Sukses dengan Akun Asli
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

    // Muat progres modul khusus milik user yang berhasil login
    await _loadUserModuleProgress(cleanEmail);

    // Muat riwayat scan dan praktikum user yang login dari SQLite lokal
    try {
      final histories = await DatabaseHelper.instance.getScanHistories(_currentUser?.id ?? 1);
      _scanHistories = histories;
    } catch (_) {}

    // Tarik progres dan riwayat praktikum terbaru dari Cloud Supabase (Server-First)
    await syncUserProgressFromServer();

    _isLoading = false;
    notifyListeners();

    // Simpan preferensi secara asinkron
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

    // Jalankan antrean sinkronisasi offline di latar belakang setelah login
    processOfflineQueue();

    return true;
  }

  /// Meminta kode OTP untuk pemulihan kata sandi
  Future<EmailSendResult> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();

    // Validasi format email
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

    // Cek apakah email terdaftar di SQLite lokal atau cloud Supabase
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

    // Generate 4 digit OTP acak (1000 - 9999)
    final otp = (1000 + Random().nextInt(9000)).toString();
    _resetTargetEmail = cleanEmail;
    _resetOtpCode = otp;
    _resetOtpExpiresAt = DateTime.now().add(const Duration(minutes: 5));

    // Kirim via EmailService (baik live via EmailJS maupun demo simulation)
    final result = await EmailService.sendPasswordResetOtp(
      recipientEmail: cleanEmail,
      recipientName: recipientName,
      otpCode: otp,
    );

    _isLoading = false;
    notifyListeners();
    return result;
  }

  /// Verifikasi kecocokan kode OTP yang diinput
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

  /// Menyimpan kata sandi baru ke database & memory
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

    // Perbarui hash di database SQLite
    await DatabaseHelper.instance.updateUserPassword(targetEmail, newHash);

    // Perbarui di in-memory map
    _inMemoryPasswordHashes[targetEmail] = newHash;

    // Bersihkan sesi reset
    _resetTargetEmail = null;
    _resetOtpCode = null;
    _resetOtpExpiresAt = null;

    _isLoading = false;
    notifyListeners();
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

    // 1. Simpan ke SQLite lokal
    int newId = await DatabaseHelper.instance.insertUser(
      name: cleanName,
      email: cleanEmail,
      passwordHash: passwordHash,
      profileImagePath: _savedPhotoPath,
    );
    if (newId <= 0) {
      newId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }

    // 2. Sinkronkan ke cloud Supabase (jika terhubung)
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

    // Akun baru: pastikan progres modul di memori bersih (0%)
    _resetModuleProgressInMemory();

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
    // Reset progres modul di memori saat logout agar tidak bocor ke akun berikutnya
    _resetModuleProgressInMemory();
    notifyListeners();
  }

  /// Dipanggil dari ModuleDetailScreen saat user menyelesaikan satu page/pillar.
  /// pillar: 'history' | 'character' | 'gallery'
  Future<void> updatePillarProgress(int moduleId, String pillar) async {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      bool h = old.historyDone;
      bool c = old.characterDone;
      bool g = old.galleryDone;
      bool q = old.quizDone;
      bool p = old.practiceDone;

      if (pillar == 'history' && !h) h = true;
      if (pillar == 'character' && !c) c = true;
      if (pillar == 'gallery' && !g) g = true;

      final tempMod = old.copyWith(
        historyDone: h,
        characterDone: c,
        galleryDone: g,
      );
      final int percent = tempMod.calculateProgressPercent();
      final bool isPassed = tempMod.isCompleted;

      _modules[index] = tempMod.copyWith(progressPercent: percent);
      notifyListeners();

      // Simpan progres ke SharedPreferences & SQLite
      try {
        final prefs = await SharedPreferences.getInstance();
        final userKey = _currentUser?.email.trim().toLowerCase() ?? 'guest';
        final userKeyPrefix = 'user_${userKey}_module_$moduleId';
        await prefs.setInt('${userKeyPrefix}_progress', percent);
        await prefs.setBool('${userKeyPrefix}_history', h);
        await prefs.setBool('${userKeyPrefix}_character', c);
        await prefs.setBool('${userKeyPrefix}_gallery', g);
        await prefs.setBool('${userKeyPrefix}_quiz', q);
        await prefs.setBool('${userKeyPrefix}_practice', p);

        // Fallback key umum
        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_history', h);
        await prefs.setBool('module_${moduleId}_character', c);
        await prefs.setBool('module_${moduleId}_gallery', g);
        await prefs.setBool('module_${moduleId}_quiz', q);
        await prefs.setBool('module_${moduleId}_practice', p);

        final userId = _currentUser?.id ?? 1;
        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: h,
          characterDone: c,
          galleryDone: g,
          quizDone: q,
          practiceDone: p,
          quizScore: old.quizScore,
          practiceScore: old.practiceScore,
          passingScore: old.passingScore,
          isPassed: isPassed,
        );

        // Sinkronisasi ke Cloud Supabase (non-blocking)
        final userEmail = _currentUser?.email;
        if (userEmail != null) {
          SupabaseService.instance.syncUserModuleProgress(
            userEmail: userEmail,
            moduleId: moduleId,
            progressPercent: percent,
            historyDone: h,
            characterDone: c,
            galleryDone: g,
            quizDone: q,
            practiceDone: p,
            quizScore: old.quizScore,
            practiceScore: old.practiceScore,
            passingScore: old.passingScore,
            isPassed: isPassed,
          ).then((success) {
            if (success) {
              DatabaseHelper.instance.markUserModuleProgressSynced(userId, moduleId);
            }
          }).catchError((e) {
            debugPrint('Cloud sync pillar fallback: $e');
          });
        }
      } catch (_) {}
    }
  }

  Future<void> saveQuizResult(int moduleId, int score, bool passed) async {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      bool h = old.historyDone;
      bool c = old.characterDone;
      bool g = old.galleryDone;
      bool p = old.practiceDone;

      final tempMod = old.copyWith(
        quizDone: passed,
        quizScore: score,
      );
      final int percent = tempMod.calculateProgressPercent();
      final bool isPassed = tempMod.isCompleted;

      _modules[index] = tempMod.copyWith(progressPercent: percent);
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        final userKey = _currentUser?.email.trim().toLowerCase() ?? 'guest';
        final userKeyPrefix = 'user_${userKey}_module_$moduleId';
        await prefs.setInt('${userKeyPrefix}_progress', percent);
        await prefs.setBool('${userKeyPrefix}_quiz', passed);
        await prefs.setInt('${userKeyPrefix}_quizScore', score);

        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_quiz', passed);
        await prefs.setInt('module_${moduleId}_quizScore', score);

        final userId = _currentUser?.id ?? 1;
        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: h,
          characterDone: c,
          galleryDone: g,
          quizDone: passed,
          practiceDone: p,
          quizScore: score,
          practiceScore: old.practiceScore,
          passingScore: old.passingScore,
          isPassed: isPassed,
        );

        await DatabaseHelper.instance.saveQuizAttempt(
          userId: userId,
          moduleId: moduleId,
          score: score,
          passed: passed,
          totalQuestions: 10,
        );

        // Sinkronisasi ke Cloud Supabase (non-blocking)
        final userEmail = _currentUser?.email;
        if (userEmail != null) {
          SupabaseService.instance.saveQuizAttempt(
            userEmail: userEmail,
            moduleId: moduleId,
            score: score,
            passed: passed,
          ).then((success) {
            if (success) {
              DatabaseHelper.instance.getUnsyncedQuizAttempts(userId).then((list) {
                if (list.isNotEmpty) {
                  DatabaseHelper.instance.markQuizAttemptSynced(list.last['id'] as int);
                }
              }).catchError((_) {});
            }
          }).catchError((e) {
            debugPrint('Cloud sync quiz attempt fallback: $e');
          });

          SupabaseService.instance.syncUserModuleProgress(
            userEmail: userEmail,
            moduleId: moduleId,
            progressPercent: percent,
            historyDone: h,
            characterDone: c,
            galleryDone: g,
            quizDone: passed,
            practiceDone: p,
            quizScore: score,
            practiceScore: old.practiceScore,
            passingScore: old.passingScore,
            isPassed: isPassed,
          ).then((success) {
            if (success) {
              DatabaseHelper.instance.markUserModuleProgressSynced(userId, moduleId);
            }
          }).catchError((e) {
            debugPrint('Cloud sync quiz progress fallback: $e');
          });
        }
      } catch (_) {}
    }
  }

  Future<void> savePracticeResult(int moduleId, double fitScore, bool passed, {String? imagePath}) async {
    final index = _modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      final old = _modules[index];
      bool h = old.historyDone;
      bool c = old.characterDone;
      bool g = old.galleryDone;
      bool q = old.quizDone;

      // Pastikan skor integer bulat (0..100) dan skor ter-normalisasi (0.0..1.0)
      final int intScore = (fitScore > 1.0 ? fitScore : fitScore * 100).round().clamp(0, 100);
      final double normalizedScore = intScore / 100.0;

      final tempMod = old.copyWith(
        practiceDone: passed,
        practiceScore: intScore,
      );
      final int percent = tempMod.calculateProgressPercent();
      final bool isPassed = tempMod.isCompleted;

      _modules[index] = tempMod.copyWith(progressPercent: percent);
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        final userKey = _currentUser?.email.trim().toLowerCase() ?? 'guest';
        final userKeyPrefix = 'user_${userKey}_module_$moduleId';
        await prefs.setInt('${userKeyPrefix}_progress', percent);
        await prefs.setBool('${userKeyPrefix}_practice', passed);
        await prefs.setInt('${userKeyPrefix}_practiceScore', intScore);

        await prefs.setInt('module_${moduleId}_progress', percent);
        await prefs.setBool('module_${moduleId}_practice', passed);
        await prefs.setInt('module_${moduleId}_practiceScore', intScore);

        final userId = _currentUser?.id ?? 1;
        await DatabaseHelper.instance.upsertUserModuleProgress(
          userId: userId,
          moduleId: moduleId,
          progressPercent: percent,
          historyDone: h,
          characterDone: c,
          galleryDone: g,
          quizDone: q,
          practiceDone: passed,
          quizScore: old.quizScore,
          practiceScore: intScore,
          passingScore: old.passingScore,
          isPassed: isPassed,
        );

        await DatabaseHelper.instance.savePracticeAttempt(
          userId: userId,
          moduleId: moduleId,
          topMotifId: old.motifId,
          confidence: normalizedScore,
          passed: passed,
          imagePath: imagePath,
        );

        // Muat ulang daftar riwayat lokal agar mobile langsung memiliki data terbaru
        final updatedHistories = await DatabaseHelper.instance.getScanHistories(userId, userEmail: _currentUser?.email);
        if (updatedHistories.isNotEmpty) {
          _scanHistories = updatedHistories;
        } else {
          _scanHistories.removeWhere((s) => s.moduleId == moduleId && s.scanType == 'kuismu');
          _scanHistories.insert(
            0,
            ScanHistoryModel(
              id: DateTime.now().millisecondsSinceEpoch,
              scanType: 'kuismu',
              motifName: old.title.replaceAll('\n', ' '),
              score: normalizedScore,
              passed: passed,
              createdAt: 'Baru saja',
              imagePath: imagePath,
              moduleId: moduleId,
            ),
          );
        }

        // Sinkronisasi ke Cloud Supabase (non-blocking)
        final userEmail = _currentUser?.email;
        if (userEmail != null) {
          if (imagePath != null && imagePath.isNotEmpty) {
            SupabaseService.instance.uploadPracticeImage(
              filePath: imagePath,
              email: userEmail,
              moduleId: moduleId,
            ).then((publicUrl) {
              SupabaseService.instance.savePracticeScan(
                userEmail: userEmail,
                moduleId: moduleId,
                confidence: normalizedScore,
                passed: passed,
                imageUrl: publicUrl,
              ).then((success) {
                if (success) {
                  DatabaseHelper.instance.getUnsyncedScans(userId).then((list) {
                    if (list.isNotEmpty) {
                      DatabaseHelper.instance.markScanSynced(list.last['id'] as int);
                    }
                  }).catchError((_) {});
                }
              }).catchError((e) {
                debugPrint('Cloud sync practice scan fallback: $e');
              });
            }).catchError((_) {
              SupabaseService.instance.savePracticeScan(
                userEmail: userEmail,
                moduleId: moduleId,
                confidence: normalizedScore,
                passed: passed,
                imageUrl: null,
              ).then((success) {
                if (success) {
                  DatabaseHelper.instance.getUnsyncedScans(userId).then((list) {
                    if (list.isNotEmpty) {
                      DatabaseHelper.instance.markScanSynced(list.last['id'] as int);
                    }
                  }).catchError((_) {});
                }
              }).catchError((e) {
                debugPrint('Cloud sync practice scan fallback: $e');
              });
            });
          } else {
            SupabaseService.instance.savePracticeScan(
              userEmail: userEmail,
              moduleId: moduleId,
              confidence: normalizedScore,
              passed: passed,
              imageUrl: null,
            ).then((success) {
              if (success) {
                DatabaseHelper.instance.getUnsyncedScans(userId).then((list) {
                  if (list.isNotEmpty) {
                    DatabaseHelper.instance.markScanSynced(list.last['id'] as int);
                  }
                }).catchError((_) {});
              }
            }).catchError((e) {
              debugPrint('Cloud sync practice scan fallback: $e');
            });
          }

          SupabaseService.instance.syncUserModuleProgress(
            userEmail: userEmail,
            moduleId: moduleId,
            progressPercent: percent,
            historyDone: h,
            characterDone: c,
            galleryDone: g,
            quizDone: q,
            practiceDone: passed,
            quizScore: old.quizScore,
            practiceScore: intScore,
            passingScore: old.passingScore,
            isPassed: isPassed,
          ).then((success) {
            if (success) {
              DatabaseHelper.instance.markUserModuleProgressSynced(userId, moduleId);
            }
          }).catchError((e) {
            debugPrint('Cloud sync practice progress fallback: $e');
          });
        }
      } catch (_) {
        _scanHistories.removeWhere((s) => s.moduleId == moduleId && s.scanType == 'kuismu');
        _scanHistories.insert(
          0,
          ScanHistoryModel(
            id: DateTime.now().millisecondsSinceEpoch,
            scanType: 'kuismu',
            motifName: old.title.replaceAll('\n', ' '),
            score: normalizedScore,
            passed: passed,
            createdAt: 'Baru saja',
            imagePath: imagePath,
            moduleId: moduleId,
          ),
        );
      }

      notifyListeners();
    }
  }

  /// Mengambil riwayat percobaan praktikum dari database lokal SQLite
  Future<List<Map<String, dynamic>>> getPracticeAttempts(int moduleId) async {
    final userId = _currentUser?.id ?? 1;
    return await DatabaseHelper.instance.getPracticeAttempts(userId: userId, moduleId: moduleId);
  }

  void addUniversalScanResult({required String motifName, required double confidence}) {
    _scanHistories.insert(
      0,
      ScanHistoryModel(
        id: DateTime.now().millisecondsSinceEpoch,
        scanType: 'universal',
        motifName: motifName,
        score: confidence,
        passed: confidence >= 0.70,
        createdAt: 'Baru saja',
      ),
    );
    notifyListeners();
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

      // 1. Simpan ke SQLite lokal
      await DatabaseHelper.instance.updateUserProfile(
        userId: _currentUser!.id,
        name: cleanName,
        email: cleanEmail,
        phone: cleanPhone,
        profileImagePath: _savedPhotoPath,
      );

      // 2. Simpan perubahan kata sandi jika diisi
      if (password.isNotEmpty && password.length >= 8) {
        final newHash = PasswordHasher.hashPassword(password);
        _inMemoryPasswordHashes[cleanEmail] = newHash;
        await DatabaseHelper.instance.updateUserPassword(cleanEmail, newHash);
      }

      // 3. Simpan nama dan email ke SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_user_name', cleanName);
        await prefs.setString('logged_user_email', cleanEmail);
        await prefs.setString('logged_user_phone', cleanPhone);
      } catch (_) {}

      // 4. Sinkronkan ke cloud Supabase (jika terhubung)
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

      // 1. Simpan ke database SQLite lokal
      if (_currentUser != null) {
        await DatabaseHelper.instance.updateUserProfile(
          userId: _currentUser!.id,
          name: _currentUser!.name,
          email: _currentUser!.email,
          phone: _currentUser!.phone,
          profileImagePath: path,
        );
      }

      // 2. Upload ke Supabase Storage & perbarui Supabase users table (non-blocking)
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
            debugPrint('Cloud sync: Foto profil tersinkron ke Supabase users & storage!');
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

      // 1. Perbarui SQLite lokal
      await DatabaseHelper.instance.updateUserProfile(
        userId: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        profileImagePath: null,
      );

      // 2. Perbarui Supabase users table
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

  /// Melakukan migrate fresh database SQLite lokal dan memuat ulang state aplikasi
  Future<void> migrateFreshDatabase() async {
    _isLoading = true;
    notifyListeners();
    await DatabaseHelper.instance.migrateFresh();
    await initApp();
    _isLoading = false;
    notifyListeners();
  }
}