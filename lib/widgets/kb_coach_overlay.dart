import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

const Color _kBtnBrown = Color(0xFF7B3A1A); // coklat tombol
const Color _kGold = Color(0xFFE8C98A); // emas
const Color _kGoldDeep = Color(0xFFC4882F); // emas tua (titik aktif)
const Color _kCream = Color(0xFFFFFDF8); // latar kartu
const Color _kInk = Color(0xFF4A2F1D); // judul
const Color _kBody = Color(0xFF6F5744); // teks isi
const Color _kScrim = Color(0xFF120A05); // warna penggelap halaman

/// Bentuk lubang sorotan di sekitar elemen target.
enum KbCoachShape { circle, roundedRect }

/// Satu langkah tur. Bila [targetKey] null, langkah ini adalah sambutan:
/// seluruh halaman digelapkan dan kartu tampil di tengah layar.
class KbCoachStep {
  final GlobalKey? targetKey;
  final String title;
  final String body;
  final IconData icon;
  final KbCoachShape shape;

  /// Jarak lubang sorotan dari tepi elemen target.
  final double padding;

  /// Radius sudut lubang (dipakai untuk [KbCoachShape.roundedRect]).
  final double cornerRadius;

  const KbCoachStep({
    required this.title,
    required this.body,
    required this.icon,
    this.targetKey,
    this.shape = KbCoachShape.roundedRect,
    this.padding = 8,
    this.cornerRadius = 16,
  });

  bool get isWelcome => targetKey == null;
}

/// Overlay tur ala "coach mark": menggelapkan seluruh layar kecuali bagian
/// yang sedang dijelaskan, lalu menampilkan kartu penjelasan di dekatnya.
///
/// Letakkan di atas halaman (misalnya di dalam Stack dengan Positioned.fill).
/// Seluruh sentuhan di luar kartu diserap sehingga halaman di belakangnya
/// tidak bisa diketuk selama tur berlangsung.
class KbCoachOverlay extends StatefulWidget {
  final List<KbCoachStep> steps;

  /// Dipanggil setelah overlay selesai memudar.
  /// [completed] bernilai true bila pengguna menamatkan semua langkah,
  /// false bila menekan "Lewati".
  final void Function(bool completed) onFinish;

  const KbCoachOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
  }) : assert(steps.length > 0, 'Tur membutuhkan minimal satu langkah');

  @override
  State<KbCoachOverlay> createState() => _KbCoachOverlayState();
}

