import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Heritage Warm Brown Palette sesuai Figma & Budaya Batik Nusantara
  static const Color primary = Color(0xFF7A4B29); // Batik Brown
  static const Color primaryDark = Color(0xFF543118);
  static const Color primaryLight = Color(0xFFA66D44);
  
  static const Color background = Color(0xFFF8F5EE); // Warm ivory background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFDFBF7);
  
  static const Color textPrimary = Color(0xFF2B231D);
  static const Color textSecondary = Color(0xFF6B625B);
  static const Color textMuted = Color(0xFF9E958C);
  
  static const Color border = Color(0xFFE8E2D8);
  static const Color borderLight = Color(0xFFF0EBE1);
  
  static const Color accentGold = Color(0xFFD49B45);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);

  // Typography: Satoshi (Headings) + Inter (Body/UI)
  // Catatan: Satoshi dimuat via GoogleFonts atau fallback jika offline
  static TextStyle satoshi({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
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

  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static const Color darkBackground = Color(0xFF14110E); // Deep Warm Black/Brown
  static const Color darkSurface = Color(0xFF221C16); // Elevated dark brown card
  static const Color darkCard = Color(0xFF2B231C);
  static const Color darkBorder = Color(0xFF3D3228);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accentGold,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: satoshi(fontSize: 28, fontWeight: FontWeight.bold),
        headlineMedium: satoshi(fontSize: 22, fontWeight: FontWeight.bold),
        headlineSmall: satoshi(fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge: satoshi(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: satoshi(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: inter(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: inter(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: inter(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted),
        labelLarge: satoshi(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: satoshi(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        ),
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
        hintStyle: inter(color: textMuted, fontSize: 13),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: primary,
        surface: darkSurface,
        error: error,
        onPrimary: darkBackground,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: satoshi(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: satoshi(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        headlineSmall: satoshi(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: satoshi(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: satoshi(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: inter(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white),
        bodyMedium: inter(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70),
        bodySmall: inter(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white54),
        labelLarge: satoshi(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: satoshi(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
          borderSide: const BorderSide(color: accentGold, width: 1.5),
        ),
        hintStyle: inter(color: Colors.white38, fontSize: 13),
      ),
    );
  }
}
