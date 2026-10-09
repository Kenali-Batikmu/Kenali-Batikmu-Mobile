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

  double get _scrollOffset {
    if (!_scrollController.hasClients) return 0;
    final o = _scrollController.offset;
    return o < 0 ? 0 : o;
  }

  // ── Modal pencarian (dipertahankan dari versi lama) ──────────────────────
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
    // Konten modul dimulai setelah ilustrasi (sedikit lebih tinggi dari Modul
    // karena Beranda tidak punya sub-header "Daftar Modul")
    final listStart = screenWidth * 0.54;

    const brown = Color(0xFF4A2F1D);
    final firstName = (user?.name.isNotEmpty ?? false)
        ? user!.name.split(' ').first
        : 'Sekar';

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Background ilustrasi (parallax ringan) ───────────────────
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              return Positioned(
                top: headerHeight - _scrollOffset,
                left: 0,
                right: 0,
                height: bgHeight,
                child: child!,
              );
            },
            child: Stack(
              children: [
                ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.05, 0.9, 1.0],
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

          // ── Top bar + konten scrollable ──────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopBar(context, isDark, bgColor),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ruang agar kartu muncul di bawah ilustrasi
                        SizedBox(height: listStart),

                        // Header seksi
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

                        // Kartu modul — pakai KbModuleCard persis seperti halaman Modul
                        ...provider.modules.map(
                          (m) => KbModuleCard(module: m, isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        return Container(
          height: _topBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          color: _scrollOffset > 4
              ? bgColor.withValues(alpha: 0.95)
              : Colors.transparent,
          child: child,
        );
      },
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

          // Lonceng notifikasi
          GestureDetector(
            onTap: () {
              // TODO: buka halaman notifikasi
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                boxShadow: _softShadow,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF4A2F1D),
                    size: 24,
                  ),
                  Positioned(
                    top: 11,
                    right: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9534F),
                        shape: BoxShape.circle,
                        border: Border.all(color: surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modal pencarian (dipertahankan dari versi lama) ──────────────────────────
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
