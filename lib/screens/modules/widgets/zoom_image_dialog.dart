import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Menampilkan dialog perbesaran detail motif batik
void showZoomImageDialog(BuildContext context, bool isDark) {
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Detail Motif Batik',
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
                const SizedBox(height: 16),
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF382516),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
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
