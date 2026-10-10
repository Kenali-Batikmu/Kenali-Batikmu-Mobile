import 'package:flutter/material.dart';
import '../../widgets/kb_bottom_nav.dart';
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        onOpenModules: () => _goToTab(_modulesIndex),
        onOpenScan: () => _goToTab(_scanIndex),
        onOpenProfile: () => _goToTab(_profileIndex),
      ),
      const UniversalScanScreen(),
      // Avatar di top bar halaman modul pindah ke tab Profil (footer tetap tampil)
      ModulesListScreen(
        onOpenProfile: () => _goToTab(_profileIndex),
      ),
      ProfileScreen(
        // Kembali ke Home atau Modul, sesuai tab asal
        onBack: () => setState(() => _currentIndex = _previousIndex),
      ),
    ];

    return Scaffold(
      extendBody: true, // Allow body to flow under the transparent wavy bottom bar
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: KbBottomNav(
        currentIndex: _currentIndex,
        onTap: _goToTab,
      ),
    );
  }
}