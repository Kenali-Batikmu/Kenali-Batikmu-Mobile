import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../kb_module_card.dart';
import 'load_more_controller.dart';

/// Section daftar modul dengan sistem "Load More on Scroll" (infinite-style batch loading):
///
/// ### Alur Kerja:
/// 1. Tampilan awal: Tepat **4 modul pertama**.
/// 2. Pengguna scroll ke bawah:
///    Saat mendekati dasar daftar modul, sistem otomatis memicu pemuatan batch berikutnya.
/// 3. Muncul **Ikon Load (Loading Indicator)** di bagian bawah selama **1 detik**.
/// 4. Setelah selesai loading, **4 modul tambahan muncul** (4 → 8 → 12 → 16 → 20)
///    dengan animasi fade-in + slide-up yang halus.
/// 5. Pengguna scroll lagi ke bawah → ikon load berputar 1 detik → tambah 4 modul lagi.
/// 6. Setelah seluruh 20 modul telah tampil, loading dihentikan dan ditampilkan
///    pesan: *"Semua 20 modul telah dimuat"*.
///
/// ### Responsive Grid:
/// - Mobile (< 640px): 1 kolom, card full-width (gap 14px)
/// - Tablet (640-1024px): 2 kolom grid (gap 16px)
/// - Desktop (> 1024px): 3 kolom grid proporsional (gap 20px)
class ModuleLoadMoreSection extends StatefulWidget {
  /// Seluruh modul yang sudah difilter (dari pencarian & sort).
  final List<ModuleModel> allModules;

  /// Apakah mode gelap aktif.
  final bool isDark;

  /// ScrollController dari parent SingleChildScrollView.
  final ScrollController scrollController;

  /// Jumlah modul per batch. Default: 4.
  final int batchSize;

  const ModuleLoadMoreSection({
    super.key,
    required this.allModules,
    required this.isDark,
    required this.scrollController,
    this.batchSize = 4,
  });

  @override
  State<ModuleLoadMoreSection> createState() => _ModuleLoadMoreSectionState();
}

class _ModuleLoadMoreSectionState extends State<ModuleLoadMoreSection> {
  late final LoadMoreController<ModuleModel> _controller;

  /// Set berisi ID modul yang sudah pernah ditampilkan.
  /// Modul baru pada batch berikutnya mendapat animasi fade-in + slide-up.
  final Set<int> _animatedModuleIds = {};

