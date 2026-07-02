import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class AppTheme {
  AppTheme._();

  static bool get _isDark => Get.find<ThemeController>().isDark.value;

  // ─── Bảng màu thương hiệu (giữ nguyên ở cả 2 theme) ─────
  static const Color primary      = Color(0xFF00E5A0);
  static const Color primaryDark  = Color(0xFF00B87A);
  static const Color secondary    = Color(0xFF0091FF);
  static const Color accent       = Color(0xFF7B61FF);
  static const Color warning      = Color(0xFFFFB347);
  static const Color danger       = Color(0xFFFF4D6D);

  // ─── Màu nền / text — đổi theo theme hiện tại ───────────
  static Color get bg            => _isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F6F9);
  static Color get bgCard        => _isDark ? const Color(0xFF111827) : Colors.white;
  static Color get bgSurface     => _isDark ? const Color(0xFF1A2236) : const Color(0xFFEDEFF3);
  static Color get bgBorder      => _isDark ? const Color(0xFF263147) : const Color(0xFFE1E4EA);

  static Color get textPrimary   => _isDark ? const Color(0xFFF0F4FF) : const Color(0xFF1A1D29);
  static Color get textSecondary => _isDark ? const Color(0xFF8899BB) : const Color(0xFF6B7280);
  static Color get textDisabled  => _isDark ? const Color(0xFF4A5568) : const Color(0xFFB0B4BA);

  // ─── Gradient ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF0091FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get bgGradient => _isDark
      ? const LinearGradient(
          colors: [Color(0xFF0A0E1A), Color(0xFF0D1526)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
      : const LinearGradient(
          colors: [Color(0xFFF5F6F9), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bgColor        = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F6F9);
    final cardColor      = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor    = isDark ? const Color(0xFF263147) : const Color(0xFFE1E4EA);
    final textPrimaryC   = isDark ? const Color(0xFFF0F4FF) : const Color(0xFF1A1D29);
    final textSecondaryC = isDark ? const Color(0xFF8899BB) : const Color(0xFF6B7280);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: const Color(0xFF001A0F),
        secondary: secondary,
        onSecondary: Colors.white,
        error: danger,
        onError: Colors.white,
        surface: cardColor,
        onSurface: textPrimaryC,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: textPrimaryC, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: textPrimaryC, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: textPrimaryC, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: textPrimaryC, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: textPrimaryC, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimaryC, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimaryC, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimaryC),
          bodyMedium: TextStyle(color: textSecondaryC),
          labelLarge: TextStyle(color: textPrimaryC, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textPrimaryC,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimaryC,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(color: primary, fontWeight: FontWeight.w600, fontSize: 11);
          }
          return GoogleFonts.inter(color: textSecondaryC, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const IconThemeData(color: primary);
          return IconThemeData(color: textSecondaryC);
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
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2236) : const Color(0xFFEDEFF3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}