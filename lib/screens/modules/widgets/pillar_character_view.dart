import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_models.dart';

/// Halaman Pilar 2: Karakteristik, Struktur Visual, dan Pakem Anatomi Batik
class PillarCharacterView extends StatelessWidget {
  final ModuleModel module;
  final void Function(String imageUrl, String subtitle)? onZoomImage;
  final bool isDark;

  const PillarCharacterView({
    super.key,
    required this.module,
    this.onZoomImage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final content = module.content;
    if (content == null) return const Center(child: CircularProgressIndicator());
    final charData = content.karakteristik;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Karakteristik ${module.title}',
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold, height: 1.25),
          ),
          const SizedBox(height: 8),
          Text(
            charData.deskripsi,
            style: AppTheme.inter(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          _SectionLabel(label: 'Struktur & Ornamen Visual', isDark: isDark),
          const SizedBox(height: 10),

          _CharacteristicTile(
            data: charData.strukturUtama,
            isDark: isDark,
            onTapImage: onZoomImage,
          ),
          const SizedBox(height: 10),
          _CharacteristicTile(
            data: charData.ornamen,
            isDark: isDark,
            onTapImage: onZoomImage,
          ),
          const SizedBox(height: 10),
          _CharacteristicTile(
            data: charData.warna,
            isDark: isDark,
            accent: AppTheme.accentGold,
            onTapImage: onZoomImage,
          ),

          if (charData.pakemList.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionLabel(
              label: '${charData.pakemList.length} Pakem Anatomi Visual',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < charData.pakemList.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? AppTheme.darkBorder : AppTheme.border.withValues(alpha: 0.7),
                      ),
                    _PakemRow(
                      index: i + 1,
                      pakem: charData.pakemList[i],
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF5A3416),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _CharacteristicTile extends StatelessWidget {
  final KarakteristikDetailModel data;
  final bool isDark;
  final Color accent;
  final void Function(String imageUrl, String subtitle)? onTapImage;

  const _CharacteristicTile({
    required this.data,
    required this.isDark,
    this.accent = AppTheme.primary,
    this.onTapImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = data.image.isNotEmpty;
    final imageWidget = hasImage
        ? Image.asset(
            data.image,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _placeholder(),
          )
        : _placeholder();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: hasImage && onTapImage != null
                  ? () => onTapImage!(data.image, data.title)
                  : null,
              child: SizedBox(width: 96, height: 96, child: imageWidget),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.badge,
                        style: TextStyle(
                          color: accent == AppTheme.accentGold
                              ? AppTheme.primaryDark
                              : AppTheme.primary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.satoshi(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.inter(
                        fontSize: 11.5,
                        height: 1.4,
                        color: isDark ? Colors.white70 : AppTheme.textSecondary,
                      ),
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

  Widget _placeholder() {
    return Container(
      color: isDark ? AppTheme.darkBackground : const Color(0xFFF3EADF),
      child: Center(
        child: Icon(
          Icons.texture_rounded,
          size: 30,
          color: AppTheme.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _PakemRow extends StatelessWidget {
  final int index;
  final PakemModel pakem;
  final bool isDark;

  const _PakemRow({
    required this.index,
    required this.pakem,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pakem.title,
                  style: AppTheme.satoshi(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pakem.desc,
                  style: AppTheme.inter(
                    fontSize: 11.5,
                    height: 1.45,
                    color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
