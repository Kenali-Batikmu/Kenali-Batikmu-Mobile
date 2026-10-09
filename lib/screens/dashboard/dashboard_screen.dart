import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/kb_module_card.dart';
import '../modules/module_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenModules;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenProfile;

  const DashboardScreen({
    super.key,
    required this.onOpenModules,
    required this.onOpenScan,
    required this.onOpenProfile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  // Sama dengan ModulesListScreen supaya header identik
  static const double _topBarHeight = 68;
  static const double _bgRatio = 1560 / 1170;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  // ── Modal pencarian ──────────────────────────────────────────────────────
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
          onOpenModules: widget.onOpenModules,
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeTop = MediaQuery.of(context).padding.top;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFFBF3E3);

    final headerHeight = safeTop + _topBarHeight;
    final bgHeight = screenWidth * _bgRatio;
    // Teks sapaan di sisi kiri, sejajar tokoh kebaya (sama proporsi Modul)
    final textLeft = screenWidth * 0.09;
    final textTop = screenWidth * 0.10;
    final textWidth = screenWidth * 0.46;
    final textHeight = screenWidth * 0.30;

    const brown = Color(0xFF4A2F1D);
    final firstName = (user?.name.isNotEmpty ?? false)
        ? user!.name.split(' ').first
        : 'Sekar';

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Konten scrollable (di bawah App Bar) ─────────────────────────
          Column(
            children: [
              SizedBox(height: headerHeight), // Beri ruang untuk App Bar
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Background ilustrasi + Teks Sapaan ───────────────────
                      SizedBox(
                        height: bgHeight,
                        child: Stack(
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (rect) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black,
                                  Colors.black,
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.8, 1.0],
                              ).createShader(rect),
                              child: Image.asset(
                                'assets/images/module_bg.jpeg',
                                width: screenWidth,
                                height: bgHeight,
                                fit: BoxFit.fill,
                              ),
                            ),
                            // Teks sapaan di atas ilustrasi
                            Positioned(
                              left: textLeft,
                              top: textTop,
                              width: textWidth,
                              height: textHeight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Selamat\nDatang, $firstName!',
                                      style: AppTheme.satoshi(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: brown,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: textWidth),
                                      child: Text(
                                        'Selesaikan materi hari ini untuk membuka lencana baru.',
                                        style: AppTheme.inter(
                                          fontSize: 12,
                                          color: brown,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24), // Jarak ke Rekomendasi Belajar

                        // ── Header Rekomendasi Belajar ─────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Rekomendasi Belajar',
                            style: AppTheme.satoshi(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Kartu modul aktif (3 KbModuleCard) ───────────
                        Builder(builder: (_) {
                          final inProgress = provider.modules
                              .where((m) =>
                                  m.progressPercent > 0 &&
                                  m.progressPercent < 100)
                              .toList()
                            ..sort((a, b) => b.progressPercent
                                .compareTo(a.progressPercent));

                          final notStarted = provider.modules
                              .where((m) => m.progressPercent == 0)
                              .toList()
                            ..sort((a, b) => a.orderNo.compareTo(b.orderNo));

                          final finished = provider.modules
                              .where((m) => m.progressPercent == 100)
                              .toList();

                          final combined = [
                            ...inProgress,
                            ...notStarted,
                            ...finished
                          ];
                          final recommended = combined.take(3).toList();

                          return Column(
                            children: recommended
                                .map((m) =>
                                    KbModuleCard(module: m, isDark: isDark))
                                .toList(),
                          );
                        }),
                        const SizedBox(height: 8),

                        // ── Header seksi motif ────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Modul Kenali Batikmu',
                                style: AppTheme.satoshi(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: widget.onOpenModules,
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

                        // ── List horizontal kartu motif kecil ─────────────
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: provider.modules.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 14),
                            itemBuilder: (ctx, idx) {
                              final m = provider.modules[idx];
                              // Assign icon dynamically based on index for variety
                              final icons = [
                                Icons.grain,
                                Icons.waves,
                                Icons.auto_awesome,
                                Icons.eco,
                                Icons.water_drop,
                              ];
                              return _buildMotifCard(
                                context: context,
                                title: m.title.split('\n').first,
                                subtitle: 'Modul ${m.orderNo}',
                                icon: icons[idx % icons.length],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ModuleDetailScreen(module: m)),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          // ── App Bar Solid (menutupi area status bar) ───────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: safeTop),
              decoration: BoxDecoration(
                color: bgColor,
                boxShadow: [
                  BoxShadow(
                    color: bgColor,
                    blurRadius: 16,
                    spreadRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: _buildTopBar(context, isDark, bgColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar: sama persis dengan _buildTopBar di ModulesListScreen ─────────
  List<BoxShadow> get _softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  Widget _buildTopBar(BuildContext context, bool isDark, Color bgColor) {
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    const iconColor = Color(0xFF8A6D56);
    final provider = context.read<AppProvider>();
    final user = provider.currentUser;

    return Container(
      height: _topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.center,
      child: Row(
        children: [
          // Logo KB
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _softShadow,
            ),
            child: ClipOval(
              child: Image.asset('assets/images/kb_logo.jpeg',
                  fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),

          // Search bar (fungsional → buka modal pencarian)
          Expanded(
            child: GestureDetector(
              onTap: () => _showSearchSheet(context, isDark),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: _softShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cari motif atau modul batik...',
                        style: AppTheme.inter(
                            fontSize: 13,
                            color: const Color(0xFFA59284)),
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
            onTap: widget.onOpenProfile,
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
                  (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'S',
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
    );
  }

  // ── Kartu motif kecil horizontal (dari versi lama) ───────────────────────
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
          border:
              Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
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
            // Tag Label
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Batik Klasik',
                  style: AppTheme.satoshi(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold),
                ),
              ),
            ),
            // Judul & Subtitle
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
                    style: AppTheme.satoshi(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
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

// ── Modal pencarian ───────────────────────────────────────────────────────────
class _SearchModalContent extends StatefulWidget {
  final bool isDark;
  final VoidCallback onOpenModules;

  const _SearchModalContent(
      {required this.isDark, required this.onOpenModules});

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
            style: AppTheme.inter(
                color: widget.isDark ? Colors.white : AppTheme.textPrimary),
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
              fillColor: widget.isDark
                  ? AppTheme.darkBackground
                  : AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color: widget.isDark
                        ? AppTheme.darkBorder
                        : AppTheme.border),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        style: AppTheme.inter(
                            fontSize: 13, color: AppTheme.textMuted),
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
                          child: const Center(
                              child: Icon(Icons.menu_book,
                                  color: Colors.white, size: 18)),
                        ),
                        title: Text(
                          m.title.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.satoshi(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Kemajuan: ${m.progressPercent}% Selesai',
                          style: AppTheme.inter(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ModuleDetailScreen(module: m)),
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
