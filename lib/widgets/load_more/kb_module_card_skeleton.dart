import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Skeleton card yang meniru layout KbModuleCard agar tidak ada layout shift
/// (CLS = 0) saat batch baru sedang dimuat.
///
/// Dimensi disesuaikan persis dengan KbModuleCard asli:
/// - Header: 108px, body: ~170px (deskripsi + progress + tombol + chip)
/// - Border radius: 20px, padding: 18px
class KbModuleCardSkeleton extends StatefulWidget {
  final bool isDark;
  final EdgeInsetsGeometry? margin;

  const KbModuleCardSkeleton({super.key, required this.isDark, this.margin});

  @override
  State<KbModuleCardSkeleton> createState() => _KbModuleCardSkeletonState();
}

class _KbModuleCardSkeletonState extends State<KbModuleCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmerAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyColor = widget.isDark ? AppTheme.darkSurface : const Color(0xFFFFFDF8);
    final borderColor = widget.isDark ? AppTheme.darkBorder : const Color(0xFFE5D3B8);

    return Padding(
      padding: widget.margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ListenableBuilder(
        listenable: _shimmerAnim,
        builder: (context, child) {
          final opacity = _shimmerAnim.value;

          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Skeleton (108px, sama dengan _kHeaderHeight) ──
                Container(
                  height: 108,
                  decoration: BoxDecoration(
                    color: (widget.isDark
                            ? const Color(0xFF2A221A)
                            : const Color(0xFFE5D3B8))
                        .withValues(alpha: opacity),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(60, 10, opacity),
                      const SizedBox(height: 12),
                      _shimmerBox(double.infinity, 14, opacity),
                      const SizedBox(height: 6),
                      _shimmerBox(180, 14, opacity),
                    ],
                  ),
                ),

                // ── Body Skeleton ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deskripsi (2 baris)
                      _shimmerBox(double.infinity, 10, opacity),
                      const SizedBox(height: 5),
                      _shimmerBox(220, 10, opacity),
                      const SizedBox(height: 14),

                      // Progress bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _shimmerBox(80, 9, opacity),
                          _shimmerBox(30, 9, opacity),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _shimmerBox(double.infinity, 6, opacity),
                      const SizedBox(height: 14),

                      // Tombol aksi (46px, sama dengan card asli)
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: (widget.isDark
                                  ? const Color(0xFF2A221A)
                                  : const Color(0xFFE5D3B8))
                              .withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Chip nilai (2 chip)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: (widget.isDark
                                        ? const Color(0xFF2A221A)
                                        : const Color(0xFFF3ECE3))
                                    .withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: (widget.isDark
                                        ? const Color(0xFF2A221A)
                                        : const Color(0xFFF3ECE3))
                                    .withValues(alpha: opacity),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Box placeholder persegi panjang dengan efek shimmer.
  Widget _shimmerBox(double width, double height, double opacity) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: (widget.isDark ? Colors.white : const Color(0xFF8A6D56))
            .withValues(alpha: opacity * 0.25),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
