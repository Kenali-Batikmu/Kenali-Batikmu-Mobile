import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../modules/module_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenModules;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenProfile;

  const DashboardScreen({
    super.key,
    required this.onOpenModules,
    required this.onOpenScan,
    required this.onOpenProfile,
  });

  void _showSearchSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _SearchModalContent(
          isDark: isDark,
          onOpenModules: onOpenModules,
        );
      },
    );
  }

  void _showMotifDetailSheet(BuildContext context, String title, String subtitle, String region, String philosophy, IconData icon, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF382516),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Icon(icon, color: AppTheme.accentGold, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 13, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              region,
                              style: AppTheme.inter(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Makna & Filosofi:',
                style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                philosophy,
                style: AppTheme.inter(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  final target = provider.modules.firstWhere(
                    (m) => m.title.toLowerCase().contains(title.toLowerCase().split(' ').first),
                    orElse: () => provider.modules[2],
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: target)),
                  );
                },
                icon: const Icon(Icons.menu_book, size: 16),
                label: const Text('Pelajari Modul Motif Ini'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A3416),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Search Bar & Profile Header Sesuai PDF Page 2
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Search Bar Box (Interactive)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showSearchSheet(context, isDark),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.stars, color: AppTheme.primary, size: 14),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cari motif atau modul batik...',
                                  style: AppTheme.inter(color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Profile Avatar (Clickable: opens Profile tab)
                    GestureDetector(
                      onTap: onOpenProfile,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentGold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty ?? false) ? user!.name[0] : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero Greeting Banner dengan Motif Sogan Keraton Sesuai PDF Page 2
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF261A12),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kenali Batikmu',
                      style: AppTheme.satoshi(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selamat Datang, ${user != null && user.name.contains(' ') ? user.name.split(' ').first : 'Sekar'}!',
                      style: AppTheme.satoshi(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Carousel Dots Indicator
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kartu Progress Latihan 'Teknik Nglowongi' Sesuai PDF Page 2
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teknik Nglowongi: Menggambar\nGaris Pola Utama',
                        style: AppTheme.satoshi(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Latihan menjaga kestabilan aliran malam cucuk canting pada kain mori prima yang terbentang di gawangan.',
                        style: AppTheme.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Progress Bar 65% Selesai Sesuai PDF
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kemajuan Sesi',
                            style: AppTheme.inter(fontSize: 13, color: AppTheme.textMuted),
                          ),
                          Text(
                            '65% Selesai',
                            style: AppTheme.satoshi(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.65,
                          minHeight: 8,
                          backgroundColor: isDark ? AppTheme.darkBorder : AppTheme.borderLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tombol Cokelat Tua: Lanjut Belajar (Navigates directly to Modul 3)
                      ElevatedButton(
                        onPressed: () {
                          final targetModule = provider.modules.firstWhere(
                            (m) => m.id == 3,
                            orElse: () => provider.modules[0],
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ModuleDetailScreen(module: targetModule),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3416),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Lanjut Belajar',
                          style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Mudul Kenali Batikmu (Cecek Hasan, Parang Rusak, Truntum)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mudul Kenali Batikmu',
                      style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: onOpenModules,
                      child: Text(
                        'Lihat Semua',
                        style: AppTheme.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Grid 3 Kartu Gambar Motif Sesuai PDF Page 2
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildMotifCard(
                      context: context,
                      title: 'Cecek Hasan',
                      subtitle: 'Ornamen Isen Halus',
                      icon: Icons.grain,
                      onTap: () => _showMotifDetailSheet(
                        context,
                        'Cecek Hasan',
                        'Ornamen Isen Halus',
                        'Pekalongan & Surakarta',
                        'Cecek Hasan merupakan ornamen isen halus berupa titik-titik melingkar teratur yang mengisi bidang kosong motif utama, melambangkan kebersahajaan dan ketelitian budi manusia.',
                        Icons.grain,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _buildMotifCard(
                      context: context,
                      title: 'Parang Rusak',
                      subtitle: 'Pakem Keraton Agung',
                      icon: Icons.waves,
                      onTap: () => _showMotifDetailSheet(
                        context,
                        'Parang Rusak',
                        'Pakem Keraton Agung',
                        'Surakarta & Yogyakarta',
                        'Pakem larangan keraton bermotif lereng ombak tajam menghantam karang, melambangkan pertempuran manusia melawan hawa nafsu dan ketegaran jiwa tanpa kenal kata menyerah.',
                        Icons.waves,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _buildMotifCard(
                      context: context,
                      title: 'Truntum',
                      subtitle: 'Bintang Kasih Sayang',
                      icon: Icons.auto_awesome,
                      onTap: () => _showMotifDetailSheet(
                        context,
                        'Truntum',
                        'Bintang Kasih Sayang',
                        'Surakarta',
                        'Bermotif kuntum bintang bertabur di langit malam, diciptakan oleh Kanjeng Ratu Kencana sebagai simbol cinta yang tulus dan kembali bersemi abadi.',
                        Icons.auto_awesome,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotifCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF382516),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Icon(
                  icon,
                  size: 54,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Tag Label di Atas
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Batik Klasik',
                  style: AppTheme.satoshi(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                ),
              ),
            ),
            // Judul & Subtitle di Bawah
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchModalContent extends StatefulWidget {
  final bool isDark;
  final VoidCallback onOpenModules;

  const _SearchModalContent({required this.isDark, required this.onOpenModules});

  @override
  State<_SearchModalContent> createState() => _SearchModalContentState();
}

class _SearchModalContentState extends State<_SearchModalContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filteredModules = provider.modules.where((m) {
      if (_query.isEmpty) return true;
      return m.title.toLowerCase().contains(_query.toLowerCase()) ||
          m.description.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: (val) => setState(() => _query = val),
            style: AppTheme.inter(color: widget.isDark ? Colors.white : AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cari motif atau modul batik...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: widget.isDark ? AppTheme.darkBackground : AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: widget.isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Hasil Pencarian (${filteredModules.length}):',
            style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: filteredModules.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Tidak ada modul yang cocok dengan pencarian.',
                        style: AppTheme.inter(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredModules.length,
                    itemBuilder: (ctx, idx) {
                      final m = filteredModules[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5A3416),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(child: Icon(Icons.menu_book, color: Colors.white, size: 18)),
                        ),
                        title: Text(
                          m.title.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Kemajuan: ${m.progressPercent}% Selesai',
                          style: AppTheme.inter(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: m)),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
