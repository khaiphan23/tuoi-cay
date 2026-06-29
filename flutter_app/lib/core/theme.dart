import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme — Thiết kế tối (dark mode) cho Smart Irrigation
class AppTheme {
  AppTheme._();

  // ─── Bảng màu chính ─────────────────────────────────────
  static const Color primary      = Color(0xFF00E5A0);   // Xanh lá neon
  static const Color primaryDark  = Color(0xFF00B87A);
  static const Color secondary    = Color(0xFF0091FF);   // Xanh dương
  static const Color accent       = Color(0xFF7B61FF);   // Tím
  static const Color warning      = Color(0xFFFFB347);   // Cam
  static const Color danger       = Color(0xFFFF4D6D);   // Đỏ

  // ─── Màu nền ────────────────────────────────────────────
  static const Color bg           = Color(0xFF0A0E1A);   // Nền chính
  static const Color bgCard       = Color(0xFF111827);   // Card
  static const Color bgSurface    = Color(0xFF1A2236);   // Surface
  static const Color bgBorder     = Color(0xFF263147);   // Viền

  // ─── Màu text ───────────────────────────────────────────
  static const Color textPrimary  = Color(0xFFF0F4FF);
  static const Color textSecondary= Color(0xFF8899BB);
  static const Color textDisabled = Color(0xFF4A5568);

  // ─── Gradient ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF0091FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1526)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: bgCard,
      error: danger,
      onPrimary: Color(0xFF001A0F),
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardTheme(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: bgBorder, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bgCard,
      indicatorColor: primary.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600, fontSize: 11);
        }
        return GoogleFonts.inter(color: textSecondary, fontSize: 11);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const IconThemeData(color: primary);
        return const IconThemeData(color: textSecondary);
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: const Color(0xFF001A0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    dividerTheme: const DividerThemeData(color: bgBorder, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: bgBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: bgBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
  );
}
