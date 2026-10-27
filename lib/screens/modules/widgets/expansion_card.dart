import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Kartu konten berbingkai rapi untuk Sejarah, Filosofi, dan Penggunaan
class ExpansionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String body;
  final bool isDark;

  const ExpansionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: AppTheme.satoshi(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(body, style: AppTheme.inter(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
