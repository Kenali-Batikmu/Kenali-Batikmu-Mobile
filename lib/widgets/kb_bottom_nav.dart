import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// ── Footer navigasi bawah: bar coklat tua bergelombang + tombol Kamera menonjol ──
// Urutan menu: 0 = Beranda, 1 = Kamera, 2 = Modul
// Bar menempel penuh ke tepi kiri, kanan, dan bawah layar (tanpa jarak).

const double _kNavHeight = 100; // tinggi bar + tombol kamera (belum termasuk area gesture bawah)
const double _kShoulderY = 26; // posisi atas "bahu" kiri & kanan bar
const double _kNotchY = 70; // dasar cekungan tempat tombol kamera
const double _kNotchHalf = 80; // setengah lebar cekungan (dari tengah)
const double _kCamSize = 64; // diameter tombol kamera

const Color _kBrown = Color(0xFF3E2418); // coklat tua (dasar bar & cincin tombol)
const Color _kBatik = Color(0xFF8A5A3C); // garis motif batik
const Color _kGold = Color(0xFFE8C98A); // emas (tombol, garis tepi, menu aktif)
const Color _kSoft = Color(0xFFD9C3A5); // krem lembut (menu tidak aktif)

// Garis tepi atas yang bergelombang (terbuka, dari kiri ke kanan)
Path _topEdge(Size size) {
  final w = size.width;
  final cx = w / 2;
  final l = cx - _kNotchHalf; // lebar bahu kiri (sama dengan kanan)
  const s = _kShoulderY;
  const a = _kNotchHalf;
  return Path()
    ..moveTo(0, s - 4)
    // gelombang bahu kiri
    ..cubicTo(l * .35, s - 12, l * .65, s + 8, l, s)
    // turun ke cekungan tengah
    ..cubicTo(cx - a * .62, s - 4, cx - a * .54, _kNotchY, cx, _kNotchY)
    // naik lagi ke bahu kanan
    ..cubicTo(cx + a * .54, _kNotchY, cx + a * .62, s - 4, cx + a, s)
    // gelombang bahu kanan
    ..cubicTo(w - l * .65, s + 8, w - l * .35, s - 12, w, s - 4);
}

// Bentuk tertutup bar: tepi atas bergelombang, sisi kiri/kanan/bawah lurus sampai ujung layar
Path _navPath(Size size) {
  final w = size.width;
  final h = size.height;
  return _topEdge(size)
    ..lineTo(w, h)
    ..lineTo(0, h)
    ..close();
}

class KbBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const KbBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Area gesture/tombol sistem di bawah layar: bar tetap digambar sampai dasar layar,
    // tetapi menu digeser naik supaya tidak tertutup.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _kNavHeight + bottomInset,
      width: double.infinity,
      child: CustomPaint(
        painter: _NavPainter(),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SideItem(
                  icon: Icons.home_outlined,
                  label: 'Beranda',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _CameraItem(
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              Expanded(
                child: _SideItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Modul',
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Menu di sisi kiri / kanan (ikon outline + label)
class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _kGold : _kSoft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          const SizedBox(height: 46),
          AnimatedScale(
            scale: selected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Tombol Kamera di tengah: lingkaran emas dengan cincin coklat tua, menonjol di atas bar
class _CameraItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CameraItem({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          const SizedBox(height: 2),
          AnimatedScale(
            scale: selected ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _kCamSize,
              height: _kCamSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGold,
                border: Border.all(color: _kBrown, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? _kGold.withValues(alpha: 0.55)
                        : Colors.black.withValues(alpha: 0.25),
                    blurRadius: selected ? 14 : 8,
                    offset: selected ? Offset.zero : const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 30,
                color: _kBrown,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kamera',
            style: AppTheme.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? _kGold : _kSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// Menggambar: bayangan, dasar coklat, motif kawung, lalu garis emas di tepi atas
class _NavPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _navPath(size);

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 6, false);

    canvas.save();
    canvas.clipPath(path);
    canvas.drawPaint(Paint()..color = _kBrown);
    _paintKawung(canvas, size);
    canvas.restore();

    canvas.drawPath(
      _topEdge(size),
      Paint()
        ..color = _kGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  // Motif kawung: empat kelopak lonjong bertemu di satu titik, diulang
  void _paintKawung(Canvas canvas, Size size) {
    const cell = 30.0;
    const q = cell / 4;
    final line = Paint()
      ..color = _kBatik.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint()..color = _kBatik.withValues(alpha: 0.55);

    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        final c = Offset(x, y);
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, -q), width: cell / 3, height: cell / 2),
          line,
        );
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, q), width: cell / 3, height: cell / 2),
          line,
        );
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(-q, 0), width: cell / 2, height: cell / 3),
          line,
        );
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(q, 0), width: cell / 2, height: cell / 3),
          line,
        );
        canvas.drawCircle(c, 1.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}