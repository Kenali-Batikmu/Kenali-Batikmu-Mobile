import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/youtube_link.dart';
import '../../../models/app_models.dart';
import 'expansion_card.dart';
import 'inapp_youtube_player.dart';
import 'inline_youtube_player.dart';

/// Halaman Pilar 1: Teori, Sejarah & Makna Filosofis Motif Batik
class PillarHistoryView extends StatelessWidget {
  final ModuleModel module;
  final String youtubeVideoId;
  final void Function(String imageUrl, String subtitle) onZoomImage;
  final bool isDark;

  const PillarHistoryView({
    super.key,
    required this.module,
    this.youtubeVideoId = '',
    required this.onZoomImage,
    required this.isDark,
  });

  /// Badge motif disesuaikan asal-usul tiap batik (bukan semua 'larangan':
  /// pesisir Pekalongan/Lasem, Betawi, dan Dayak tidak memakai paugeran larangan keraton)
  String get _motifBadgeLabel {
    final t = module.title.toLowerCase();
    if (t.contains('sido') || t.contains('wahyu') || t.contains('parang') || t.contains('kawung') || t.contains('truntum')) {
      return 'Motif Larangan Keraton Mataram';
    }
    if (t.contains('singa barong')) return 'Motif Kraton Cirebon';
    if (t.contains('mega mendung')) return 'Motif Klasik Cirebon';
    if (t.contains('tujuh rupa') || t.contains('jlamprang')) return 'Motif Klasik Pesisir Pekalongan';
    if (t.contains('buketan')) return 'Motif Pesisir Indo-Eropa Pekalongan';
    if (t.contains('betawi')) return 'Motif Khas Betawi';
    if (t.contains('dayak') || t.contains('benang bintik')) return 'Motif Khas Kalimantan Tengah';
    if (t.contains('liong')) return 'Motif Klasik Pesisiran';
    return 'Motif Klasik Nusantara';
  }

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
                      ? GestureDetector(
                          onTap: () => onZoomImage(module.coverImage!, 'Foto Utama Motif Batik'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(module.coverImage!, fit: BoxFit.cover),
                          ),
                        )
                      : Center(child: Icon(Icons.waves, size: 90, color: Colors.white.withValues(alpha: 0.18))),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: GestureDetector(
                    onTap: module.coverImage != null
                        ? () => onZoomImage(module.coverImage!, 'Foto Utama Motif Batik')
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.accentGold, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _motifBadgeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => onZoomImage(
                      module.coverImage ?? '',
                      'Foto Utama Motif Batik',
                    ),
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

          if (youtubeVideoId.isNotEmpty) ...[
            InlineYoutubePlayer(
              videoId: youtubeVideoId,
              title: module.title,
              onOpenFullscreen: () => _openInAppPlayer(context),
            ),
            const SizedBox(height: 10),
            _buildYoutubeButton(),
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

          if (content.sumberRujukan.isNotEmpty) ...[
            const SizedBox(height: 10),
            ExpansionCard(
              title: 'Sumber & Rujukan',
              icon: Icons.menu_book_outlined,
              body: content.sumberRujukan.map((ref) => '• $ref').join('\n\n'),
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYoutubeButton() {
    return Material(
      color: isDark ? AppTheme.darkSurface : const Color(0xFFFBF7F2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openInBrowser,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
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
                      'Buka di YouTube',
                      style: AppTheme.satoshi(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cadangan bila video tidak muncul di dalam aplikasi',
                      style: AppTheme.inter(fontSize: 11, color: AppTheme.textSecondary),
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
    );
  }

  void _openInAppPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppYoutubePlayerScreen(
          videoId: youtubeVideoId,
          title: module.title,
        ),
      ),
    );
  }

  /// Membuka video di aplikasi YouTube/browser sebagai jalur cadangan.
  Future<void> _openInBrowser() async {
    final videoId = YoutubeLink.extractVideoId(youtubeVideoId);
    if (videoId == null) return;
    try {
      await launchUrl(
        YoutubeLink.watchUri(videoId),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}
