import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import 'module_detail_screen.dart';

class ModulesListScreen extends StatefulWidget {
  const ModulesListScreen({super.key});

  @override
  State<ModulesListScreen> createState() => _ModulesListScreenState();
}

class _ModulesListScreenState extends State<ModulesListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortFilter = 'all'; // 'all', 'completed', 'in_progress', 'not_started'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showSortModal(BuildContext context, bool isDark) {
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
                'Filter & Urutkan Modul',
                style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildSortOption('all', 'Semua Modul (11 Modul)', ctx),
              _buildSortOption('completed', 'Modul Selesai (100%)', ctx),
              _buildSortOption('in_progress', 'Sedang Dikerjakan (> 0%)', ctx),
              _buildSortOption('not_started', 'Belum Dimulai (0%)', ctx),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String key, String label, BuildContext ctx) {
    final isSelected = _sortFilter == key;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppTheme.accentGold : AppTheme.textMuted,
      ),
      title: Text(
        label,
        style: AppTheme.inter(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
        ),
      ),
      onTap: () {
        setState(() => _sortFilter = key);
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    // Filter modul sesuai pencarian & sort
    final displayModules = provider.modules.where((m) {
      final matchesQuery = _searchQuery.isEmpty ||
          m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.description.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesQuery) return false;

      if (_sortFilter == 'completed') return m.progressPercent >= 100;
      if (_sortFilter == 'in_progress') return m.progressPercent > 0 && m.progressPercent < 100;
      if (_sortFilter == 'not_started') return m.progressPercent == 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar Sesuai PDF Page 3 (Menu icon, Title Modul, Search Bar, Avatar)
              Row(
                children: [
                  const Icon(Icons.grid_view_rounded, size: 24, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Modul',
                    style: AppTheme.satoshi(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: AppTheme.inter(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Cari motif atau modul...',
                                hintStyle: AppTheme.inter(fontSize: 12, color: AppTheme.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close, size: 14, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name[0] : 'S',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Sub Header: Daftar Modul Belajar & Tombol Urutkan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Daftar Modul Belajar',
                        style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showSortModal(context, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_vert, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _sortFilter == 'all'
                                ? 'Urutkan'
                                : _sortFilter == 'completed'
                                    ? 'Selesai'
                                    : _sortFilter == 'in_progress'
                                        ? 'Dikerjakan'
                                        : 'Belum Mulai',
                            style: AppTheme.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Banner: Jejak Perajin (Selamat mengerjakan! 6/11 Selesai - 55% Selesai) Sesuai PDF Page 3
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E4324),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.menu_book, color: Colors.white70, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'JEJAK PERAJIN',
                                    style: AppTheme.satoshi(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selamat\nmengerjakan!',
                                style: AppTheme.satoshi(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selesaikan materi hari ini untuk meningkatkan keahlian canting dan membuka lencana baru.',
                                style: AppTheme.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Circular Progress Indicator
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.accentGold, width: 3),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${provider.completedModulesCount}/${provider.totalModulesCount}',
                                  style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  'Selesai',
                                  style: AppTheme.inter(fontSize: 9, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kemajuan Keseluruhan', style: AppTheme.inter(fontSize: 12, color: Colors.white70)),
                          Text('${provider.overallProgressPercent}% Selesai', style: AppTheme.satoshi(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentGold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Daftar Modul Dinamis Sesuai PDF Page 3
              if (displayModules.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Text(
                      'Tidak ada modul yang cocok dengan filter.',
                      style: AppTheme.inter(color: AppTheme.textMuted),
                    ),
                  ),
                )
              else
                ...displayModules.map((m) {
                  return _buildModuleCard(context, m, isDark);
                }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, ModuleModel module, bool isDark) {
    final isDone = module.progressPercent >= 100;
    final isCurrentWorking = module.id == 3 || (module.progressPercent > 0 && module.progressPercent < 100);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrentWorking ? AppTheme.accentGold.withValues(alpha: 0.6) : (isDark ? AppTheme.darkBorder : AppTheme.border),
          width: isCurrentWorking ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFFE8F5E9) : const Color(0xFFF4ECE4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle : Icons.menu_book,
                      color: isDone ? const Color(0xFF2E7D32) : AppTheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MODUL ${module.orderNo}/8',
                    style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: AppTheme.primary),
                  ),
                ],
              ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Selesai', style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                )
              else if (isCurrentWorking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${module.progressPercent}% Selesai', style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            module.title,
            style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            module.description,
            style: AppTheme.inter(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),

          // Nilai Teori & Praktikum Sesuai PDF Page 3
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBackground : const Color(0xFFF9F6F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      isDone
                          ? (module.id == 1 ? 'Nilai Teori: 80%' : 'Nilai Teori: 100%')
                          : (module.quizDone ? 'Nilai Teori: 80%' : 'Nilai Teori: -'),
                      style: AppTheme.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      isDone
                          ? 'Nilai Praktikum: 100%'
                          : (module.practiceDone ? 'Nilai Praktikum: 70%' : 'Nilai Praktikum: 0%'),
                      style: AppTheme.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Aksi: 'Lanjut Belajar' atau 'Mulai Belajar'
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ModuleDetailScreen(module: module),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentWorking ? const Color(0xFF5A3416) : (isDone ? const Color(0xFF4A3423) : const Color(0xFF6E4324)),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isCurrentWorking ? 'Lanjut Belajar' : (isDone ? 'Buka Kembali Materi' : 'Mulai Belajar'),
              style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
