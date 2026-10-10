import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/kb_module_card.dart';
import '../modules/module_detail_screen.dart';
import '../../services/search_history_service.dart';

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
  late final PageController _pageController;
  Timer? _heroTimer;
  int _currentHeroPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startHeroTimer();
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_pageController.hasClients) return;
      final nextPage = (_currentHeroPage + 1) % 4;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Modal pencarian ──────────────────────────────────────────────────────
  void _showSearchSheet(BuildContext context, bool isDark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup pencarian',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        );
      },
      pageBuilder: (ctx, anim, secondAnim) {
        return _SearchModalContent(
          isDark: isDark,
          onOpenModules: widget.onOpenModules,
        );
      },
    );
  }

  // ── Kartu Hero PageView Full-Bleed ───────────────────────────────────────
  Widget _buildHeroHeader(
    BuildContext context,
    String firstName,
    bool isDark,
    double safeTop,
    double heroHeight,
  ) {
    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            // ── Lapisan bawah: PageView ──
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentHeroPage = index;
                });
                _startHeroTimer();
              },
              children: [
                _buildSlide1(firstName),
                _buildBatikSlide(
                  title: 'Warisan Dunia',
                  description:
                      'Batik Indonesia diakui UNESCO sebagai Warisan Budaya Takbenda sejak 2009.',
                  tag: 'WARISAN BUDAYA',
                  icon: Icons.public_rounded,
                ),
                _buildBatikSlide(
                  title: 'Parang',
                  description:
                      'Motif tertua yang melambangkan kekuatan dan keteguhan hati.',
                  tag: 'MOTIF BATIK',
                  icon: Icons.waves_rounded,
                ),
                _buildBatikSlide(
                  title: 'Kawung',
                  description:
                      'Pola lingkaran yang melambangkan kesucian dan keadilan.',
                  tag: 'MOTIF BATIK',
                  icon: Icons.grain_rounded,
                ),
              ],
            ),

            // ── Lapisan atas: Gradasi gelap tipis (agar status bar/ikon terbaca) ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: safeTop + 76,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Lapisan atas: App Bar (logo KB, search, profil) ──
            Positioned(
              top: safeTop + 12,
              left: 0,
              right: 0,
              child: _buildTopBar(context, isDark),
            ),

            // ── Indikator titik di dasar hero ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => _buildDot(index)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentHeroPage == index;
    final isLightSlide = _currentHeroPage == 0;

    final activeColor = isLightSlide
        ? const Color(0xFFC4882F)
        : const Color(0xFFE8C98A);
    final inactiveColor = isLightSlide
        ? Colors.grey.shade500.withValues(alpha: 0.5)
        : const Color(0xFFE8C98A).withValues(alpha: 0.35);

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3.5),
        width: isActive ? 22 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: isActive ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildSlide1(String firstName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTextWidth = constraints.maxWidth * 0.48;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hero_sekar.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.6, 0.3),
            ),
            Positioned(
              left: 20,
              bottom: 40,
              width: maxTextWidth,
              child: Text(
                'Selamat Datang,\n$firstName!',
                style: AppTheme.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A2F1D),
                  height: 1.22,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBatikSlide({
    required String title,
    required String description,
    String? tag,
    IconData? icon,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: const Color(0xFF2E1911),
          child: const CustomPaint(
            painter: _KawungHeroPainter(
              color: Color(0xFFE8C98A),
              opacity: 0.18,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.88),
                ],
                stops: const [0.15, 0.55, 1.0],
              ),
            ),
          ),
        ),
        if (icon != null)
          Positioned(
            top: 75,
            right: 20,
            child: Icon(
              icon,
              size: 52,
              color: const Color(0xFFE8C98A).withValues(alpha: 0.14),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (tag != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8C98A).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE8C98A).withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: AppTheme.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE8C98A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                title,
                style: AppTheme.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: AppTheme.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFFBF3E3);

    final heroHeight = (screenHeight * 0.40).clamp(310.0, 360.0);

    final firstName = (user?.name.isNotEmpty ?? false)
        ? user!.name.split(' ').first
        : 'Sekar';

    return Scaffold(
      backgroundColor: bgColor,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(context, firstName, isDark, safeTop, heroHeight),
              const SizedBox(height: 20),

              // ── Header Riwayat Belajar ─────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Riwayat Belajar',
                  style: AppTheme.satoshi(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A2F1D),
                  ),
                ),
              ),
              const SizedBox(height: 14),

                        // ── Carousel KbModuleCard horizontal ───────────
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

                          final unfinished = [...inProgress, ...notStarted];

                          // Jika semua selesai, tampilkan modul terakhir saja
                          if (unfinished.isEmpty) {
                            final lastModule = finished.isNotEmpty
                                ? finished.last
                                : provider.modules.first;
                            return KbModuleCard(module: lastModule, isDark: isDark);
                          }

                          // Jika hanya 1 modul belum selesai, tampilkan penuh
                          if (unfinished.length == 1) {
                            return KbModuleCard(module: unfinished.first, isDark: isDark);
                          }

                          // Carousel horizontal untuk > 1 modul belum selesai
                          final cardWidth = screenWidth * 0.92;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 16, right: 16),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 0; i < unfinished.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 12),
                                    SizedBox(
                                      width: cardWidth,
                                      child: KbModuleCard(
                                        module: unfinished[i],
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),

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
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4A2F1D),
                                ),
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
              );
  }

  // ── Top bar floating di atas hero slide ──────────────────────────────────
  List<BoxShadow> get _softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  Widget _buildTopBar(BuildContext context, bool isDark) {
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    const iconColor = Color(0xFF8A6D56);
    final provider = context.read<AppProvider>();
    final user = provider.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo KB
          Container(
            width: 44,
            height: 44,
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
          const SizedBox(width: 10),

          // Search bar (fungsional → buka modal pencarian)
          Expanded(
            child: GestureDetector(
              onTap: () => _showSearchSheet(context, isDark),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(22),
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
          const SizedBox(width: 10),

          // Profile Avatar (Clickable: opens Profile tab)
          GestureDetector(
            onTap: widget.onOpenProfile,
            child: Container(
              width: 42,
              height: 42,
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
                    fontSize: 17,
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
  List<int> _historyIds = [];

  // Warna ikon normal & pressed — reuse warna dari KbModuleCard
  static const Color _iconNormal = AppTheme.primaryDark; // 0xFF543118
  static const Color _iconPressed = Color(0xFF3E2418);   // _kBrown di kb_module_card

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await SearchHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _historyIds = history;
      });
    }
  }

  void _onModuleTapped(dynamic module) {
    SearchHistoryService.addToHistory(module.id);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleDetailScreen(module: module),
      ),
    );
  }

  void _removeFromHistory(int moduleId) {
    SearchHistoryService.removeFromHistory(moduleId);
    setState(() {
      _historyIds.remove(moduleId);
    });
  }

  void _clearHistory() {
    SearchHistoryService.clearHistory();
    setState(() {
      _historyIds.clear();
    });
  }

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

    // Ambil data modul terbaru untuk riwayat pencarian (berdasarkan urutan _historyIds)
    final historyModules = <dynamic>[];
    for (final id in _historyIds) {
      final matches = provider.modules.where((m) => m.id == id);
      if (matches.isNotEmpty) {
        historyModules.add(matches.first);
      }
    }

    final safeTop = MediaQuery.of(context).padding.top;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          margin: EdgeInsets.only(bottom: viewInsetsBottom),
          padding: EdgeInsets.only(
            top: safeTop + 16,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            color: widget.isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (val) => setState(() => _query = val),
                style: AppTheme.inter(
                    color: widget.isDark
                        ? Colors.white
                        : AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari motif atau modul batik...',
                  hintStyle: AppTheme.inter(
                      fontSize: 13, color: const Color(0xFFA59284)),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF8A6D56)),
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
                  fillColor:
                      widget.isDark ? AppTheme.darkSurface : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(23),
                    borderSide: BorderSide(
                        color: widget.isDark
                            ? AppTheme.darkBorder
                            : AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(23),
                    borderSide: BorderSide(
                        color: widget.isDark
                            ? AppTheme.darkBorder
                            : AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(23),
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                       horizontal: 16, vertical: 12),
                ),
              ),
              if (_query.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Hasil Pencarian (${filteredModules.length}):',
                  style: AppTheme.satoshi(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: filteredModules.isEmpty
                      ? Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Modul tidak ditemukan',
                              style: AppTheme.inter(
                                  fontSize: 13,
                                  color: AppTheme.textMuted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filteredModules.length,
                          itemBuilder: (ctx, idx) {
                            final m = filteredModules[idx];
                            return _SearchResultTile(
                              module: m,
                              isDark: widget.isDark,
                              iconNormal: _iconNormal,
                              iconPressed: _iconPressed,
                              onTap: () => _onModuleTapped(m),
                            );
                          },
                        ),
                ),
              ] else if (historyModules.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Pencarian',
                      style: AppTheme.satoshi(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: _clearHistory,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Hapus semua',
                        style: AppTheme.inter(
                          fontSize: 12,
                          color: widget.isDark
                              ? AppTheme.secondaryLight
                              : AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: historyModules.length,
                    itemBuilder: (ctx, idx) {
                      final m = historyModules[idx];
                      return _SearchResultTile(
                        module: m,
                        isDark: widget.isDark,
                        iconNormal: _iconNormal,
                        iconPressed: _iconPressed,
                        onTap: () => _onModuleTapped(m),
                        onDelete: () => _removeFromHistory(m.id),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Item hasil pencarian dengan efek pressed (ikon menggelap).
class _SearchResultTile extends StatefulWidget {
  final dynamic module;
  final bool isDark;
  final Color iconNormal;
  final Color iconPressed;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SearchResultTile({
    required this.module,
    required this.isDark,
    required this.iconNormal,
    required this.iconPressed,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<_SearchResultTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _pressed = false),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _pressed ? widget.iconPressed : widget.iconNormal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                        child: Icon(Icons.menu_book,
                            color: Colors.white, size: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.satoshi(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kemajuan: ${m.progressPercent}% Selesai',
                          style: AppTheme.inter(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.onDelete != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onDelete,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Icon(Icons.close, size: 18, color: AppTheme.textMuted),
              ),
            )
          else
            GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
              onTapCancel: () => setState(() => _pressed = false),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.chevron_right, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

/// Motif kawung: empat kelopak lonjong bertemu di satu titik, diulang memenuhi area
class _KawungHeroPainter extends CustomPainter {
  final Color color;
  final double opacity;
  const _KawungHeroPainter({required this.color, this.opacity = 1});

  static const double cell = 26;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    final line = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint()..color = color.withValues(alpha: opacity);

    final long = cell / 2;
    final short = cell * 0.31;
    final q = cell / 4;

    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final c = Offset(x + cell / 2, y + cell / 2);
        canvas.drawOval(
            Rect.fromCenter(
                center: c.translate(0, -q), width: short, height: long),
            line);
        canvas.drawOval(
            Rect.fromCenter(
                center: c.translate(0, q), width: short, height: long),
            line);
        canvas.drawOval(
            Rect.fromCenter(
                center: c.translate(-q, 0), width: long, height: short),
            line);
        canvas.drawOval(
            Rect.fromCenter(
                center: c.translate(q, 0), width: long, height: short),
            line);
        canvas.drawCircle(c, 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KawungHeroPainter old) =>
      old.color != color || old.opacity != opacity;
}

