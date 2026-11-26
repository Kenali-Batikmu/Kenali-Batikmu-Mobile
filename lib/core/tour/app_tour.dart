import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kumpulan GlobalKey untuk elemen-elemen yang disorot pada tur onboarding.
/// Dibuat satu kali di MainNavigationScreen lalu diteruskan ke widget terkait.
class AppTourKeys {
  /// Bagian paling atas Beranda (dipakai untuk menggulir kembali ke atas setelah tur).
  final GlobalKey top = GlobalKey(debugLabel: 'tour_top');

  /// Menu "Beranda" di footer.
  final GlobalKey homeNav = GlobalKey(debugLabel: 'tour_home_nav');

  /// Tombol "Kamera" di footer.
  final GlobalKey cameraNav = GlobalKey(debugLabel: 'tour_camera_nav');

  /// Menu "Modul" di footer.
  final GlobalKey modulesNav = GlobalKey(debugLabel: 'tour_modules_nav');

  /// Tombol "Mulai belajar" pada kartu Riwayat Belajar.
  /// Hanya terpasang bila pengguna belum mengerjakan modul apa pun.
  final GlobalKey learnButton = GlobalKey(debugLabel: 'tour_learn_button');

  /// Avatar profil di pojok kanan atas Beranda.
  final GlobalKey profileAvatar = GlobalKey(debugLabel: 'tour_profile_avatar');
}

/// Penyimpanan status tur: ditandai selesai per akun (email) di perangkat ini,
/// jadi akun baru yang masuk di perangkat yang sama tetap mendapat tur.
class AppTourStore {
  AppTourStore._();

  static String _key(String? email) {
    final id = (email ?? 'guest').trim().toLowerCase();
    return 'app_tour_done_$id';
  }

  static Future<bool> isDone(String? email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key(email)) ?? false;
    } catch (_) {
      // Bila penyimpanan gagal, anggap sudah selesai supaya pengguna tidak
      // terus-menerus diganggu tur yang tidak bisa dicatat.
      return true;
    }
  }

  static Future<void> markDone(String? email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(email), true);
    } catch (_) {}
  }

  static Future<void> reset(String? email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(email));
    } catch (_) {}
  }
}
