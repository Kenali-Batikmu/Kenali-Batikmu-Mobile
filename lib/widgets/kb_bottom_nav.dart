import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// ── Footer navigasi bawah: bar coklat bergelombang (Beranda / Kamera / Koleksi) ──
const double _kNavHeight = 76; // tinggi total bar
const double _kNavDrop = 14; // turunnya "bahu" kiri & kanan dari bagian tengah yang menonjol

Path _navPath(Size size) {
  final w = size.width;
  final h = size.height;
  const d = _kNavDrop;
  const r = 22.0; // lengkung sudut bawah
  const c = 10.0; // lengkung sudut atas bahu
  return Path()
    ..moveTo(0, d + c)
    ..quadraticBezierTo(0, d, c, d)
    ..lineTo(w * 0.13, d)
    ..cubicTo(w * 0.21, d, w * 0.19, 0, w * 0.27, 0)
    ..lineTo(w * 0.73, 0)
    ..cubicTo(w * 0.81, 0, w * 0.79, d, w * 0.87, d)
    ..lineTo(w - c, d)
    ..quadraticBezierTo(w, d, w, d + c)
    ..lineTo(w, h - r)
    ..quadraticBezierTo(w, h, w - r, h)
    ..lineTo(r, h)
    ..quadraticBezierTo(0, h, 0, h - r)
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

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.photo_camera_outlined,
    Icons.menu_book_outlined,
  ];
  static const List<String> _labels = ['Beranda', 'Kamera', 'Koleksi'];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 6, left: 6, right: 6),
      child: SizedBox(
        height: _kNavHeight,
        child: CustomPaint(
          painter: _NavShadowPainter(),
          child: ClipPath(
            clipper: _NavClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF7A3C17), Color(0xFF4D240E)],
                ),
              ),
              child: Stack(
                children: [
                  // Ornamen ranting daun emas di pojok kiri & kanan bawah
                  const Positioned(
                    left: 0,
                    bottom: 0,
                    width: 90,
                    height: 56,
                    child: CustomPaint(painter: _SprigPainter(mirrored: false)),
                  ),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    width: 90,
                    height: 56,
                    child: CustomPaint(painter: _SprigPainter(mirrored: true)),
                  ),

                  // Garis pemisah tipis antar menu
                  Positioned.fill(
                    child: Align(
                      alignment: const Alignment(-0.2, 0.25),
                      child: Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.07)),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: const Alignment(0.2, 0.25),
                      child: Container(width: 1, height: 44, color: Colors.white.withValues(alpha: 0.07)),
                    ),
                  ),

                  // Menu (di tengah: pusat di 30%, 50%, 70% lebar bar)
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(flex: 20),
                        ...List.generate(_icons.length, (i) {
                          return Expanded(
                            flex: 20,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: _NavItem(
                                icon: _icons[i],
                                label: _labels[i],
                                selected: i == currentIndex,
                                onTap: () => onTap(i),
                              ),
                            ),
                          );
                        }),
                        const Spacer(flex: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFBF3E3) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? const Color(0xFFFBF3E3) : const Color(0xFFB8733A).withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected ? const Color(0xFF6B3516) : Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTheme.inter(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Memotong bar sesuai bentuk (tengah menonjol, bahu kiri-kanan lebih rendah, sudut bawah membulat)
class _NavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _navPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Bayangan lembut di sekeliling bentuk bar
class _NavShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(_navPath(size), Colors.black.withValues(alpha: 0.35), 6, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Ranting daun emas sebagai ornamen di pojok bawah bar
class _SprigPainter extends CustomPainter {
  final bool mirrored;
  const _SprigPainter({required this.mirrored});

  @override
  void paint(Canvas canvas, Size size) {
    if (mirrored) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final w = size.width;
    final h = size.height;

    // Titik pada batang (kurva kuadratik) untuk t antara 0..1
    final p0 = Offset(w * 0.80, h);
    final p1 = Offset(w * 0.55, h * 0.40);
    final p2 = Offset(w * 0.12, h * 0.02);
    Offset pointAt(double t) {
      final u = 1 - t;
      return Offset(
        u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
        u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
      );
    }

    final stemPaint = Paint()
      ..color = const Color(0xFFD39A55).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy),
      stemPaint,
    );

    final leafPaint = Paint()..color = const Color(0xFFD9A05B).withValues(alpha: 0.75);
    void drawLeaf(Offset c, double angle, double len, double wid) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      final leaf = Path()
        ..moveTo(-len / 2, 0)
        ..quadraticBezierTo(0, -wid, len / 2, 0)
        ..quadraticBezierTo(0, wid, -len / 2, 0)
        ..close();
      canvas.drawPath(leaf, leafPaint);
      canvas.restore();
    }

    drawLeaf(pointAt(0.55) + const Offset(10, -2), -0.30, 24, 7);
    drawLeaf(pointAt(0.30) + const Offset(8, 2), -0.20, 18, 5.5);
    drawLeaf(pointAt(0.80) + const Offset(-7, 0), -2.90, 14, 4.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
