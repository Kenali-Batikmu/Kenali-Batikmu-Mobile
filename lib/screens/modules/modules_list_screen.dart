import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/kb_module_card.dart';

class ModulesListScreen extends StatefulWidget {
  const ModulesListScreen({super.key});

  @override
  State<ModulesListScreen> createState() => _ModulesListScreenState();
}

class _ModulesListScreenState extends State<ModulesListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _sortFilter = 'all'; // 'all', 'completed', 'in_progress', 'not_started'

  // Tinggi top bar tetap supaya posisi background bisa dihitung presisi
  static const double _topBarHeight = 68;

  // Rasio gambar background: 1170 x 1560
  static const double _bgRatio = 1560 / 1170;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double get _scrollOffset {
    if (!_scrollController.hasClients) return 0;
    final o = _scrollController.offset;
    return o < 0 ? 0 : o; // jangan bergerak saat overscroll
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
    final screenWidth = MediaQuery.of(context).size.width;
    final safeTop = MediaQuery.of(context).padding.top;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFFBF3E3);

    // Semua ukuran dihitung dari lebar layar agar selalu proporsional dengan gambar
    final headerHeight = safeTop + _topBarHeight;
    final bgHeight = screenWidth * _bgRatio;
    final textLeft = screenWidth * 0.09;
    final textTop = screenWidth * 0.10; // makin kecil = makin naik
    final textWidth = screenWidth * 0.46;
    final textHeight = screenWidth * 0.30;
    final listStart = screenWidth * 0.58; // awal daftar, tepat di bawah lengkungan krem

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

    const brown = Color(0xFF4A2F1D);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Background ilustrasi (ikut scroll, dimulai tepat di bawah top bar) ──
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
                // Fade di tepi atas & bawah agar menyatu dengan warna latar
                ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                    stops: [0.0, 0.05, 0.9, 1.0],
                  ).createShader(rect),
                  child: Image.asset(
                    'assets/images/module_bg.jpeg',
                    width: screenWidth,
                    height: bgHeight,
                    fit: BoxFit.fill,
                  ),
                ),

                // Teks sambutan: di kolom kiri, sejajar dengan tokoh kebaya
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
                          'Selamat\nmengerjakan!',
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

          // ── Top bar (tetap) + konten yang bisa di-scroll ──
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopBar(isDark, bgColor),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: listStart),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildListHeader(context, isDark),
                        ),
                        const SizedBox(height: 14),
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
                          ...displayModules.map((m) => _buildModuleCard(context, m, isDark)),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Footer berada di level MainNavigationScreen ──
        ],
      ),
    );
  }

  // ── Top bar: logo, search, lonceng (semua tinggi 46, bayangan seragam) ──
  List<BoxShadow> get _softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  Widget _buildTopBar(bool isDark, Color bgColor) {
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    const iconColor = Color(0xFF8A6D56);

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        return Container(
          height: _topBarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          color: _scrollOffset > 4 ? bgColor.withValues(alpha: 0.95) : Colors.transparent,
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
              child: Image.asset('assets/images/kb_logo.jpeg', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),

          // Search bar
          Expanded(
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
                  const Icon(Icons.search_rounded, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      textAlignVertical: TextAlignVertical.center,
                      style: AppTheme.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari modul batik...',
                        hintStyle: AppTheme.inter(fontSize: 13, color: const Color(0xFFA59284)),
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
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.close_rounded, size: 18, color: Color(0xFFA59284)),
                      ),
                    ),
                ],
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
                    color: isDark ? Colors.white : const Color(0xFF4A2F1D),
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

  // ── Sub header: "Daftar Modul Belajar" + tombol Urutkan ──
  Widget _buildListHeader(BuildContext context, bool isDark) {
    final label = switch (_sortFilter) {
      'completed' => 'Selesai',
      'in_progress' => 'Dikerjakan',
      'not_started' => 'Belum Mulai',
      _ => 'Urutkan',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Daftar Modul Belajar',
              style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
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
                  label,
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
    );
  }

  // Kartu modul: desain baru ada di class KbModuleCard (di bagian bawah file ini)
  Widget _buildModuleCard(BuildContext context, ModuleModel module, bool isDark) {
    return KbModuleCard(module: module, isDark: isDark);
  }
}