  @override
  void initState() {
    super.initState();
    _controller = LoadMoreController<ModuleModel>(
      batchSize: widget.batchSize,
    );
    _controller.setSource(widget.allModules);

    // Batch pertama: tandai sebagai sudah animasi (langsung tampil)
    for (final m in _controller.displayedItems) {
      _animatedModuleIds.add(m.id);
    }

    // Dengarkan event scroll untuk mendeteksi saat user scroll ke bawah
    widget.scrollController.addListener(_onScroll);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant ModuleLoadMoreSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Jika data modul sumber berubah (misal filter/search berubah), update controller
    if (!_listEquals(widget.allModules, oldWidget.allModules)) {
      _animatedModuleIds.clear();
      _controller.setSource(widget.allModules);
      for (final m in _controller.displayedItems) {
        _animatedModuleIds.add(m.id);
      }
    }

    // Jika scroll controller berganti, pindahkan listener
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  bool _listEquals(List<ModuleModel> a, List<ModuleModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  /// Deteksi otomatis saat user scroll ke bawah:
  /// Ketika posisi scroll mendekati bagian dasar (sisa 150px sebelum ujung bawah),
  /// sistem otomatis menjalankan pemuatan batch berikutnya.
  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    if (_controller.isLoading || _controller.allLoaded) return;

    final pos = widget.scrollController.position;
    final maxScroll = pos.maxScrollExtent;
    final currentScroll = pos.pixels;

    // Trigger saat scroll mendekati ujung bawah (sisa 150px)
    if (currentScroll >= (maxScroll - 150)) {
      _controller.loadNextBatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _controller.displayedItems;

    if (displayed.isEmpty && widget.allModules.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // ── Responsive Breakpoints ──
        // Mobile (< 640px): 1 kolom
        // Tablet (640-1024px): 2 kolom
        // Desktop (> 1024px): 3 kolom
        final int columnCount;
        final double gap;
        final EdgeInsets gridPadding;

        if (screenWidth >= 1024) {
          columnCount = 3;
          gap = 20.0;
          gridPadding = const EdgeInsets.symmetric(horizontal: 20);
        } else if (screenWidth >= 640) {
          columnCount = 2;
          gap = 16.0;
          gridPadding = const EdgeInsets.symmetric(horizontal: 16);
        } else {
          columnCount = 1;
          gap = 14.0;
          gridPadding = EdgeInsets.zero;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Grid Modul (Responsive) ──
            if (columnCount == 1) ...[
              // Mobile 1-kolom
              for (int i = 0; i < displayed.length; i++)
                _buildAnimatedCard(displayed[i], i, isGrid: false),
            ] else ...[
              // Tablet / Desktop Multi-kolom (Wrap Layout)
              Padding(
                padding: gridPadding,
                child: _buildMultiColumnGrid(
                  displayed: displayed,
                  columnCount: columnCount,
                  gap: gap,
                  totalWidth: screenWidth - gridPadding.horizontal,
                ),
              ),
            ],

            // ── Ikon Load (Loading Indicator) saat scroll ke bawah (1 detik) ──
            if (_controller.isLoading)
              _buildLoadingIconSection(context),

            // ── Pesan "Semua modul telah dimuat" setelah 20 modul tampil ──
            if (_controller.allLoaded && widget.allModules.length > widget.batchSize)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (widget.isDark
                                  ? const Color(0xFFE8C98A)
                                  : AppTheme.primary)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 24,
                          color: widget.isDark
                              ? const Color(0xFFE8C98A)
                              : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Semua ${widget.allModules.length} modul telah dimuat',
                        style: AppTheme.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark
                              ? Colors.white70
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Selamat belajar dan eksplorasi kekayaan batik Nusantara!',
                        style: AppTheme.inter(
                          fontSize: 11,
                          color: widget.isDark
                              ? Colors.white38
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Tampilan Ikon Load (Loading Indicator) di bawah modul:
  /// Muncul selama 1 detik sebelum 4 modul tambahan berikutnya ditampilkan.
  Widget _buildLoadingIconSection(BuildContext context) {
    final isDark = widget.isDark;
    const gold = Color(0xFFE8C98A);
    const darkGold = Color(0xFF7B3A1A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE5D3B8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? gold : darkGold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Memuat 4 modul berikutnya...',
                style: AppTheme.satoshi(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? gold : darkGold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Menyiapkan materi modul (${_controller.displayCount}/${widget.allModules.length})',
                style: AppTheme.inter(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun grid multi-kolom untuk Tablet & Desktop menggunakan Wrap.
  Widget _buildMultiColumnGrid({
    required List<ModuleModel> displayed,
    required int columnCount,
    required double gap,
    required double totalWidth,
  }) {
    final itemWidth = (totalWidth - (gap * (columnCount - 1))) / columnCount;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (int i = 0; i < displayed.length; i++)
          SizedBox(
            width: itemWidth,
            child: _buildAnimatedCard(displayed[i], i, isGrid: true),
          ),
      ],
    );
  }

  /// Membungkus KbModuleCard dengan:
  /// 1. Efek interaktif hover/tap (scale 1.02 + shadow)
  /// 2. Animasi fade-in + slide-up untuk modul baru
  Widget _buildAnimatedCard(ModuleModel module, int indexInDisplayed, {required bool isGrid}) {
    final isNewlyLoaded = !_animatedModuleIds.contains(module.id);

    if (isNewlyLoaded) {
      _animatedModuleIds.add(module.id);
    }

    final cardWidget = _InteractiveCard(
      child: KbModuleCard(
        module: module,
        isDark: widget.isDark,
        margin: isGrid ? EdgeInsets.zero : null,
      ),
    );

    // Batch pertama: langsung tampil tanpa delay animasi
    if (!isNewlyLoaded) return cardWidget;

    // Stagger delay antar card dalam batch (80ms per card)
    final positionInBatch = indexInDisplayed % widget.batchSize;

    return _FadeSlideIn(
      delay: Duration(milliseconds: positionInBatch * 80),
      child: cardWidget,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  WIDGET INTERAKTIF: HOVER & TAP SCALE + SHADOW
// ═══════════════════════════════════════════════════════════════════════════

/// Membungkus card dengan efek hover/tap:
/// - Skala sedikit membesar (1.02x) saat disentuh/hover
/// - Shadow meningkat lembut untuk memberikan kedalaman visual
class _InteractiveCard extends StatefulWidget {
  final Widget child;

  const _InteractiveCard({required this.child});

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isPressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: isActive ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ANIMASI FADE-IN + SLIDE-UP
// ═══════════════════════════════════════════════════════════════════════════

/// Widget animasi fade-in + slide-up untuk card modul baru.
/// Cleanup otomatis: AnimationController di-dispose saat unmount.
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // Slide-up: mulai dari 24px di bawah posisi akhir
    _slide = Tween<Offset>(
      begin: const Offset(0, 24),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    // Delay sebelum memulai animasi (stagger effect antar card)
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: _slide.value,
          child: Opacity(
            opacity: _opacity.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
