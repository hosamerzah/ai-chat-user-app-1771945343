import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _primaryColor = Color(0xFF6C63FF); // Rich purple
const _secondaryColor = Color(0xFF03DAC6); // Teal accent
const _surfaceColor = Color(0xFFF5F5FF); // Very light purple tint
const _backgroundColor = Color(0xFFFAFAFF);
const _errorColor = Color(0xFFCF6679);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: GoogleFonts.outfit().fontFamily,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: _primaryColor,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFEDE7FF),
    onPrimaryContainer: const Color(0xFF21005D),
    secondary: _secondaryColor,
    onSecondary: Colors.black,
    secondaryContainer: const Color(0xFFCEFAF8),
    onSecondaryContainer: const Color(0xFF003733),
    surface: _surfaceColor,
    onSurface: const Color(0xFF1C1B1F),
    error: _errorColor,
    onError: Colors.white,
    outline: const Color(0xFFB0BEC5),
  ),
  scaffoldBackgroundColor: _backgroundColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: _primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.5,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: Colors.white,
    surfaceTintColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
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
      foregroundColor: _primaryColor,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primaryColor, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: const TextStyle(color: Color(0xFF6B7280)),
    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
    headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
    bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF374151)),
    bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF1F2937),
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
  ),
);
