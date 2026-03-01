import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _primaryColorDark = Color(0xFF9D8FFF); // Lighter purple for dark mode
const _secondaryColorDark = Color(0xFF80CBC4);
const _surfaceDark = Color(0xFF13131A); // Deepened surface
const _backgroundDark = Color(0xFF0D0D14); // Deepened background
const _errorColorDark = Color(0xFFCF6679);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.outfit().fontFamily,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: _primaryColorDark,
    onPrimary: const Color(0xFF21005D),
    primaryContainer: const Color(0xFF4D3B9E),
    onPrimaryContainer: const Color(0xFFEDE7FF),
    secondary: _secondaryColorDark,
    onSecondary: Colors.black,
    secondaryContainer: const Color(0xFF2A5A58),
    onSecondaryContainer: const Color(0xFFCEFAF8),
    surface: _surfaceDark,
    onSurface: const Color(0xFFE6E0F8),
    error: _errorColorDark,
    onError: Colors.white,
    outline: const Color(0xFF4A5568),
  ),
  scaffoldBackgroundColor: _backgroundDark,
  appBarTheme: const AppBarTheme(
    backgroundColor: _surfaceDark,
    foregroundColor: Color(0xFFE6E0F8),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFFE6E0F8),
      letterSpacing: 0.5,
    ),
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: const Color(0xFF1A1A24),
    surfaceTintColor: Colors.transparent,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _primaryColorDark,
      foregroundColor: const Color(0xFF21005D),
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _primaryColorDark,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF4A5568)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF374151)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primaryColorDark, width: 2),
    ),
    filled: true,
    fillColor: const Color(0xFF1A1A24),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE6E0F8)),
    headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFE6E0F8)),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFD1C4E9)),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFD1C4E9)),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFB39DDB)),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFD1C4E9)),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD1C4E9)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF374151), thickness: 1),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF252538),
    contentTextStyle: const TextStyle(color: Color(0xFFE6E0F8)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
  ),
);
