import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color brand     = Color(0xFF6EE7B7);
  static const Color brandDark = Color(0xFF10B981);
  static const Color accent    = Color(0xFFF59E0B);
  static const Color danger    = Color(0xFFEF4444);
  static const Color purple    = Color(0xFF8B5CF6);

  // ── Dark Palette ───────────────────────────────────────────────────────────
  static const Color darkBg      = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard    = Color(0xFF21262D);
  static const Color darkBorder  = Color(0xFF30363D);
  static const Color darkText    = Color(0xFFF0F6FC);
  static const Color darkSubtext = Color(0xFF8B949E);

  // ── Light Palette ──────────────────────────────────────────────────────────
  static const Color lightBg      = Color(0xFFF6F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard    = Color(0xFFFFFFFF);
  static const Color lightBorder  = Color(0xFFD0D7DE);
  static const Color lightText    = Color(0xFF1F2328);
  static const Color lightSubtext = Color(0xFF656D76);

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: brand,
          secondary: accent,
          surface: darkSurface,
          error: danger,
          onPrimary: darkBg,
          onSurface: darkText,
        ),
        textTheme: GoogleFonts.syneTextTheme(_baseTextTheme(darkText, darkSubtext)),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBg,
          foregroundColor: darkText,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardTheme(
          color: darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: darkBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brand,
            foregroundColor: darkBg,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: brand, width: 2)),
          hintStyle: const TextStyle(color: darkSubtext),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkSurface,
          selectedItemColor: brand,
          unselectedItemColor: darkSubtext,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerColor: darkBorder,
        iconTheme: const IconThemeData(color: darkSubtext),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: brand),
      );

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        colorScheme: const ColorScheme.light(
          primary: brandDark,
          secondary: accent,
          surface: lightSurface,
          error: danger,
          onPrimary: Colors.white,
          onSurface: lightText,
        ),
        textTheme: GoogleFonts.syneTextTheme(_baseTextTheme(lightText, lightSubtext)),
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBg,
          foregroundColor: lightText,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardTheme(
          color: lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: lightBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lightBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: lightBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: brandDark, width: 2)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: lightSurface,
          selectedItemColor: brandDark,
          unselectedItemColor: lightSubtext,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerColor: lightBorder,
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: brandDark),
      );

  static TextTheme _baseTextTheme(Color primary, Color secondary) => TextTheme(
        displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primary, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: primary, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: primary),
        headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: primary),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
        bodyLarge:     TextStyle(fontSize: 15, color: primary),
        bodyMedium:    TextStyle(fontSize: 14, color: secondary),
        bodySmall:     TextStyle(fontSize: 12, color: secondary),
        labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
      );
}
