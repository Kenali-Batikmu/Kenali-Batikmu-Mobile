import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/app_models.dart';

/// Komponen Header Bar Terpadu (Kenali Batikmu)
/// Menampilkan Logo di kiri dan Avatar Profil di kanan.
/// Opsional: menampilkan Search Bar di tengah (misal di halaman modul).
class KbHeaderBar extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onOpenProfile;
  final bool showSearch;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final String searchHint;
  final double height;
  final EdgeInsetsGeometry padding;

  const KbHeaderBar({
    super.key,
    required this.user,
    this.onOpenProfile,
    this.showSearch = false,
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.onSearchClear,
    this.searchHint = 'Cari modul batik...',
    this.height = 46.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static ImageProvider? avatarImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (kIsWeb || path.startsWith('http')) return NetworkImage(path);
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final img = avatarImage(user?.profileImagePath);
    final initial = (user?.name.isNotEmpty ?? false)
        ? user!.name[0].toUpperCase()
        : (user?.email.isNotEmpty ?? false ? user!.email[0].toUpperCase() : 'K');

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: showSearch
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceBetween,
        children: [
          // 1. Logo Aplikasi (Kiri - langsung tanpa container / clip oval)
          Image.asset(
            'assets/images/logo_1.png',
            width: height,
            height: height,
            fit: BoxFit.contain,
          ),

          // 2. Search Bar (Tengah, aktif bila showSearch == true)
          if (showSearch) ...[
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: height,
                padding: const EdgeInsets.only(left: 6, right: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(height / 2),
                  border: Border.all(
                    color: (searchFocusNode?.hasFocus ?? false)
                        ? AppTheme.accentGold
                        : const Color(0xFFE5D3B8),
                    width: (searchFocusNode?.hasFocus ?? false) ? 1.5 : 1,
                  ),
                  boxShadow: softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4E4C4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF7B3A1A),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        cursorColor: const Color(0xFF7B3A1A),
                        onChanged: onSearchChanged,
                        textAlignVertical: TextAlignVertical.center,
                        style: AppTheme.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: AppTheme.inter(
                            fontSize: 13,
                            color: const Color(0xFFA59284),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (searchController?.text.isNotEmpty ?? false)
                      GestureDetector(
                        onTap: () {
                          searchController?.clear();
                          if (onSearchClear != null) onSearchClear!();
                          if (onSearchChanged != null) onSearchChanged!('');
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF8A6D56),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // 3. Avatar Profil (Kanan)
          GestureDetector(
            onTap: onOpenProfile,
            child: Container(
              width: height,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary,
                border: Border.all(color: AppTheme.accentGold, width: 2),
                boxShadow: softShadow,
                image: img != null
                    ? DecorationImage(image: img, fit: BoxFit.cover)
                    : null,
              ),
              child: img == null
                  ? Text(
                      initial,
                      style: AppTheme.satoshi(
                        color: Colors.white,
                        fontSize: height * 0.42,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
