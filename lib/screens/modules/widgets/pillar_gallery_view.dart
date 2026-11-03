import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_models.dart';

/// Halaman Pilar 3: Galeri Dokumentasi Visual Karya & Arsip Kain Tradisional
class PillarGalleryView extends StatelessWidget {
  final ModuleModel module;
  final void Function(String imageUrl, String subtitle) onZoomImage;
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
    final hero = galeriList.isNotEmpty ? galeriList.first : null;
    final others = galeriList.length > 1 ? galeriList.sublist(1) : <GaleriModel>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Galeri ${module.title}',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold, height: 1.25),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dokumentasi visual kain, detail motif, dan proses membatik.',
                  style: AppTheme.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${galeriList.length} Foto',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (hero != null)
            _GalleryTile(
              imageUrl: hero.imageUrl,
              caption: hero.caption,
              isDark: isDark,
              height: 200,
              onTap: () => onZoomImage(hero.imageUrl, hero.caption),
            ),

          if (others.isNotEmpty) ...[
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: others.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final galeri = others[index];
                return _GalleryTile(
                  imageUrl: galeri.imageUrl,
                  caption: galeri.caption,
                  isDark: isDark,
                  height: null,
                  onTap: () => onZoomImage(galeri.imageUrl, galeri.caption),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final String imageUrl;
  final String caption;
  final bool isDark;
  final double? height;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.imageUrl,
    required this.caption,
    required this.isDark,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : const Color(0xFF382516),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _placeholder(),
              )
            else
              _placeholder(),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.45, 0.68, 1.0],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 15),
              ),
            ),

            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.inter(
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: isDark ? AppTheme.darkSurface : const Color(0xFF382516),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: AppTheme.accentGold.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
