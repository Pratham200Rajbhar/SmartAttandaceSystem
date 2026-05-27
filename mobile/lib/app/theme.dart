
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SasColors {
  SasColors._();

  static const Color bgPrimary = Color(0xFF000000);
  static const Color bgSecondary = Color(0xFF05050A);
  static const Color bgSurface = Color(0xFF0A0B1C);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF64748B);

  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color accentAmber = Color(0xFFF59E0B);

  static const Color glassBg = Color(0x09FFFFFF); 
  static const Color glassBgHover = Color(0x12FFFFFF); 
  static const Color glassBorder = Color(0x17FFFFFF); 
  static const Color glassBorderHover = Color(0x33FFFFFF); 

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFB923C);
  static const Color danger = Color(0xFFFB7185);
  static const Color info = Color(0xFF38BDF8);
}

/// Standardized spacing tokens to replace hardcoded EdgeInsets values.
class SasSpacing {
  SasSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Default screen-level padding used by AppScaffold and all list views.
  static const EdgeInsets screenPadding = EdgeInsets.all(xl);
}

/// Standardized border radius tokens.
class SasRadius {
  SasRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
}

/// Standardized animation duration tokens.
class SasDurations {
  SasDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration vSlow = Duration(milliseconds: 500);
}

ThemeData buildSasTheme() {
  final baseText = GoogleFonts.plusJakartaSansTextTheme(
    ThemeData.dark().textTheme,
  );

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SasColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: SasColors.accentEmerald,
      secondary: SasColors.accentTeal,
      surface: SasColors.bgSecondary,
      error: SasColors.accentPink,
      onPrimary: SasColors.textPrimary,
      onSecondary: SasColors.textPrimary,
      onSurface: SasColors.textPrimary,
      onError: SasColors.textPrimary,
    ),
    textTheme: baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontFamily: GoogleFonts.outfit().fontFamily,
        letterSpacing: -0.025,
        color: SasColors.textPrimary,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontFamily: GoogleFonts.outfit().fontFamily,
        letterSpacing: -0.025,
        color: SasColors.textPrimary,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontFamily: GoogleFonts.outfit().fontFamily,
        letterSpacing: -0.025,
        color: SasColors.textPrimary,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontFamily: GoogleFonts.outfit().fontFamily,
        fontWeight: FontWeight.w700,
        color: SasColors.textPrimary,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        color: SasColors.textPrimary,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        color: SasColors.textSecondary,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        color: SasColors.textMuted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: SasColors.textPrimary,
        letterSpacing: -0.025,
      ),
      iconTheme: const IconThemeData(color: SasColors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x80030410),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: SasColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: SasColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: SasColors.glassBorderHover,
          width: 1.5,
        ),
      ),
      hintStyle: const TextStyle(color: SasColors.textMuted),
      labelStyle: const TextStyle(color: SasColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SasColors.glassBgHover,
        foregroundColor: SasColors.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SasColors.glassBorderHover),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: SasColors.glassBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SasColors.glassBorder),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: SasColors.accentEmerald,
      unselectedItemColor: SasColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: SasColors.glassBorder,
    useMaterial3: true,
  );
}
