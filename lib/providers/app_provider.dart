import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/email_service.dart';
import '../models/app_models.dart';
import 'auth_provider.dart';
import 'module_provider.dart';
import 'quiz_provider.dart';
import 'sync_provider.dart';
import 'theme_provider.dart';

/// AppProvider bertindak sebagai Master Orchestrator dan Central Facade
/// untuk seluruh domain state aplikasi (Auth, Module, Quiz, Sync, Theme).
/// Mempertahankan 100% kompatibilitas backward bagi seluruh widget layar dan test suite.
class AppProvider with ChangeNotifier {
  // Domain Providers Terisolasi
  late final AuthProvider authProvider;
  late final ModuleProvider moduleProvider;
  late final QuizProvider quizProvider;
  late final SyncProvider syncProvider;
  late final ThemeProvider themeProvider;

  // Delegasi Getters Auth
  UserModel? get currentUser => authProvider.currentUser;
  bool get isLoading => authProvider.isLoading;
  String? get errorMessage => authProvider.errorMessage;
  String? get resetTargetEmail => authProvider.resetTargetEmail;
  String? get activeResetOtp => authProvider.activeResetOtp;
  bool get hasActiveResetOtp => authProvider.hasActiveResetOtp;

  // Delegasi Getters Modul & Kurikulum
  List<ModuleModel> get modules => moduleProvider.modules;
  List<BatikMotifModel> get motifs => moduleProvider.motifs;
  int get completedModulesCount => moduleProvider.completedModulesCount;
  int get totalModulesCount => moduleProvider.totalModulesCount;
  int get overallProgressPercent => moduleProvider.overallProgressPercent;

  // Delegasi Getters Kuis & Pindaian
  List<ScanHistoryModel> get scanHistories => quizProvider.scanHistories;
  int get scannedMotifsCount => quizProvider.scannedMotifsCount;

  // Delegasi Getter Tema
  bool get isDarkMode => themeProvider.isDarkMode;

  Future<void>? _initFuture;

  AppProvider({bool initialIsLoggedIn = false, String? initialEmail}) {
    themeProvider = ThemeProvider();
    authProvider = AuthProvider();
    moduleProvider = ModuleProvider();
    quizProvider = QuizProvider();
    syncProvider = SyncProvider();

    // Teruskan notifikasi dari setiap sub-provider agar widget yang watch AppProvider ter-update otomatis
    themeProvider.addListener(notifyListeners);
    authProvider.addListener(notifyListeners);
    moduleProvider.addListener(notifyListeners);
    quizProvider.addListener(notifyListeners);
    syncProvider.addListener(notifyListeners);

    initApp(savedEmail: initialEmail);
  }

  @override
  void dispose() {
    syncProvider.disposeListener();
    themeProvider.removeListener(notifyListeners);
    authProvider.removeListener(notifyListeners);
    moduleProvider.removeListener(notifyListeners);
    quizProvider.removeListener(notifyListeners);
    syncProvider.removeListener(notifyListeners);
    super.dispose();
  }

  void toggleDarkMode(bool value) => themeProvider.toggleDarkMode(value);

  /// Inisialisasi terpadu seluruh state aplikasi
  Future<void> initApp({String? savedEmail}) {
    _initFuture ??= _runInitApp(savedEmail: savedEmail).whenComplete(() {
      _initFuture = null;
    });
    return _initFuture!;
  }

  Future<void> _runInitApp({String? savedEmail}) async {
    try {
      await themeProvider.initTheme();

      String? emailToLoad = savedEmail;
      if (emailToLoad == null) {
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
        if (isLoggedIn) {
          emailToLoad = prefs.getString('logged_user_email');
        }
      }

      await authProvider.initSession(savedEmail: emailToLoad);

      final user = authProvider.currentUser;
      await moduleProvider.loadMasterData(
        userId: user?.id,
        userEmail: user?.email,
      );

      if (user != null) {
        await moduleProvider.loadUserModuleProgress(user.email, userId: user.id);
        await quizProvider.loadScanHistories(user.id, userEmail: user.email);
      } else {
        moduleProvider.resetModuleProgressInMemory();
      }
    } catch (e) {
      debugPrint('AppProvider _runInitApp error: $e');
    } finally {
      notifyListeners();
      _syncBackground();
      syncProvider.setupConnectivityListener(_syncBackground);
    }
  }

