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
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        onOpenModules: () => setState(() => _currentIndex = 2),
        onOpenScan: () => setState(() => _currentIndex = 1),
        onOpenProfile: () => setState(() => _currentIndex = 3),
      ),
      const UniversalScanScreen(),
      const ModulesListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allow body to flow under the transparent wavy bottom bar
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: KbBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

