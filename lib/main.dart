import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/main_navigation_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi SQLite platform-aware (non-blocking fallback)
  try {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  } catch (e) {
    debugPrint('Database factory init info: $e');
  }

  // Inisialisasi Cloud Supabase (jika kredensial dikonfigurasi)
  try {
    await SupabaseService.instance.initialize();
  } catch (e) {
    debugPrint('Supabase bootstrap info: $e');
  }

  // Muat status sesi dan preferensi perangkat
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final savedEmail = prefs.getString('logged_user_email');

  // Logika Navigasi Awal:
  // 1. Jika sesi tersimpan aktif (ingat saya) -> Beranda
  // 2. Jika sudah pernah onboarding namun sesi tidak tersimpan / logout -> Login
  // 3. Jika pengguna baru pertama kali buka aplikasi -> Onboarding
  final Widget initialScreen;
  if (isLoggedIn) {
    initialScreen = const MainNavigationScreen();
  } else if (hasSeenOnboarding) {
    initialScreen = const LoginScreen();
  } else {
    initialScreen = const OnboardingScreen();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(
            initialIsLoggedIn: isLoggedIn,
            initialEmail: savedEmail,
          ),
        ),
      ],
      child: KenaliBatikmuApp(initialScreen: initialScreen),
    ),
  );
}

class KenaliBatikmuApp extends StatelessWidget {
  final Widget initialScreen;
  const KenaliBatikmuApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'Kenali Batikmu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: initialScreen,
    );
  }
}
