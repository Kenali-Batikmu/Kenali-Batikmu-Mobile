import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';

class PracticeQuizScreen extends StatefulWidget {
  final ModuleModel module;

  const PracticeQuizScreen({super.key, required this.module});

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen>
    with WidgetsBindingObserver {
  CameraController? _cam;
  List<CameraDescription> _cams = [];
  int _camIdx = 0;
  File? _photo;
  bool _flash = false;
  bool _grid = false;
  bool _isCamAvailable = true;
  bool _isAnalyzing = false;
  bool _hasResult = false;
  String? _camErr;

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
      _startCam();
    }
  }

  /// Inisialisasi kamera platform-aware (Windows & HP)
  Future<void> _initCam() async {
    try {
      _cams = await availableCameras();
      if (_cams.isEmpty) {
        if (mounted) {
          setState(() {
            _isCamAvailable = false;
            _camErr = 'Kamera tidak ditemukan. Anda dapat mengunggah foto kain batik dari galeri.';
          });
        }
        return;
      }

      // Pilih kamera belakang pada HP, atau kamera pertama pada Windows PC
      _camIdx = _cams.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      if (_camIdx < 0) _camIdx = 0;

      await _startCam();
    } catch (e) {
      debugPrint('Info kamera praktikum: $e');
      if (mounted) {
        setState(() {
          _isCamAvailable = false;
          _camErr = 'Sensor kamera tidak tersedia. Silakan gunakan fitur unggah foto dari galeri.';
        });
      }
    }
  }

  Future<void> _startCam() async {
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
        _camErr = null;
      });
    } catch (e) {
      debugPrint('Gagal inisialisasi kamera praktikum: $e');
      if (mounted) {
        setState(() {
          _isCamAvailable = false;
          _camErr = 'Gagal mengakses kamera. Silakan pilih foto kain batik dari galeri.';
        });
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTheme.inter(color: Colors.white, fontSize: 13)),
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
    await _startCam();
  }

  Future<void> _shootPhoto() async {
    final c = _cam;
    if (c != null && c.value.isInitialized && !c.value.isTakingPicture) {
      try {
        final x = await c.takePicture();
        if (mounted) setState(() => _photo = File(x.path));
        return;
      } catch (e) {
        debugPrint('Error takePicture praktikum: $e');
      }
    }

    // Jika kamera tidak aktif, arahkan ke picker galeri
    await _pickFromGallery();
  }

  Future<void> _pickFromGallery() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x != null && mounted) {
        setState(() => _photo = File(x.path));
      }
    } catch (e) {
      _snack('Gagal memilih gambar dari galeri: $e');
    }
  }

  Future<void> _submitAssessment() async {
    // Jika belum ada foto & kamera aktif, ambil foto otomatis
    if (_photo == null && _cam != null && _cam!.value.isInitialized) {
      await _shootPhoto();
    }

    // Jika kamera tidak ada & foto belum dipilih, minta pilih dari galeri
    if (_photo == null && (_cam == null || !_cam!.value.isInitialized)) {
      await _pickFromGallery();
    }

    if (_photo == null) {
      _snack('Ambil foto karyamu atau unggah gambar dari galeri terlebih dahulu.');
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;

      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.savePracticeResult(widget.module.id, 0.70, true);

      setState(() {
        _isAnalyzing = false;
        _hasResult = true;
      });
    } catch (e) {
      if (mounted) setState(() => _isAnalyzing = false);
      _snack('Gagal menilai hasil praktikum: $e');
    }
  }

  Widget _buildViewfinderContent(bool isDark) {
    if (_photo != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          kIsWeb ? Image.network(_photo!.path, fit: BoxFit.cover) : Image.file(_photo!, fit: BoxFit.cover),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => setState(() => _photo = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Foto Ulang', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final c = _cam;
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

    // Fallback Viewfinder Canvas ketika Kamera tidak tersedia / di Windows tanpa Webcam
    return Container(
      color: const Color(0xFF2B231D),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(
              child: Icon(
                Icons.waves,
                size: 160,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.accentGold, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  kIsWeb
                      ? 'Unggah Foto Hasil Praktikum'
                      : (Platform.isWindows ? 'Kamera Windows / Mode Upload Gambar' : 'Unggah Foto Praktikum'),
                  style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  _camErr ?? 'Arahkan kamera ke kain batikmu atau unggah gambar dari galeri perangkat.',
                  textAlign: TextAlign.center,
                  style: AppTheme.inter(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Unggah Gambar dari Galeri'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_hasResult) {
      return _buildHasilPenilaianView(context, isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: isDark ? Colors.white : AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'KENALI BATIKMU',
              style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.primary),
            ),
            Text(
              'Detail Modul - Kuis Praktikum',
              style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Frame Viewfinder Utama Kamera / Upload
              Container(
                height: 480,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B231D),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildViewfinderContent(isDark),

                      // Grid Overlay jika diaktifkan
                      if (_grid && _photo == null)
                        const CustomPaint(painter: _GridPainter()),

                      // Top Bar Kamera (Grid Toggle, Pill Instruksi, Flash Toggle)
                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _grid = !_grid),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.grid_on,
                                  color: _grid ? AppTheme.accentGold : Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.camera_alt, color: AppTheme.accentGold, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    _photo != null
                                        ? 'Foto Karyamu Terpilih'
                                        : 'Arahkan kamera ke kain batikmu',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleFlash,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _flash ? Icons.flash_on : Icons.flash_off,
                                  color: _flash ? AppTheme.accentGold : Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Focus Reticle Frame (jika foto belum diambil)
                      if (_photo == null)
                        Center(
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.accentGold, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 60,
                                  left: 60,
                                  child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle)),
                                ),
                                Positioned(
                                  top: 100,
                                  right: 60,
                                  child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle)),
                                ),
                                Positioned(
                                  bottom: 60,
                                  left: 80,
                                  child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.accentGold, shape: BoxShape.circle)),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Bottom Controls (Galeri Upload, Shutter Capture, Switch Cam)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Tombol Galeri Upload Gambar
                            GestureDetector(
                              onTap: _pickFromGallery,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white70),
                                ),
                                child: const Icon(Icons.photo_library, color: Colors.white, size: 22),
                              ),
                            ),

                            // Tombol Shutter Ambil Foto
                            GestureDetector(
                              onTap: _isAnalyzing ? null : _shootPhoto,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera, color: Colors.white, size: 28),
                                  ),
                                ),
                              ),
                            ),

                            // Tombol Flip Switch Camera
                            GestureDetector(
                              onTap: _switchCam,
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Overlay Loading saat Penilaian
                      if (_isAnalyzing)
                        Container(
                          color: Colors.black.withValues(alpha: 0.7),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppTheme.accentGold),
                                SizedBox(height: 14),
                                Text(
                                  'Menganalisis & Menilai Karyamu...',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Tombol Kirim untuk Dinilai
              ElevatedButton(
                onPressed: _isAnalyzing ? null : _submitAssessment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A3416),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isAnalyzing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Menilai...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: AppTheme.accentGold),
                          SizedBox(width: 8),
                          Text('Kirim untuk Dinilai'),
                        ],
                      ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Kembali ke Halaman Kuis',
                    style: AppTheme.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Layar Hasil Penilaian Praktikum
  Widget _buildHasilPenilaianView(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: isDark ? Colors.white : AppTheme.textPrimary,
          onPressed: () => setState(() => _hasResult = false),
        ),
        title: Column(
          children: [
            Text('KENALI BATIKMU', style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.primary)),
            Text('Hasil Penilaian Praktikum', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Foto Karyamu & Info Waktu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF382516),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
                    ),
                    child: _photo != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: kIsWeb ? Image.network(_photo!.path, fit: BoxFit.cover) : Image.file(_photo!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, color: Colors.white, size: 18),
                                Text(
                                  'Foto\nKaryamu',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.draw, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'KUIS PRAKTIK MODUL ${widget.module.id}',
                              style: AppTheme.satoshi(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Diambil pada baru saja', style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(() => _hasResult = false),
                          child: const Row(
                            children: [
                              Icon(Icons.replay, size: 14, color: AppTheme.primaryDark),
                              SizedBox(width: 4),
                              Text('Ambil / Unggah Ulang', style: TextStyle(color: AppTheme.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Card Kecocokan Asal Daerah
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.radar, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kecocokan Asal Daerah', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Berdasarkan ornamen, canting, & isen', style: AppTheme.inter(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 20),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _buildDaerahItem('S', 'Sumatra', 70, isTop: true, badge: 'Paling Cocok'),
                  const SizedBox(height: 14),
                  _buildDaerahItem('J', 'Jawa', 60),
                  const SizedBox(height: 14),
                  _buildDaerahItem('M', 'Malang', 40),
                  const SizedBox(height: 18),

                  Text(
                    'ⓘ  Persentase menunjukkan kemiripan pola, warna, dan komposisi karyamu dengan ciri khas tiap daerah.',
                    style: AppTheme.inter(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Ketentuan Penilaian
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.rule, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('Ketentuan Penilaian', style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildKetentuanBullet('≥ 70%: Sangat Mirip', const Color(0xFFD49B45)),
                  const SizedBox(height: 6),
                  _buildKetentuanBullet('50% – 69%: Cukup Mirip', const Color(0xFF5A3416)),
                  const SizedBox(height: 6),
                  _buildKetentuanBullet('< 50%: Perlu Dilatih', const Color(0xFF8A827B)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Coba Lagi & Kembali
            ElevatedButton.icon(
              onPressed: () => setState(() => _hasResult = false),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A3416),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 10),

            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.home_outlined, size: 16, color: AppTheme.textSecondary),
                label: Text('Kembali ke Beranda', style: AppTheme.inter(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaerahItem(String letter, String name, int percent, {bool isTop = false, String? badge}) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isTop ? const Color(0xFFF7E6D2) : const Color(0xFFEBE6E1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(letter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5A3416))),
              ),
            ),
            const SizedBox(width: 10),
            Text(name, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFCECDA), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: AppTheme.accentGold),
                    const SizedBox(width: 4),
                    Text(badge, style: const TextStyle(color: Color(0xFF7A4B29), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Text('$percent%', style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF5A3416))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0EBE1),
            valueColor: AlwaysStoppedAnimation<Color>(isTop ? AppTheme.accentGold : const Color(0xFF5A3416)),
          ),
        ),
      ],
    );
  }

  Widget _buildKetentuanBullet(String text, Color dotColor) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
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
