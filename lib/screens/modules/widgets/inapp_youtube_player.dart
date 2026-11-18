import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'inline_youtube_player.dart';

/// Halaman pemutar layar penuh untuk video pembahasan motif batik.
/// Memakai pemutar yang sama dengan halaman Teori agar perilakunya konsisten.
class InAppYoutubePlayerScreen extends StatelessWidget {
  final String videoId;
  final String title;

  const InAppYoutubePlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VIDEO PEMBAHASAN',
              style: AppTheme.satoshi(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppTheme.primary,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.satoshi(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: InlineYoutubePlayer(
            videoId: videoId,
            title: title,
            fill: true,
          ),
        ),
      ),
    );
  }
}
