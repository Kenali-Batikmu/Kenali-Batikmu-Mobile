import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_models.dart';

/// Halaman Pilar 2: Karakteristik, Struktur Visual, dan Pakem Anatomi Batik
class PillarCharacterView extends StatelessWidget {
  final ModuleModel module;
  final bool isDark;

  const PillarCharacterView({
    super.key,
    required this.module,
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
            style: AppTheme.satoshi(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            charData.deskripsi,
            style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 20),

          Text(
            'Struktur & Ornamen Visual',
            style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Struktur Utama
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(charData.strukturUtama.badge, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(charData.strukturUtama.title, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(charData.strukturUtama.desc, style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ornamen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(charData.ornamen.badge, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(charData.ornamen.title, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(charData.ornamen.desc, style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Warna
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(charData.warna.badge, style: const TextStyle(color: AppTheme.primaryDark, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(charData.warna.title, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(charData.warna.desc, style: AppTheme.inter(fontSize: 13, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Pakem Anatomi Visual
          Row(
            children: [
              Container(width: 4, height: 18, color: const Color(0xFF5A3416)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${charData.pakemList.length} Pakem Anatomi Visual', style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...charData.pakemList.map((pakem) => _buildPakemItem(pakem.title, pakem.desc, isDark)),
        ],
      ),
    );
  }

  Widget _buildPakemItem(String title, String desc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.transparent),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryDark)),
                const SizedBox(height: 6),
                Text(desc, style: AppTheme.inter(fontSize: 12, height: 1.5, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
