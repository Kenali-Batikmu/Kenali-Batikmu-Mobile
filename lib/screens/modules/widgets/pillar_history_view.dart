import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/app_models.dart';
import 'expansion_card.dart';

/// Halaman Pilar 1: Teori, Sejarah & Makna Filosofis Motif Batik
class PillarHistoryView extends StatelessWidget {
  final ModuleModel module;
  final YoutubePlayerController? youtubeController;
  final VoidCallback onZoomImage;
  final bool isDark;

  const PillarHistoryView({
    super.key,
    required this.module,
    required this.youtubeController,
    required this.onZoomImage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final content = module.content;
    if (content == null) return const Center(child: CircularProgressIndicator());
    final sejarah = content.sejarahDanFilosofi;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Motif dengan Badge 'Motif Klasik Larangan' dan 'Perbesar Detail'
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF382516),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: module.coverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(module.coverImage!, fit: BoxFit.cover),
                        )
                      : Center(child: Icon(Icons.waves, size: 90, color: Colors.white.withValues(alpha: 0.18))),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, color: AppTheme.accentGold, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Motif Klasik Larangan',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: onZoomImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Perbesar Detail',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Badge Modul & Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'MODUL ${module.orderNo} • TEORI & FILOSOFI',
              style: AppTheme.satoshi(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            module.title,
            style: AppTheme.satoshi(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${content.origin} • Estimasi Baca ${content.estimatedTime}',
            style: AppTheme.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          if (youtubeController != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: YoutubePlayer(
                controller: youtubeController!,
                keepAlive: true,
                gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
                },
              ),
            ),
            const SizedBox(height: 10),
            if (sejarah.youtubeUrl.isNotEmpty)
              Material(
                color: isDark ? AppTheme.darkSurface : const Color(0xFFFBF7F2),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final uri = Uri.tryParse(sejarah.youtubeUrl);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_circle_filled_rounded,
                            color: Color(0xFFFF0000),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buka di Aplikasi YouTube',
                                style: AppTheme.satoshi(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tonton langsung di YouTube jika terkendala di dalam aplikasi',
                                style: AppTheme.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],

          // Section Hakikat & Simbol
          Text(
            'Hakikat & Simbol',
            style: AppTheme.satoshi(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            sejarah.deskripsiUtama,
            style: AppTheme.inter(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // ExpansionCard: Asal Daerah & Sejarah
          ExpansionCard(
            title: 'Asal Daerah & Sejarah',
            icon: Icons.history_edu,
            body: sejarah.asalDaerah,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // ExpansionCard: Makna Filosofis Simbolik
          ExpansionCard(
            title: 'Makna Filosofis Simbolik',
            icon: Icons.psychology,
            body: sejarah.maknaFilosofis,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          // ExpansionCard: Penggunaan Tradisional & Pakem
          ExpansionCard(
            title: 'Penggunaan Tradisional & Pakem',
            icon: Icons.verified_user_outlined,
            body: sejarah.penggunaan,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}