  Future<void> _syncBackground() async {
    try {
      // 1. Unggah antrean offline terlebih dahulu ke Supabase
      await processOfflineQueue();
      // 2. Sinkronkan master data dari cloud
      await syncMasterDataFromCloud();
      // 3. Tarik dan merge progres pengguna dari cloud
      if (currentUser != null) {
        await syncUserProgressFromServer();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider _syncBackground error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELEGASI OPERASI AUTENTIKASI (AUTH)
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    final success = await authProvider.login(email, password, rememberMe: rememberMe);
    if (success && currentUser != null) {
      final user = currentUser!;
      await moduleProvider.loadUserModuleProgress(user.email, userId: user.id);
      await quizProvider.loadScanHistories(user.id, userEmail: user.email);
      await syncUserProgressFromServer();
      processOfflineQueue();
      notifyListeners();
    }
    return success;
  }

  Future<bool> register(String name, String email, String password) async {
    final success = await authProvider.register(name, email, password);
    if (success) {
      moduleProvider.resetModuleProgressInMemory();
      quizProvider.clearHistories();
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    await authProvider.logout();
    moduleProvider.resetModuleProgressInMemory();
    quizProvider.clearHistories();
    notifyListeners();
  }

  Future<EmailSendResult> requestPasswordReset(String email) =>
      authProvider.requestPasswordReset(email);

  bool verifyResetOtp(String inputOtp) =>
      authProvider.verifyResetOtp(inputOtp);

  Future<bool> finalizePasswordReset(String newPassword) =>
      authProvider.finalizePasswordReset(newPassword);

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) =>
      authProvider.updateProfile(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

  Future<bool> setProfilePhoto(String path) =>
      authProvider.setProfilePhoto(path);

  Future<void> removeProfilePhoto() =>
      authProvider.removeProfilePhoto();

  // ─────────────────────────────────────────────────────────────────────────
  // DELEGASI OPERASI MODUL & PILAR
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> updatePillarProgress(int moduleId, String pillar) async {
    final userId = currentUser?.id ?? 1;
    final userEmail = currentUser?.email;
    await moduleProvider.updatePillarProgress(
      moduleId,
      pillar,
      userId: userId,
      userEmail: userEmail,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELEGASI OPERASI KUIS & PRAKTIKUM
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> saveQuizResult(int moduleId, int score, bool passed) async {
    final userId = currentUser?.id ?? 1;
    final userEmail = currentUser?.email;
    final index = modules.indexWhere((m) => m.id == moduleId);
    final module = index != -1 ? modules[index] : null;

    await quizProvider.saveQuizResult(
      moduleId: moduleId,
      score: score,
      passed: passed,
      userId: userId,
      userEmail: userEmail,
      module: module,
    );

    moduleProvider.updateModuleQuizResult(moduleId, score, passed);
  }

  Future<void> savePracticeResult(
    int moduleId,
    double fitScore,
    bool passed, {
    String? imagePath,
  }) async {
    final userId = currentUser?.id ?? 1;
    final userEmail = currentUser?.email;
    final index = modules.indexWhere((m) => m.id == moduleId);
    final module = index != -1 ? modules[index] : null;

    await quizProvider.savePracticeResult(
      moduleId: moduleId,
      fitScore: fitScore,
      passed: passed,
      userId: userId,
      userEmail: userEmail,
      module: module,
      imagePath: imagePath,
    );

    final intScore = (fitScore > 1.0 ? fitScore : fitScore * 100).round().clamp(0, 100);
    moduleProvider.updateModulePracticeResult(moduleId, intScore, passed);
  }

  Future<List<Map<String, dynamic>>> getPracticeAttempts(int moduleId) =>
      quizProvider.getPracticeAttempts(moduleId, userId: currentUser?.id ?? 1);

  void addUniversalScanResult({required String motifName, required double confidence}) =>
      quizProvider.addUniversalScanResult(motifName: motifName, confidence: confidence);

  // ─────────────────────────────────────────────────────────────────────────
  // DELEGASI OPERASI SINKRONISASI (SYNC)
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> syncMasterDataFromCloud() async {
    return await syncProvider.syncMasterDataFromCloud(
      onMasterDataUpdated: (newMotifs, newModules) {
        if (newMotifs.isNotEmpty) moduleProvider.setMotifs(newMotifs);
        if (newModules.isNotEmpty) {
          // Preservasi progres modul yang sedang aktif di memori
          final mergedModules = newModules.map((newMod) {
            final existingIndex = modules.indexWhere((m) => m.id == newMod.id);
            if (existingIndex == -1) return newMod;
            final existing = modules[existingIndex];
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
          moduleProvider.setModules(mergedModules);
        }
      },
      userId: currentUser?.id,
      userEmail: currentUser?.email,
    );
  }

  Future<bool> syncUserProgressFromServer() async {
    if (currentUser == null) return false;
    return await syncProvider.syncUserProgressFromServer(
      currentUser: currentUser!,
      onReloadProgress: (email) => moduleProvider.loadUserModuleProgress(email, userId: currentUser?.id),
      onHistoriesUpdated: (histories) => quizProvider.setScanHistories(histories),
    );
  }

  Future<int> processOfflineQueue() async {
    if (currentUser == null) return 0;
    return await syncProvider.processOfflineQueue(currentUser: currentUser!);
  }

  Future<void> migrateFreshDatabase() async {
    authProvider.setLoading(true);
    notifyListeners();
    await DatabaseHelper.instance.migrateFresh();
    await initApp();
    authProvider.setLoading(false);
    notifyListeners();
  }
}