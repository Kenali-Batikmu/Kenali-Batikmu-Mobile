import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/tour/app_tour.dart';
import '../../providers/app_provider.dart';
import '../../widgets/kb_bottom_nav.dart';
import '../../widgets/kb_coach_overlay.dart';
import 'dashboard_screen.dart';
import '../modules/modules_list_screen.dart';
import '../scan/universal_scan_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const int _homeIndex = 0;
  static const int _scanIndex = 1;
  static const int _modulesIndex = 2;
  static const int _profileIndex = 3;

  int _currentIndex = _homeIndex;

  // Tab asal sebelum masuk Profil (Home atau Modul). Default: Home.
  int _previousIndex = _homeIndex;

  // ── Tur onboarding ──
  final AppTourKeys _tourKeys = AppTourKeys();
  bool _tourScheduled = false;
  bool _tourActive = false;
  List<KbCoachStep> _tourSteps = const [];

  void _goToTab(int index) {
    setState(() {
      // Simpan asal hanya saat berpindah KE Profil dari tab lain.
      // Hanya Home dan Modul yang dijadikan tujuan kembali.
      if (index == _profileIndex && _currentIndex != _profileIndex) {
        if (_currentIndex == _homeIndex || _currentIndex == _modulesIndex) {
          _previousIndex = _currentIndex;
        }
      }
      _currentIndex = index;
    });
  }

  // ── Tur onboarding ─────────────────────────────────────────────────────────

  /// Memulai tur. Secara default hanya bila akun ini belum pernah menyelesaikan
  /// atau melewati tur; [force] dipakai untuk mengulang dari halaman Profil.
  Future<void> _startTour({bool force = false}) async {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    final email = provider.currentUser?.email;

    if (!force && await AppTourStore.isDone(email)) return;
    if (!mounted) return;

    // Tur selalu dimulai dari Beranda.
    if (_currentIndex != _homeIndex) {
      setState(() => _currentIndex = _homeIndex);
    }

    // Beri waktu agar Beranda selesai tergambar sebelum elemen diukur.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || _tourActive) return;

    setState(() {
      _tourSteps = _buildTourSteps(provider);
      _tourActive = true;
    });
  }

  List<KbCoachStep> _buildTourSteps(AppProvider provider) {
    final user = provider.currentUser;
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().split(' ').first
        : null;

    return [
      // 1. Selamat datang: seluruh halaman digelapkan
      KbCoachStep(
        icon: Icons.waving_hand_rounded,
        title: name == null
            ? 'Selamat Datang di Kenali Batikmu!'
            : 'Selamat Datang, $name!',
        body: 'Yuk, kenali sekilas bagian-bagian utama aplikasi ini '
            'sebelum mulai menjelajahi warisan batik Nusantara. '
            'Hanya butuh semenit.',
      ),

      // 2. Beranda
      KbCoachStep(
        targetKey: _tourKeys.homeNav,
        icon: Icons.home_rounded,
        title: 'Beranda',
        body: 'Pusat belajarmu. Di sini kamu melihat riwayat belajar, '
            'kemajuan tiap modul, dan cuplikan modul batik pilihan.',
        padding: 10,
        cornerRadius: 18,
      ),

      // 3. Kamera
      KbCoachStep(
        targetKey: _tourKeys.cameraNav,
        icon: Icons.photo_camera_rounded,
        title: 'Kamera Pindai',
        body: 'Arahkan kamera ke kain batik dan kecerdasan buatan akan '
            'mengenali motifnya, lengkap dengan asal daerah dan maknanya.',
        padding: 8,
        cornerRadius: 34,
      ),

      // 4. Modul
      KbCoachStep(
        targetKey: _tourKeys.modulesNav,
        icon: Icons.menu_book_rounded,
        title: 'Modul',
        body: 'Daftar lengkap modul pembelajaran. Tiap modul memuat sejarah, '
            'karakter, galeri, kuis teori, dan praktikum motif batik.',
        padding: 10,
        cornerRadius: 18,
      ),

      // 5. Mulai belajar: hanya bila pengguna belum mengerjakan modul apa pun.
      // Tombolnya hanya terpasang (punya konteks) saat kartu Riwayat Belajar
      // berlabel "Mulai belajar"; bila sudah "Lanjut belajar", langkah ini dilewati.
      if (_tourKeys.learnButton.currentContext != null)
        KbCoachStep(
          targetKey: _tourKeys.learnButton,
          icon: Icons.play_circle_rounded,
          title: 'Mulai Belajar',
          body: 'Kamu belum mengerjakan modul apa pun. Ketuk tombol ini untuk '
              'memulai modul pertamamu. Progresnya akan tersimpan di Riwayat '
              'Belajar dan tombol berganti menjadi “Lanjut belajar”.',
          padding: 6,
          cornerRadius: 18,
        ),

      // 6. Profil
      KbCoachStep(
        targetKey: _tourKeys.profileAvatar,
        icon: Icons.person_rounded,
        title: 'Profil',
        body: 'Ketuk avatarmu untuk mengubah nama, email, nomor telepon, '
            'kata sandi, dan foto profil, atau untuk keluar dari akun. '
            'Panduan ini bisa dibuka lagi dari sana.',
        shape: KbCoachShape.circle,
        padding: 6,
      ),
    ];
  }

  void _finishTour(bool completed) {
    // Dilewati maupun diselesaikan sama-sama dianggap sudah melihat tur.
    final email = context.read<AppProvider>().currentUser?.email;
    AppTourStore.markDone(email);

    setState(() => _tourActive = false);

    // Kembalikan gulir Beranda ke atas (tur bisa menggulirnya ke kartu Riwayat Belajar).
    final topContext = _tourKeys.top.currentContext;
    if (topContext != null) {
      Scrollable.ensureVisible(
        topContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tur dijadwalkan sekali, begitu pengguna dan data modul sudah siap.
    final ready = context.select<AppProvider, bool>(
      (p) => p.currentUser != null && p.modules.isNotEmpty,
    );
    if (ready && !_tourScheduled) {
      _tourScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
    }

    final List<Widget> screens = [
      DashboardScreen(
        tourKeys: _tourKeys,
        onOpenModules: () => _goToTab(_modulesIndex),
        onOpenScan: () => _goToTab(_scanIndex),
        onOpenProfile: () => _goToTab(_profileIndex),
      ),
      UniversalScanScreen(
        isActive: _currentIndex == _scanIndex,
      ),
      // Avatar di top bar halaman modul pindah ke tab Profil (footer tetap tampil)
      ModulesListScreen(
        onOpenProfile: () => _goToTab(_profileIndex),
      ),
      ProfileScreen(
        // Kembali ke Home atau Modul, sesuai tab asal
        onBack: () => setState(() => _currentIndex = _previousIndex),
        onReplayTour: () => _startTour(force: true),
      ),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          extendBody: true, // Allow body to flow under the transparent wavy bottom bar
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: KbBottomNav(
            currentIndex: _currentIndex,
            onTap: _goToTab,
            homeKey: _tourKeys.homeNav,
            cameraKey: _tourKeys.cameraNav,
            modulesKey: _tourKeys.modulesNav,
          ),
        ),
        // Overlay tur: menggelapkan semua yang tidak sedang dijelaskan
        if (_tourActive)
          Positioned.fill(
            child: KbCoachOverlay(
              steps: _tourSteps,
              onFinish: _finishTour,
            ),
          ),
      ],
    );
  }
}