class _KbCoachOverlayState extends State<KbCoachOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _anim;

  int _index = 0;

  // Lubang sorotan beranimasi dari [_fromRect] ke [_toRect]. null = tanpa lubang
  // (langkah sambutan); dalam animasi, null diperlakukan sebagai titik di tengah.
  Rect? _fromRect;
  Rect? _toRect;
  double _fromRadius = 0;
  double _toRadius = 0;

  Size _size = Size.zero;
  bool _visible = false;
  bool _closing = false;
  bool _closingCompleted = false;
  bool _busy = false;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
      _showStep(0, animate: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _anim.dispose();
    super.dispose();
  }

  // Ukuran layar berubah (rotasi, mode jendela): ukur ulang tanpa animasi.
  @override
  void didChangeMetrics() {
    if (!mounted || _closing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_closing) _showStep(_index, animate: false);
    });
  }

  // ── Perhitungan lubang sorotan ─────────────────────────────────────────────

  Rect _resolve(Rect? r) =>
      r ?? Rect.fromCenter(center: _size.center(Offset.zero), width: 0, height: 0);

  double get _t => Curves.easeInOutCubic.transform(_anim.value);

  Rect get _currentRect => Rect.lerp(_resolve(_fromRect), _resolve(_toRect), _t)!;

  double get _currentRadius => lerpDouble(_fromRadius, _toRadius, _t) ?? 0;

  /// Mengukur posisi target relatif terhadap overlay ini.
  ({Rect rect, double radius})? _measure(KbCoachStep step) {
    final targetObject = step.targetKey?.currentContext?.findRenderObject();
    final overlayObject = context.findRenderObject();
    if (targetObject is! RenderBox ||
        overlayObject is! RenderBox ||
        !targetObject.attached ||
        !targetObject.hasSize ||
        !overlayObject.hasSize) {
      return null;
    }

    final topLeft =
        overlayObject.globalToLocal(targetObject.localToGlobal(Offset.zero));
    final raw = topLeft & targetObject.size;

    if (step.shape == KbCoachShape.circle) {
      final r = math.max(raw.width, raw.height) / 2 + step.padding;
      return (rect: Rect.fromCircle(center: raw.center, radius: r), radius: r);
    }
    return (rect: raw.inflate(step.padding), radius: step.cornerRadius);
  }

  /// Menggulir halaman bila target berada di luar area yang nyaman dilihat
  /// (tersembunyi di bawah footer atau di balik top bar).
  Future<void> _ensureVisible(BuildContext targetContext) async {
    if (Scrollable.maybeOf(targetContext) == null) return;
    final box = targetContext.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;

    final media = MediaQuery.of(context);
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    const navHeight = 100.0; // tinggi footer (lihat KbBottomNav)
    final minTop = media.padding.top + 76;
    final maxBottom = media.size.height - navHeight - media.padding.bottom - 16;

    if (top >= minTop && bottom <= maxBottom) return;

    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.3,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ── Navigasi langkah ───────────────────────────────────────────────────────

  Future<void> _showStep(int i, {bool animate = true}) async {
    final token = ++_token;
    _busy = true;

    final step = widget.steps[i];
    Rect? target;
    double radius = 0;

    final targetContext = step.targetKey?.currentContext;
    if (targetContext != null) {
      await _ensureVisible(targetContext);
      if (!mounted || token != _token) return;
      final m = _measure(step);
      if (m != null) {
        target = m.rect;
        radius = m.radius;
      }
    }
    if (!mounted || token != _token) return;

    final startRect = animate ? _currentRect : target;
    final startRadius = animate ? _currentRadius : radius;

    setState(() {
      _fromRect = startRect;
      _fromRadius = startRadius;
      _toRect = target;
      _toRadius = radius;
      _index = i;
    });

    if (animate) {
      _anim.forward(from: 0);
    } else {
      _anim.value = 1;
    }
    _busy = false;
  }

  void _next() {
    if (_busy || _closing) return;
    if (_index >= widget.steps.length - 1) {
      _close(completed: true);
    } else {
      _showStep(_index + 1);
    }
  }

  void _prev() {
    if (_busy || _closing || _index == 0) return;
    _showStep(_index - 1);
  }

  void _skip() {
    if (_closing) return;
    _close(completed: false);
  }

  void _close({required bool completed}) {
    setState(() {
      _closing = true;
      _closingCompleted = completed;
    });
  }

  // ── Tampilan ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol kembali Android selama tur = langkah sebelumnya, bukan keluar aplikasi.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _prev();
      },
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedOpacity(
          opacity: (_visible && !_closing) ? 1 : 0,
          duration: const Duration(milliseconds: 260),
          onEnd: () {
            if (_closing) widget.onFinish(_closingCompleted);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              _size = constraints.biggest;
              return Stack(
                children: [
                  // Lapisan gelap + lubang sorotan. Menyerap semua ketukan.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) => CustomPaint(
                          painter: _SpotlightPainter(
                            rect: _currentRect,
                            radius: _currentRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Kartu penjelasan
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_index),
                        child: _buildTooltip(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip() {
    final step = widget.steps[_index];
    final target = _toRect;
    final isFirst = _index == 0;
    final isLast = _index == widget.steps.length - 1;

    final card = _CoachCard(
      step: step,
      index: _index,
      count: widget.steps.length,
      isFirst: isFirst,
      isLast: isLast,
      onNext: _next,
      onBack: _prev,
      onSkip: _skip,
    );

    // Langkah sambutan: kartu di tengah layar.
    if (target == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: card,
        ),
      );
    }

    // Target di separuh bawah layar -> kartu di atasnya, dan sebaliknya.
    const sideMargin = 16.0;
    const gap = 12.0;
    const pointerW = 20.0;
    const pointerH = 10.0;

    final above = target.center.dy > _size.height * 0.5;
    final cardWidth = math.max(0.0, _size.width - sideMargin * 2);
    final pointerX = (target.center.dx - sideMargin)
        .clamp(28.0, math.max(28.0, cardWidth - 28.0))
        .toDouble();

    return Stack(
      children: [
        Positioned(
          left: sideMargin,
          right: sideMargin,
          top: above ? null : target.bottom + gap,
          bottom: above ? _size.height - target.top + gap : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: above ? 0 : pointerH,
                  bottom: above ? pointerH : 0,
                ),
                child: card,
              ),
              Positioned(
                left: pointerX - pointerW / 2,
                top: above ? null : 0.5,
                bottom: above ? 0.5 : null,
                child: CustomPaint(
                  size: const Size(pointerW, pointerH),
                  painter: _PointerPainter(pointsUp: !above),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Kartu penjelasan ───────────────────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  final KbCoachStep step;
  final int index;
  final int count;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _CoachCard({
    required this.step,
    required this.index,
    required this.count,
    required this.isFirst,
    required this.isLast,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final centered = step.isWelcome;
    final nextLabel = isFirst ? 'Mulai' : (isLast ? 'Selesai' : 'Lanjut');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        decoration: BoxDecoration(
          color: _kCream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGold, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            if (centered) ...[
              Image.asset(
                'assets/images/logo_1.webp',
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    _IconBadge(icon: step.icon),
              ),
              const SizedBox(height: 12),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: AppTheme.satoshi(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _kInk,
                  height: 1.25,
                ),
              ),
            ] else
              Row(
                children: [
                  _IconBadge(icon: step.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: AppTheme.satoshi(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _kInk,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Text(
              step.body,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: AppTheme.inter(
                fontSize: 13,
                height: 1.5,
                color: _kBody,
              ),
            ),
            const SizedBox(height: 14),
            _StepDots(index: index, count: count),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!isLast)
                  TextButton(
                    key: const Key('kb_coach_skip'),
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: _kBody,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Lewati',
                      style: AppTheme.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kBody,
                      ),
                    ),
                  ),
                const Spacer(),
                if (!isFirst) ...[
                  TextButton(
                    key: const Key('kb_coach_back'),
                    onPressed: onBack,
                    style: TextButton.styleFrom(
                      foregroundColor: _kBtnBrown,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Kembali',
                      style: AppTheme.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kBtnBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                ElevatedButton(
                  key: const Key('kb_coach_next'),
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBtnBrown,
                    foregroundColor: _kCream,
                    elevation: 0,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nextLabel,
                        style: AppTheme.satoshi(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _kCream,
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: _kGold, shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: const Color(0xFF3E2418)),
    );
  }
}

class _StepDots extends StatelessWidget {
  final int index;
  final int count;
  const _StepDots({required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 5),
            width: i == index ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? _kGoldDeep
                  : _kGoldDeep.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          '${index + 1} dari $count',
          style: AppTheme.inter(fontSize: 11, color: const Color(0xFF8A6D56)),
        ),
      ],
    );
  }
}

// ── Painter ────────────────────────────────────────────────────────────────────

/// Menggambar lapisan gelap dengan lubang di [rect], plus cincin emas di tepinya.
class _SpotlightPainter extends CustomPainter {
  final Rect rect;
  final double radius;

  const _SpotlightPainter({required this.rect, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final scrim = Paint()..color = _kScrim.withValues(alpha: 0.82);

    // Tanpa lubang (langkah sambutan atau saat lubang menyusut ke titik).
    if (rect.width < 1 || rect.height < 1) {
      canvas.drawRect(full, scrim);
      return;
    }

    final hole = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.min(radius, math.min(rect.width, rect.height) / 2)),
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(hole),
    );
    canvas.drawPath(path, scrim);

    // Cahaya lembut + garis emas di tepi lubang
    canvas.drawRRect(
      hole.inflate(2),
      Paint()
        ..color = _kGold.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..color = _kGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.rect != rect || old.radius != radius;
}

/// Segitiga kecil yang menunjuk ke elemen target dari tepi kartu.
class _PointerPainter extends CustomPainter {
  final bool pointsUp;
  const _PointerPainter({required this.pointsUp});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final edge = Path();
    if (pointsUp) {
      edge
        ..moveTo(0, h)
        ..lineTo(w / 2, 0)
        ..lineTo(w, h);
    } else {
      edge
        ..moveTo(0, 0)
        ..lineTo(w / 2, h)
        ..lineTo(w, 0);
    }

    canvas.drawPath(Path.from(edge)..close(), Paint()..color = _kCream);
    canvas.drawPath(
      edge,
      Paint()
        ..color = _kGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PointerPainter old) =>
      old.pointsUp != pointsUp;
}
