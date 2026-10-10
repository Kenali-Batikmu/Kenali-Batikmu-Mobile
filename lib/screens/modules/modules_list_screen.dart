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
              _buildSortOption('all', 'Semua Modul (${context.read<AppProvider>().modules.length} Modul)', ctx),
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

// ══════════════════════════════════════════════════════════════════════════
//  KARTU MODUL — header coklat tua bermotif kawung + tepi bergelombang emas
// ══════════════════════════════════════════════════════════════════════════

const Color _kBrown = Color(0xFF3E2418); // coklat tua header
const Color _kBtnBrown = Color(0xFF7B3A1A); // coklat tombol & progres
const Color _kBatik = Color(0xFF8A5A3C); // garis motif kawung
const Color _kGold = Color(0xFFE8C98A); // emas (lencana, garis gelombang, tombol)
const Color _kGoldDeep = Color(0xFFC9A16E); // emas lebih tua (progres selesai)
const Color _kGoldLine = Color(0xFFCFA967); // motif kawung di atas tombol emas
const Color _kCream = Color(0xFFFBF0E0); // krem untuk teks di latar coklat
const Color _kChipBg = Color(0xFFFBF3E3);
const Color _kChipBorder = Color(0xFFE3D2B4);

const double _kHeaderHeight = 108;
const double _kWaveHeight = 18;

class KbModuleCard extends StatelessWidget {
  final ModuleModel module;
  final bool isDark;

  const KbModuleCard({super.key, required this.module, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final num progress = module.progressPercent;
    final isDone = progress >= 100;
    final isWorking = module.id == 3 || (progress > 0 && progress < 100);

    final bodyColor = isDark ? AppTheme.darkSurface : const Color(0xFFFFFDF8);
    final borderColor = isWorking
        ? AppTheme.accentGold.withValues(alpha: 0.6)
        : (isDark ? AppTheme.darkBorder : const Color(0xFFE5D3B8));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bodyColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isWorking ? 1.5 : 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, bodyColor, isDone, isWorking, progress),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
              child: _buildBody(context, isDone, isWorking, progress),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: motif kawung, label modul, lencana, judul, tepi bergelombang ──
  Widget _buildHeader(BuildContext context, Color bodyColor, bool isDone, bool isWorking, num progress) {
    return SizedBox(
      height: _kHeaderHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              color: _kBrown,
              child: const CustomPaint(
                painter: _KawungPainter(color: _kBatik, opacity: 0.75),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MODUL ${module.orderNo}/${context.read<AppProvider>().modules.length}',
                      style: AppTheme.satoshi(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: _kGold,
                      ),
                    ),
                    if (isDone) _badge('Selesai', check: true),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  module.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.satoshi(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _kCream,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: _kWaveHeight,
            child: CustomPaint(painter: _WavePainter(fill: bodyColor)),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, {bool check = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _kGold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (check) ...[
            const Icon(Icons.check_rounded, size: 13, color: _kBrown),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: AppTheme.satoshi(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _kBrown,
            ),
          ),
        ],
      ),
    );
  }

  // ── Badan kartu: deskripsi, progres, tombol aksi, chip nilai ──
  Widget _buildBody(BuildContext context, bool isDone, bool isWorking, num progress) {
    final fraction = (progress / 100).clamp(0.0, 1.0).toDouble();

    final theory = isDone
        ? (module.id == 1 ? 'Nilai Teori: 80%' : 'Nilai Teori: 100%')
        : (module.quizDone ? 'Nilai Teori: 80%' : 'Nilai Teori: 0%');
    final practice = isDone
        ? 'Nilai Praktikum: 100%'
        : (module.practiceDone ? 'Nilai Praktikum: 70%' : 'Nilai Praktikum: 0%');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          module.description,
          style: AppTheme.inter(
            fontSize: 12,
            height: 1.45,
            color: isDark ? Colors.white70 : const Color(0xFF6F5744),
          ),
        ),
        const SizedBox(height: 12),

        // Progres belajar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progres belajar',
              style: AppTheme.inter(fontSize: 11, color: const Color(0xFF8A6D56)),
            ),
            Text(
              '$progress%',
              style: AppTheme.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? _kGold : _kBtnBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(
                height: 6,
                color: isDark ? Colors.white12 : const Color(0xFFF1E4CC),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 6,
                  color: isDone ? _kGoldDeep : _kBtnBrown,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildActionButton(context, isDone, isWorking),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _scoreChip(theory)),
            const SizedBox(width: 8),
            Expanded(child: _scoreChip(practice)),
          ],
        ),
      ],
    );
  }

  // Tombol aksi: emas bermotif (Mulai / Lanjutkan belajar) atau coklat bermotif (Buka kembali materi)
  Widget _buildActionButton(BuildContext context, bool isDone, bool isWorking) {
    final label = isDone
        ? 'Buka Kembali Materi'
        : (isWorking ? 'Lanjutkan Belajar' : 'Mulai Belajar');
    final bg = isDone ? _kBtnBrown : _kGold;
    final fg = isDone ? _kCream : _kBrown;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: module)),
          );
        },
        child: SizedBox(
          height: 46,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _KawungPainter(
                    color: isDone ? _kBatik : _kGoldLine,
                    opacity: isDone ? 0.5 : 0.6,
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTheme.satoshi(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: fg,
                      ),
                    ),
                    if (!isDone) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 17, color: fg),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: _kChipBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kChipBorder, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5C3D1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Motif kawung: empat kelopak lonjong bertemu di satu titik, diulang memenuhi area
class _KawungPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double cell;

  const _KawungPainter({required this.color, this.opacity = 1, this.cell = 26});

  @override
  void paint(Canvas canvas, Size size) {
    // Potong gambar tepat di batas area supaya motif tidak "tumpah" ke bawah
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
        canvas.drawOval(Rect.fromCenter(center: c.translate(0, -q), width: short, height: long), line);
        canvas.drawOval(Rect.fromCenter(center: c.translate(0, q), width: short, height: long), line);
        canvas.drawOval(Rect.fromCenter(center: c.translate(-q, 0), width: long, height: short), line);
        canvas.drawOval(Rect.fromCenter(center: c.translate(q, 0), width: long, height: short), line);
        canvas.drawCircle(c, 1.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KawungPainter old) =>
      old.color != color || old.opacity != opacity || old.cell != cell;
}

// Tepi bawah header yang bergelombang, berwarna sama dengan badan kartu + garis emas tipis
class _WavePainter extends CustomPainter {
  final Color fill;

  const _WavePainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 340;
    final h = size.height;

    final edge = Path()
      ..moveTo(0, 10)
      ..cubicTo(40 * sx, 2, 80 * sx, 18, 130 * sx, 10)
      ..cubicTo(180 * sx, 2, 230 * sx, 18, 280 * sx, 10)
      ..cubicTo(310 * sx, 5, 330 * sx, 8, 340 * sx, 6);

    final area = Path.from(edge)
      ..lineTo(size.width, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(area, Paint()..color = fill);
    canvas.drawPath(
      edge,
      Paint()
        ..color = _kGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.fill != fill;
}