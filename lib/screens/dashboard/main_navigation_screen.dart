import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Bottom Navigation Bar Sesuai Desain PDF Page 2, 3, 12: 3 Tombol Rounded Rectangle Cokelat Tua
      bottomNavigationBar: Container(
        color: isDark ? AppTheme.darkBackground : AppTheme.background,
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPdfNavPill(
              index: 0,
              icon: Icons.home_outlined,
              isSelected: _currentIndex == 0,
            ),
            const SizedBox(width: 18),
            _buildPdfNavPill(
              index: 1,
              icon: Icons.camera_alt_outlined,
              isSelected: _currentIndex == 1,
            ),
            const SizedBox(width: 18),
            _buildPdfNavPill(
              index: 2,
              icon: Icons.menu_book_outlined,
              isSelected: _currentIndex == 2,
            )
            // const SizedBox(width: 18),
            // _buildPdfNavPill(
            //   index: 3,
            //   icon: Icons.person_outline,
            //   isSelected: _currentIndex == 3,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfNavPill({
    required int index,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6E4324) : const Color(0xFF4A2F1B),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF6E4324).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: isSelected ? AppTheme.accentGold : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
