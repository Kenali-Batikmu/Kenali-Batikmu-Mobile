import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Menampilkan dialog perbesaran detail motif batik
void showZoomImageDialog(
  BuildContext context,
  bool isDark, {
  String? imageUrl,
  String? title,
  String? subtitle,
}) {
  final imageToDisplay = (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : '';
  final dialogTitle = (title != null && title.isNotEmpty) ? title : 'Detail Motif Batik';

  showDialog(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: isDark ? AppTheme.darkSurface : const Color(0xFF221A14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dialogTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.satoshi(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.inter(fontSize: 12, color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF382516),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (imageToDisplay.isNotEmpty)
                        InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 3.5,
                          child: Image.asset(
                            imageToDisplay,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 320,
                          ),
                        )
                      else
                        Icon(Icons.waves, size: 160, color: Colors.white.withValues(alpha: 0.2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
