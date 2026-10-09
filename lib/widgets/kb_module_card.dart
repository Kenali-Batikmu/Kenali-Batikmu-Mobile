import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/app_models.dart';
import '../screens/modules/module_detail_screen.dart';

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
            _buildHeader(bodyColor, isDone, isWorking, progress),
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
  Widget _buildHeader(Color bodyColor, bool isDone, bool isWorking, num progress) {
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
                      'MODUL ${module.orderNo}/8',
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

  // Tombol aksi: emas bermotif (Lanjut / Mulai belajar) atau coklat bermotif (Buka kembali materi)
  Widget _buildActionButton(BuildContext context, bool isDone, bool isWorking) {
    final label = isWorking ? 'Lanjut belajar' : (isDone ? 'Buka kembali materi' : 'Mulai belajar');
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
  const _KawungPainter({required this.color, this.opacity = 1});

  static const double cell = 26;

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
      old.color != color || old.opacity != opacity;
}

// Tepi bawah header yang bergelombang, berwarna sama dengan badan kartu + garis emas tipis
class _WavePainter extends CustomPainter {
  final Color fill;

  const _WavePainter({required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.6);

    const int waves = 6;
    final waveWidth = size.width / waves;

    for (int i = 0; i < waves; i++) {
      final startX = i * waveWidth;
      path.quadraticBezierTo(
        startX + waveWidth * 0.25,
        size.height * 0.1, // puncak lengkungan naik
        startX + waveWidth * 0.5,
        size.height * 0.6, // tengah turun
      );
      path.quadraticBezierTo(
        startX + waveWidth * 0.75,
        size.height * 1.1, // lembah lengkungan turun
        startX + waveWidth,
        size.height * 0.6,
      );
    }
    path.lineTo(size.width, size.height);
    path.close();

    // Isi dengan warna latar
    canvas.drawPath(path, Paint()..color = fill);

    // Garis emas tipis di tepinya
    canvas.drawPath(
      path,
      Paint()
        ..color = _kGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.fill != fill;
}
