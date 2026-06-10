import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised, graphics-rich theming for PitStock.
class AppTheme {
  AppTheme._();

  // Brand palette
  static const Color primary = Color(0xFF1E5AF6); // electric blue
  static const Color secondary = Color(0xFF00C2A8); // teal
  static const Color accent = Color(0xFFFF7A00); // amber
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFF4B400);

  static const Color darkBg = Color(0xFF0E1116);
  static const Color darkSurface = Color(0xFF171C24);
  static const Color darkCard = Color(0xFF1E2530);

  static LinearGradient get brandGradient => const LinearGradient(
        colors: [Color(0xFF1E5AF6), Color(0xFF00C2A8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get sunsetGradient => const LinearGradient(
        colors: [Color(0xFFFF7A00), Color(0xFFFF3D77)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0E1116),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      inputDecorationTheme: _inputTheme(Colors.white, const Color(0xFFE3E8F0)),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
          .apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      inputDecorationTheme: _inputTheme(darkSurface, const Color(0xFF2A323D)),
    );
  }

  static InputDecorationTheme _inputTheme(Color fill, Color border) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),
    );
  }
}
