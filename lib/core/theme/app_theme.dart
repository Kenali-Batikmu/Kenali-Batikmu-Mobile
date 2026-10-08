import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme sesuai dengan Design System resmi:
/// - Primary: #7A4B29 (Batik Brown)
/// - Secondary: #D49B45 (Warm Amber Gold)
/// - Tertiary: #1B2B4A (Deep Indigo Navy)
/// - Neutral: #FBF8F3 (Soft Warm Cream Background)
/// - Headline Typography: Noto Serif
/// - Body & Label Typography: Plus Jakarta Sans
class AppTheme {
  // === PALET WARNA (DESIGN SYSTEM) ===
  static const Color primary = Color(0xFF7A4B29);
  static const Color primaryDark = Color(0xFF543118);
  static const Color primaryLight = Color(0xFFA66D44);

  static const Color secondary = Color(0xFFD49B45);
  static const Color secondaryLight = Color(0xFFE4BA73);
  static const Color secondaryDark = Color(0xFFA26F21);

  static const Color tertiary = Color(0xFF1B2B4A);
  static const Color tertiaryLight = Color(0xFF2C4370);
  static const Color tertiaryDark = Color(0xFF0F1A2E);

  static const Color neutral = Color(0xFFFBF8F3);
  static const Color background = Color(0xFFFBF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFDFCF9);

  // Text Colors
  static const Color textPrimary = Color(0xFF2B231D);
  static const Color textSecondary = Color(0xFF6B625B);
  static const Color textMuted = Color(0xFF9E958C);

  // Borders & Dividers
  static const Color border = Color(0xFFEADBCE);
  static const Color borderLight = Color(0xFFF3ECE3);

  // Feedback Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFED6C02);

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF13100D);
  static const Color darkSurface = Color(0xFF201B16);
  static const Color darkCard = Color(0xFF2A231C);
  static const Color darkBorder = Color(0xFF3E3328);

  // Backward compatibility alias untuk kode lama
  static const Color accentGold = secondary;

  // === TIPOGRAFI SESUAI GAMBAR ===

  /// Headline: Noto Serif (Elegan, Berkarakter Warisan Budaya)
  static TextStyle notoSerif({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.notoSerif(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  /// Body & Label: Plus Jakarta Sans (Modern, Bersih, Sangat Terbaca di Mobile)
  static TextStyle plusJakartaSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  // Alias semantik
  static TextStyle headline({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.bold,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      notoSerif(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle label({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Backward compatibility untuk layar yang belum sempat direfaktor
  static TextStyle satoshi({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      notoSerif(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  // === BUTTON STYLES DARI GAMBAR ===
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: neutral,
        foregroundColor: textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        textStyle: plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      );

  static ButtonStyle get invertedButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: tertiary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: border, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      );

  // === THEMEDATA LIGHT ===
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: notoSerif(fontSize: 28, fontWeight: FontWeight.bold),
        headlineMedium: notoSerif(fontSize: 22, fontWeight: FontWeight.bold),
        headlineSmall: notoSerif(fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge: notoSerif(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge: plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted),
        labelLarge: plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall: plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: outlinedButtonStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: plusJakartaSans(color: textMuted, fontSize: 13),
      ),
    );
  }

  // === THEMEDATA DARK ===
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: secondary,
        secondary: primary,
        tertiary: tertiaryLight,
        surface: darkSurface,
        error: error,
        onPrimary: darkBackground,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: notoSerif(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: notoSerif(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: notoSerif(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: notoSerif(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        titleSmall: plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
        bodyLarge: plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white),
        bodyMedium: plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70),
        bodySmall: plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white54),
        labelLarge: plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
        labelSmall: plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white54),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 1.5),
        ),
        hintStyle: plusJakartaSans(color: Colors.white38, fontSize: 13),
      ),
    );
  }
}
