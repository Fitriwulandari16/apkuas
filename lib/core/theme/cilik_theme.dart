import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CilikTheme {
  // Pastel Eye-Comfort Palette
  static const Color primaryPastel = Color(0xFFB5EAD7); // Mint
  static const Color secondaryPastel = Color(0xFFFF9AA2); // Pink
  static const Color accentPastel = Color(0xFFFFDAC1); // Peach
  static const Color backgroundPastel = Color(0xFFF7F9FC); // Off-white/blue
  static const Color surfacePastel = Colors.white;
  static const Color textDark = Color(0xFF2D3436);
  static const Color errorPastel = Color(0xFFFF6B6B);
  static const Color successPastel = Color(0xFF55E6C1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPastel,
        primary: primaryPastel,
        secondary: secondaryPastel,
        tertiary: accentPastel,
        surface: surfacePastel,
        background: backgroundPastel,
        error: errorPastel,
        onPrimary: textDark,
        onSecondary: Colors.white,
        onSurface: textDark,
        onBackground: textDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 18,
          color: textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPastel,
          foregroundColor: textDark,
          minimumSize: const Size(48, 48), // Child-friendly target size
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfacePastel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }
}
