import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_models.dart';

/// Halaman Pilar 3: Galeri Dokumentasi Visual Karya & Arsip Kain Tradisional
class PillarGalleryView extends StatelessWidget {
  final ModuleModel module;
  final VoidCallback onZoomImage;
  final bool isDark;

  const PillarGalleryView({
    super.key,
    required this.module,
    required this.onZoomImage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final content = module.content;
    if (content == null) return const Center(child: CircularProgressIndicator());
    final galeriList = content.galeri;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galeri ${module.title}',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Dokumentasi visual karya sentana dalem keraton dan pengrajin batik tulis.',
            style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),

          // Banner Hero Galeri
          GestureDetector(
            onTap: onZoomImage,
            child: Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF382516),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: galeriList.isNotEmpty && galeriList[0].imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(galeriList[0].imageUrl, fit: BoxFit.cover, color: Colors.black.withValues(alpha: 0.2), colorBlendMode: BlendMode.darken),
                          )
                        : const SizedBox(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library, size: 54, color: AppTheme.accentGold),
                        const SizedBox(height: 8),
                        Text('Arsip Kain Batik Tulis', style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Ketuk untuk perbesar detail', style: AppTheme.inter(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Grid Foto Dokumentasi Proses Membatik
          GridView.builder(
            itemCount: galeriList.length > 1 ? galeriList.length - 1 : 0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final galeri = galeriList[index + 1];
              return _buildGaleriItem(galeri.caption, galeri.imageUrl);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGaleriItem(String label, String imageUrl) {
    return GestureDetector(
      onTap: onZoomImage,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2B231D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(imageUrl, fit: BoxFit.cover, color: Colors.black.withValues(alpha: 0.3), colorBlendMode: BlendMode.darken),
                    )
                  : const Center(child: Icon(Icons.image, size: 38, color: Colors.white70)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
