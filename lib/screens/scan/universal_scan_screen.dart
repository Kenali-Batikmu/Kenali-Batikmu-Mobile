import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import '../modules/module_detail_screen.dart';

class UniversalScanScreen extends StatefulWidget {
  const UniversalScanScreen({super.key});

  @override
  State<UniversalScanScreen> createState() => _UniversalScanScreenState();
}

class _UniversalScanScreenState extends State<UniversalScanScreen> {
  bool _isAnalyzing = false;
  bool _showResult = false;

  void _triggerScan() async {
    setState(() => _isAnalyzing = true);

    // Simulasi on-device inference TFLite MobileNetV2 (<= 2 detik sesuai PRD NFR-PERF-01)
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.addUniversalScanResult(motifName: 'Motif Parang Kusumo', confidence: 0.884);

    setState(() {
      _isAnalyzing = false;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return _buildScanResultView();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SCAN BATIKMU',
                    style: AppTheme.satoshi(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Camera Viewfinder Box
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1917),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder Reticle
                      Container(
                        margin: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6), width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.center_focus_strong,
                            size: 54,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Posisikan kain batik di dalam kotak',
                            style: AppTheme.satoshi(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AI On-Device mengenali 5 kelas motif nusantara',
                            style: AppTheme.inter(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined, size: 28, color: AppTheme.textPrimary),
                    onPressed: _triggerScan,
                  ),
                  GestureDetector(
                    onTap: _isAnalyzing ? null : _triggerScan,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isAnalyzing
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_off_outlined, size: 28, color: AppTheme.textPrimary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResultView() {
    // Sesuai PRD FR-SCAN-01: Sebaran probabilitas 5 kelas terurut menurun
    final probabilities = [
      {'name': 'Parang Kusumo', 'prob': 88.4, 'origin': 'Surakarta & Yogyakarta'},
      {'name': 'Kawung', 'prob': 6.2, 'origin': 'Yogyakarta'},
      {'name': 'Sekar Jagad', 'prob': 3.1, 'origin': 'Solo'},
      {'name': 'Truntum', 'prob': 1.5, 'origin': 'Surakarta'},
      {'name': 'Megamendung', 'prob': 0.8, 'origin': 'Cirebon'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Text('Hasil Deteksi Batikmu', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showResult = false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Ranked Motif Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'KEYAKINAN TERTINGGI (88.4%)',
                          style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      const Icon(Icons.verified, color: AppTheme.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Motif Parang Kusumo',
                    style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Asal Daerah: Surakarta & Yogyakarta (Keraton Mataram)',
                    style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Motif klasik lereng ombak laut selatan yang melambangkan keteguhan dan perjuangan tak pernah padam.',
                    style: AppTheme.inter(fontSize: 13, height: 1.5, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ModuleDetailScreen(
                            module: ModuleModel(
                              id: 1,
                              motifId: 1,
                              title: 'Modul 1: Seni & Filosofi Parang Kusumo',
                              description: 'Pelajari sejarah keraton dan karakteristik garis lereng.',
                              orderNo: 1,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_stories, size: 18),
                    label: const Text('Pelajari di Modul Lengkap'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Distribusi Probabilitas 5 Kelas
            Text(
              'Distribusi Probabilitas Kelas',
              style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...probabilities.map((item) {
              final prob = item['prob'] as double;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name'] as String,
                          style: AppTheme.satoshi(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$prob%',
                          style: AppTheme.satoshi(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: prob > 50 ? AppTheme.primary : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: prob / 100.0,
                        minHeight: 5,
                        backgroundColor: AppTheme.borderLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          prob > 50 ? AppTheme.primary : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () => setState(() => _showResult = false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Ambil Foto Kain Lain'),
            ),
          ],
        ),
      ),
    );
  }
}
