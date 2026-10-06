import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../auth/login_screen.dart';
import '../modules/module_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAllHistoryModal(BuildContext context, bool isDark) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Semua Riwayat Modul Selesai',
                style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.modules.where((m) => m.progressPercent >= 100).length,
                  itemBuilder: (c, idx) {
                    final completed = provider.modules.where((m) => m.progressPercent >= 100).toList()[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A3416),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'M${completed.orderNo}',
                          style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      title: Text(completed.title.replaceAll('\n', ' '), style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('Status: Selesai 100%', style: AppTheme.inter(fontSize: 11, color: const Color(0xFF2E7D32))),
                      trailing: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: completed)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Keluar dari Akun?', style: AppTheme.satoshi(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Text(
            'Anda dapat masuk kembali kapan saja untuk melanjutkan latihan canting dan modul belajar.',
            style: AppTheme.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: AppTheme.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = Provider.of<AppProvider>(context, listen: false);
                await provider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A4B29),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title: Profil & Edit Pen Icon Sesuai PDF Page 12, 13, 14
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profil',
                    style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.edit_outlined, size: 20, color: isDark ? AppTheme.accentGold : const Color(0xFFC4A482)),
                ],
              ),
              const SizedBox(height: 16),

              // User Info Card Sesuai PDF Page 12, 13, 14
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF221A14) : const Color(0xFF2B231D),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar Lingkaran dengan Inisial 'S'
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentGold, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name.isNotEmpty ?? false) ? user!.name[0] : 'S',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Sekar Ayu Kinanti',
                          style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@sekar_artisan',
                          style: AppTheme.inter(fontSize: 12, color: AppTheme.accentGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2 Stats Box Sesuai PDF: 6/11 Modul Selesai & 6 Motif Discan
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF221A14) : const Color(0xFF2B231D),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.menu_book, color: AppTheme.accentGold, size: 22),
                          const SizedBox(height: 8),
                          Text(
                            '${provider.completedModulesCount}/${provider.totalModulesCount}',
                            style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text('Modul Selesai', style: AppTheme.inter(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF221A14) : const Color(0xFF2B231D),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.camera_alt, color: AppTheme.accentGold, size: 22),
                          const SizedBox(height: 8),
                          Text(
                            '${provider.scannedMotifsCount}',
                            style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text('Motif Discan', style: AppTheme.inter(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Section: Riwayat Modul & Lihat Semua Sesuai PDF Page 13 & 14
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Riwayat Modul', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => _showAllHistoryModal(context, isDark),
                    child: Text('Lihat semua', style: AppTheme.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List 3 Riwayat Modul Card Gelap Sesuai PDF Page 13 & 14
              _buildRiwayatModulItem(
                badge: 'PK',
                title: 'Motif Parang Kusumo',
                subtitle: 'Diselesaikan 2 hari lalu',
                isDark: isDark,
                onTap: () {
                  final m = provider.modules.firstWhere((item) => item.id == 3, orElse: () => provider.modules[0]);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: m)));
                },
              ),
              _buildRiwayatModulItem(
                badge: 'KW',
                title: 'Filosofi & Pola Kawung',
                subtitle: 'Diselesaikan 5 hari lalu',
                isDark: isDark,
                onTap: () {
                  final m = provider.modules.firstWhere((item) => item.id == 6, orElse: () => provider.modules[0]);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: m)));
                },
              ),
              _buildRiwayatModulItem(
                badge: 'SG',
                title: 'Teknik Celup Kulit Soga',
                subtitle: 'Diselesaikan 1 mgg lalu',
                isDark: isDark,
                onTap: () {
                  final m = provider.modules.firstWhere((item) => item.id == 4, orElse: () => provider.modules[0]);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: m)));
                },
              ),
              const SizedBox(height: 14),

              // Toggle Mode Gelap Sesuai PDF Page 12, 13, 14
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF221A14) : const Color(0xFF2B231D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.nightlight_round, color: AppTheme.accentGold, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mode Gelap', style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(
                            isDark ? 'Mode gelap sedang aktif' : 'Beralih ke tampilan gelap klasik',
                            style: AppTheme.inter(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: provider.isDarkMode,
                      activeThumbColor: AppTheme.accentGold,
                      activeTrackColor: const Color(0xFF6E4324),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      onChanged: (val) {
                        provider.toggleDarkMode(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Keluar dari Akun Sesuai PDF Page 12, 13, 14
              OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, size: 16, color: Color(0xFF7A4B29)),
                label: const Text('Keluar dari Akun', style: TextStyle(color: Color(0xFF7A4B29), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: Color(0xFFD4A373)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: isDark ? Colors.transparent : Colors.white,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatModulItem({
    required String badge,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF221A14) : const Color(0xFF2B231D),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.inter(fontSize: 11, color: Colors.white60)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 1.5),
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
