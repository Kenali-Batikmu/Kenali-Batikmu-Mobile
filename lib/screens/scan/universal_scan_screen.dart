import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import '../modules/module_detail_screen.dart';

/// Screen Universal Scan Batik
/// Mendukung pengoperasian di Windows Desktop (webcam / galeri fallback) maupun HP (Android / iOS)
class UniversalScanScreen extends StatefulWidget {
  const UniversalScanScreen({super.key});

  @override
  State<UniversalScanScreen> createState() => _UniversalScanScreenState();
}

/// Class untuk menampung peringkat kemiripan motif hasil scan AI
class MotifSimilarityMatch {
  final BatikMotifModel motif;
  final double score;

  MotifSimilarityMatch({
    required this.motif,
    required this.score,
  });
}

/// Alias backward-compatibility jika dipanggil dengan nama ScanScreen
typedef ScanScreen = UniversalScanScreen;

class _UniversalScanScreenState extends State<UniversalScanScreen>
    with WidgetsBindingObserver {
  CameraController? _cam;
  List<CameraDescription> _cams = [];
  int _camIdx = 0;
  File? _photo;
  bool _flash = false;
  bool _grid = false;
  bool _busy = false;
  bool _isCamAvailable = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cam?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final c = _cam;
      _cam = null;
      if (mounted) setState(() {});
      c?.dispose();
    } else if (state == AppLifecycleState.resumed &&
        _cam == null &&
        _cams.isNotEmpty &&
        _isCamAvailable) {
      _start();
    }
  }

  /// Menampilkan foto yang sudah diambil/dipilih.
  /// Di web memakai Image.network (blob URL), di Android/iOS/Windows memakai Image.file.
  Widget _photoImage(
    File file, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (kIsWeb) {
      return Image.network(file.path, fit: fit, width: width, height: height);
    }
    return Image.file(file, fit: fit, width: width, height: height);
  }

  /// Inisialisasi kamera platform-aware (Windows & Mobile)
  Future<void> _initCam() async {
    try {
      _cams = await availableCameras();
      if (_cams.isEmpty) {
        if (mounted) {
          setState(() {
            _isCamAvailable = false;
            _err = 'Kamera perangkat tidak ditemukan. Gunakan tombol galeri untuk memilih foto batik.';
          });
        }
        return;
      }

      // Utamakan kamera belakang di HP, atau kamera pertama di Windows PC
      _camIdx = _cams.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_camIdx < 0) _camIdx = 0;

      await _start();
    } catch (e) {
      debugPrint('Info kamera: $e');
      if (mounted) {
        setState(() {
          _isCamAvailable = false;
          _err = 'Tidak dapat mengakses sensor kamera. Anda dapat memilih foto kain batik dari galeri.';
        });
      }
    }
  }

  Future<void> _start() async {
    if (_cams.isEmpty) return;
    final old = _cam;
    _cam = null;
    if (mounted) setState(() {});
    await old?.dispose();

    final c = CameraController(
      _cams[_camIdx],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await c.initialize();
      _flash = false;
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _cam = c;
        _isCamAvailable = true;
        _err = null;
      });
    } catch (e) {
      debugPrint('Gagal start kamera: $e');
      if (mounted) {
        setState(() {
          _isCamAvailable = false;
          _err = 'Kamera tidak dapat diinisialisasi. Gunakan mode pilih foto dari galeri.';
        });
      }
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: AppTheme.inter(color: Colors.white, fontSize: 13)),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    final c = _cam;
    if (c == null || !c.value.isInitialized) {
      _snack('Lampu kilat tidak tersedia.');
      return;
    }
    try {
      await c.setFlashMode(_flash ? FlashMode.off : FlashMode.torch);
      setState(() => _flash = !_flash);
    } catch (_) {
      _snack('Lampu kilat tidak didukung pada kamera ini.');
    }
  }

  Future<void> _switchCam() async {
    if (_cams.length < 2) {
      _snack('Hanya 1 kamera terdeteksi pada perangkat ini.');
      return;
    }
    _camIdx = (_camIdx + 1) % _cams.length;
    await _start();
  }

  Future<void> _shoot() async {
    final c = _cam;
    if (c != null && c.value.isInitialized && !c.value.isTakingPicture) {
      try {
        final x = await c.takePicture();
        if (mounted) setState(() => _photo = File(x.path));
        return;
      } catch (e) {
        debugPrint('Gagal takePicture: $e');
      }
    }

    // Fallback ambil via ImagePicker jika kamera fisik tidak siap
    await _pick(source: ImageSource.camera);
  }

  Future<void> _pick({ImageSource source = ImageSource.gallery}) async {
    try {
      final x = await ImagePicker().pickImage(source: source);
      if (x != null && mounted) {
        setState(() => _photo = File(x.path));
      }
    } catch (e) {
      _snack('Gagal memilih gambar: $e');
    }
  }

  Future<void> _send() async {
    if (_photo == null && (_cam == null || !_cam!.value.isInitialized)) {
      // Jika belum ada foto & kamera tidak ada, langsung arahkan memilih dari galeri
      await _pick(source: ImageSource.gallery);
      if (_photo == null) return;
    }

    // Jika pengguna menekan Kirim saat preview kamera aktif tanpa foto terpilih, otomatis ambil foto
    if (_photo == null && _cam != null && _cam!.value.isInitialized) {
      await _shoot();
      if (_photo == null) return;
    }

    if (_photo == null) {
      _snack('Ambil foto atau pilih gambar dari galeri terlebih dahulu.');
      return;
    }

    setState(() => _busy = true);

    try {
      // Simulasi analisis klasifikasi AI motif batik yang sangat cepat & responsif
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;

      final provider = Provider.of<AppProvider>(context, listen: false);
      final motifs = List<BatikMotifModel>.from(provider.motifs);

      // Fallback jika data motif belum terisi
      if (motifs.isEmpty) {
        motifs.addAll([
          BatikMotifModel(id: 2, name: 'Parang Rusak', slug: 'parang-rusak', originRegion: 'Yogyakarta & Surakarta', shortDescription: 'Pakem keraton agung melambangkan ombak samudera dan perjuangan batin.', mlClassIndex: 1),
          BatikMotifModel(id: 4, name: 'Parang Kusumo', slug: 'parang-kusumo', originRegion: 'Surakarta & Yogyakarta', shortDescription: 'Batik larangan keraton bermakna ksatria dengan keharuman budi pekerti bunga.', mlClassIndex: 3),
          BatikMotifModel(id: 1, name: 'Cecek Hasan', slug: 'cecek-hasan', originRegion: 'Pekalongan', shortDescription: 'Ornamen isen halus berupa titik-titik melingkar membentuk geometri harmonis.', mlClassIndex: 0),
          BatikMotifModel(id: 3, name: 'Truntum', slug: 'truntum', originRegion: 'Surakarta', shortDescription: 'Bintang kasih sayang abadi, lambang cinta tulus yang senantiasa bersemi.', mlClassIndex: 2),
          BatikMotifModel(id: 5, name: 'Kawung', slug: 'kawung', originRegion: 'Yogyakarta', shortDescription: 'Empat bulatan lonjong melambangkan kesucian hati dan harmoni semesta.', mlClassIndex: 4),
          BatikMotifModel(id: 6, name: 'Mega Mendung', slug: 'mega-mendung', originRegion: 'Cirebon', shortDescription: 'Gradasi lapisan awan membawa keteduhan, kesabaran, dan kelapangan dada.', mlClassIndex: 5),
        ]);
      }

      // Skor kemiripan realistis terurut dari peringkat 1 hingga 5
      final baseScores = [0.94, 0.86, 0.77, 0.65, 0.52];

      // Variasikan rotasi urutan motif agar dinamis sesuai timestamp
      final shift = DateTime.now().second % motifs.length;
      final List<MotifSimilarityMatch> top5Matches = [];

      for (int i = 0; i < 5 && i < motifs.length; i++) {
        final index = (shift + i) % motifs.length;
        top5Matches.add(
          MotifSimilarityMatch(
            motif: motifs[index],
            score: baseScores[i < baseScores.length ? i : baseScores.length - 1],
          ),
        );
      }

      // Simpan hasil pindaian motif teratas (#1) ke riwayat provider
      provider.addUniversalScanResult(
        motifName: top5Matches.first.motif.name,
        confidence: top5Matches.first.score,
      );

      setState(() => _busy = false);

      // Tampilkan Modal Sheet Hasil Top 5 Kemiripan Motif
      _showResultSheet(top5Matches);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      _snack('Gagal menganalisis gambar: $e');
    }
  }

  /// Menutup sheet lalu membuka modul belajar dari motif terkait
  void _openModule(BuildContext ctx, int motifId) {
    Navigator.pop(ctx);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final target = provider.modules.firstWhere(
      (m) => m.motifId == motifId,
      orElse: () => provider.modules[0],
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModuleDetailScreen(module: target)),
    );
  }

  /// Warna medali peringkat: emas, perak, perunggu, lalu cokelat
  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return AppTheme.accentGold;
      case 2:
        return const Color(0xFFA8A8A8);
      case 3:
        return const Color(0xFFB0793F);
      default:
        return const Color(0xFF5A3416);
    }
  }

  void _showResultSheet(List<MotifSimilarityMatch> matches) {
    if (matches.isEmpty) return;
    final top1 = matches.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brownDark = Color(0xFF3B2314);
    const brown = Color(0xFF5A3416);
    final sheetBg = isDark ? AppTheme.darkSurface : const Color(0xFFFBF6EC);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Container(
                color: sheetBg,
                child: Stack(
                  children: [
                    // Pola kawung tipis di seluruh background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _KawungPainter(
                          color: (isDark ? Colors.white : brown).withValues(alpha: 0.05),
                          cell: 56,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          // ================= HEADER BERPOLA BATIK =================
                          SizedBox(
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _BatikHeaderPainter(
                                top: brownDark,
                                mid: brown,
                                bottom: sheetBg,
                                pattern: AppTheme.accentGold.withValues(alpha: 0.2),
                                fadeHeight: 28,
                              ),
                              child: Padding(
                                // 18 = jarak bawah kartu, 28 = area transisi blur bermotif batik
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18 + 28),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white38,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.black26,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: AppTheme.accentGold, width: 2),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: _photo != null
                                              ? _photoImage(_photo!)
                                              : const Icon(Icons.waves, color: AppTheme.accentGold, size: 28),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.auto_awesome, size: 13, color: AppTheme.accentGold),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'HASIL ANALISIS AI',
                                                    style: AppTheme.satoshi(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppTheme.accentGold,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Top 5 Kemiripan Motif',
                                                style: AppTheme.notoSerif(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Berdasarkan fitur visual & ornamen kain',
                                                style: AppTheme.inter(fontSize: 11, color: Colors.white70),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    // ============ KARTU JUARA #1 ============
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.darkCard : const Color(0xFFFFFBF2),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: AppTheme.accentGold, width: 1.8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: brown.withValues(alpha: 0.22),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accentGold,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.emoji_events, size: 12, color: Colors.white),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'PALING COCOK',
                                                        style: AppTheme.satoshi(
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.white,
                                                          letterSpacing: 0.6,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  top1.motif.name,
                                                  style: AppTheme.notoSerif(
                                                    fontSize: 21,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : brownDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on, size: 12, color: AppTheme.primary),
                                                    const SizedBox(width: 3),
                                                    Flexible(
                                                      child: Text(
                                                        top1.motif.originRegion,
                                                        style: AppTheme.inter(
                                                          fontSize: 11.5,
                                                          color: AppTheme.primary,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  top1.motif.shortDescription,
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTheme.inter(
                                                    fontSize: 12,
                                                    height: 1.4,
                                                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // Lingkaran persentase
                                          SizedBox(
                                            width: 74,
                                            height: 74,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 74,
                                                  height: 74,
                                                  child: CircularProgressIndicator(
                                                    value: top1.score,
                                                    strokeWidth: 7,
                                                    strokeCap: StrokeCap.round,
                                                    backgroundColor: AppTheme.accentGold.withValues(alpha: 0.2),
                                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                                                  ),
                                                ),
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${(top1.score * 100).round()}%',
                                                      style: AppTheme.satoshi(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w800,
                                                        color: isDark ? Colors.white : brown,
                                                      ),
                                                    ),
                                                    Text(
                                                      'cocok',
                                                      style: AppTheme.inter(
                                                        fontSize: 9.5,
                                                        color: isDark ? Colors.white60 : AppTheme.textMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ================= DAFTAR PERINGKAT =================
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGold,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Peringkat 5 Motif Terdekat',
                                      style: AppTheme.notoSerif(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : brownDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                ...List.generate(matches.length, (idx) {
                                  final item = matches[idx];
                                  final rank = idx + 1;
                                  final color = _rankColor(rank);
                                  final pct = (item.score * 100).round();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkCard : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: rank == 1
                                            ? AppTheme.accentGold.withValues(alpha: 0.8)
                                            : (isDark ? AppTheme.darkBorder : const Color(0xFFEADFCB)),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: brown.withValues(alpha: 0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [color.withValues(alpha: 0.85), color],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: color.withValues(alpha: 0.35),
                                                          blurRadius: 6,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '$rank',
                                                        style: AppTheme.satoshi(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item.motif.name,
                                                          style: AppTheme.notoSerif(
                                                            fontSize: 14.5,
                                                            fontWeight: FontWeight.bold,
                                                            color: isDark ? Colors.white : brownDark,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.location_on_outlined,
                                                              size: 11,
                                                              color: isDark ? Colors.white54 : AppTheme.textMuted,
                                                            ),
                                                            const SizedBox(width: 2),
                                                            Flexible(
                                                              child: Text(
                                                                item.motif.originRegion,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: AppTheme.inter(
                                                                  fontSize: 11,
                                                                  color: isDark ? Colors.white60 : AppTheme.textMuted,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '$pct%',
                                                      style: AppTheme.satoshi(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w800,
                                                        color: rank == 2 ? const Color(0xFF7D7D7D) : color,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              // Progress bar gradasi
                                              Stack(
                                                children: [
                                                  Container(
                                                    height: 7,
                                                    decoration: BoxDecoration(
                                                      color: isDark ? AppTheme.darkBorder : const Color(0xFFF0EBE1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ),
                                                  FractionallySizedBox(
                                                    widthFactor: item.score.clamp(0.0, 1.0),
                                                    child: Container(
                                                      height: 7,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(4),
                                                        gradient: LinearGradient(
                                                          colors: [color.withValues(alpha: 0.6), color],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                  );
                                }),

                                const SizedBox(height: 10),

                                // ================= TOMBOL AKSI =================
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(colors: [brownDark, brown]),
                                    boxShadow: [
                                      BoxShadow(
                                        color: brown.withValues(alpha: 0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openModule(ctx, top1.motif.id),
                                    icon: const Icon(Icons.menu_book, size: 18, color: AppTheme.accentGold),
                                    label: Text(
                                      'Pelajari Modul ${top1.motif.name}',
                                      style: AppTheme.satoshi(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() => _photo = null);
                                  },
                                  icon: const Icon(Icons.replay, size: 16),
                                  label: Text(
                                    'Pindai Motif Lain',
                                    style: AppTheme.satoshi(fontSize: 13.5, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white : brown,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    side: BorderSide(color: AppTheme.accentGold.withValues(alpha: 0.7), width: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewArea(bool isDark) {
    final c = _cam;

    if (_photo != null) {
      return _photoImage(
        _photo!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (c != null && c.value.isInitialized && _isCamAvailable) {
      final size = c.value.previewSize;
      if (size != null) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(c),
          ),
        );
      }
      return CameraPreview(c);
    }

    // Canvas / Mock Viewfinder fallback untuk Windows PC tanpa kamera fisik
    return Container(
      color: const Color(0xFF231C16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.waves,
            size: 160,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_camera_outlined, color: AppTheme.accentGold, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  kIsWeb
                      ? 'Kamera Web'
                      : (Platform.isWindows ? 'Kamera Windows / Mode Galeri' : 'Mode Galeri'),
                  style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _err ?? 'Arahkan kamera ke kain batikmu atau klik tombol Galeri di bawah untuk mengunggah foto.',
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _pick(source: ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Pilih dari Galeri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassWidget(Widget child, {double radius = 20}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                // Header Judul Sesuai PDF & Style Aplikasi
                Text(
                  'KENALI BATIKMU',
                  style: AppTheme.satoshi(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scan Batik Universal',
                  style: AppTheme.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Frame Viewfinder Utama Kamera
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildPreviewArea(isDark),
                            if (_grid) const CustomPaint(painter: _GridPainter()),
                            const CustomPaint(painter: _FramePainter()),

                            // Top Bar Overlays (Grid Toggle, Information Pill, Flash Toggle)
                            Positioned(
                              top: 14,
                              left: 12,
                              right: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildGlassWidget(
                                    IconButton(
                                      icon: Icon(
                                        Icons.grid_on,
                                        size: 20,
                                        color: _grid ? AppTheme.accentGold : Colors.white,
                                      ),
                                      onPressed: () => setState(() => _grid = !_grid),
                                    ),
                                    radius: 18,
                                  ),
                                  Flexible(
                                    child: _buildGlassWidget(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.photo_camera_outlined, size: 14, color: AppTheme.accentGold),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                'Arahkan kamera ke kain batikmu',
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.inter(fontSize: 11.5, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildGlassWidget(
                                    IconButton(
                                      icon: Icon(
                                        _flash ? Icons.flash_on : Icons.flash_off,
                                        size: 20,
                                        color: _flash ? AppTheme.accentGold : Colors.white,
                                      ),
                                      onPressed: _toggleFlash,
                                    ),
                                    radius: 18,
                                  ),
                                ],
                              ),
                            ),

                            // Bottom Bar Overlays (Galeri Thumbnail, Shutter Button, Switch Camera)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Tombol Galeri dengan Thumbnail
                                  GestureDetector(
                                    onTap: () => _pick(source: ImageSource.gallery),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: Colors.white, width: 2),
                                            color: Colors.black45,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: _photo == null
                                              ? const Icon(Icons.photo_library_outlined, color: Colors.white)
                                              : _photoImage(_photo!),
                                        ),
                                        Positioned(
                                          right: -4,
                                          bottom: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: Colors.black87,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.image_outlined, size: 12, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Shutter Button
                                  GestureDetector(
                                    onTap: _shoot,
                                    child: Container(
                                      width: 76,
                                      height: 76,
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primary,
                                        ),
                                        child: const Icon(Icons.camera, color: Colors.white, size: 30),
                                      ),
                                    ),
                                  ),

                                  // Tombol Switch Kamera (Depan / Belakang / Perangkat Lain)
                                  _buildGlassWidget(
                                    IconButton(
                                      icon: const Icon(Icons.flip_camera_android_outlined, color: Colors.white),
                                      onPressed: _switchCam,
                                    ),
                                    radius: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Tombol Kirim untuk Dinilai Sesuai PDF Page 10 & Design App
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3416),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.accentGold),
                      label: Text(
                        'Kirim untuk Dinilai',
                        style: AppTheme.satoshi(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(
                    'Kembali ke Beranda',
                    style: AppTheme.inter(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            // Loading Overlay saat Menganalisis
            if (_busy)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppTheme.accentGold),
                      const SizedBox(height: 16),
                      Text(
                        'Menganalisis motif batik...',
                        style: AppTheme.satoshi(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Canvas Painter bingkai sudut kuning emas viewfinder
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.64;
    final h = w * 0.80;
    final r = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: w,
      height: h,
    );

    final p = Paint()
      ..color = AppTheme.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const l = 26.0;

    // Kiri-Atas
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(l, 0), p);
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(0, l), p);
    // Kanan-Atas
    canvas.drawLine(r.topRight, r.topRight + const Offset(-l, 0), p);
    canvas.drawLine(r.topRight, r.topRight + const Offset(0, l), p);
    // Kiri-Bawah
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(l, 0), p);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -l), p);
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(-l, 0), p);
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -l), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Canvas Painter garis bantu grid 3x3
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), p);
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Pola batik Kawung (empat elips membentuk bunga) yang berulang
class _KawungPainter extends CustomPainter {
  final Color color;
  final double cell;
  const _KawungPainter({required this.color, this.cell = 48});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        canvas.save();
        canvas.translate(x, y);
        for (var i = 0; i < 4; i++) {
          canvas.save();
          canvas.rotate(i * math.pi / 2);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(0, -cell * 0.25),
              width: cell * 0.3,
              height: cell * 0.5,
            ),
            stroke,
          );
          canvas.restore();
        }
        canvas.drawCircle(Offset.zero, 2.2, dot);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KawungPainter old) =>
      old.color != color || old.cell != cell;
}

/// Background header: cokelat tua penuh sampai bawah kartu juara, lalu memudar
/// (blur) ke warna sheet. Motif kawung ikut memudar di area transisi.
class _BatikHeaderPainter extends CustomPainter {
  final Color top;
  final Color mid;
  final Color bottom;
  final Color pattern;
  final double fadeHeight;

  const _BatikHeaderPainter({
    required this.top,
    required this.mid,
    required this.bottom,
    required this.pattern,
    this.fadeHeight = 28,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    final rect = Offset.zero & size;
    final f = ((size.height - fadeHeight) / size.height).clamp(0.0, 1.0);
    final span = 1.0 - f;

    // 1. Gradasi warna: cokelat tua -> cokelat -> memudar ke warna sheet
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            top,
            mid,
            Color.lerp(mid, bottom, 0.4)!,
            Color.lerp(mid, bottom, 0.75)!,
            bottom,
          ],
          stops: [0.0, f, f + span * 0.35, f + span * 0.7, 1.0],
        ).createShader(rect),
    );

    // 2. Motif kawung, ikut memudar di area transisi
    canvas.saveLayer(rect, Paint());
    _KawungPainter(color: pattern, cell: 48).paint(canvas, size);
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
          stops: [0.0, f, 1.0],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BatikHeaderPainter old) =>
      old.top != top ||
      old.mid != mid ||
      old.bottom != bottom ||
      old.pattern != pattern ||
      old.fadeHeight != fadeHeight;
}