import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';

class CilikTheme {
  // Modern Kid-Friendly Palette
  static const Color tealTua = Color(0xFF00695C);
  static const Color woodBrown = Color(0xFF6D4C41);
  static const Color mintGreen = Color(0xFF80CBC4);
  static const Color cleanWhite = Colors.white;
  static const Color textDark = Color(0xFF212121);
  static const Color backgroundLight = Color(0xFFF5F5F5);

  static ThemeData get lightTheme {
    bool isDesktop = kIsWeb || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.macOS;

    double scale = isDesktop ? 1.2 : 1.0;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tealTua,
        primary: tealTua,
        secondary: woodBrown,
        tertiary: mintGreen,
        surface: cleanWhite,
        background: backgroundLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.fredokaTextTheme().copyWith(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 32 * scale,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.fredoka(
          fontSize: 28 * scale,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 24 * scale,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.fredoka(
          fontSize: 18 * scale,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.fredoka(
          fontSize: 16 * scale,
          color: textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealTua,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          elevation: 8,
          shadowColor: tealTua.withOpacity(0.4),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cleanWhite,
        elevation: 10,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cleanWhite,
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: tealTua,
        ),
        contentTextStyle: GoogleFonts.fredoka(
          fontSize: 18,
          color: textDark,
        ),
      ),
    );
  }
}
