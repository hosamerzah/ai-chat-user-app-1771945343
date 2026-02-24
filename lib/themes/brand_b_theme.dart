import 'package:flutter/material.dart';

final ThemeData brandBTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.purple[800],
  hintColor: Colors.cyan[600],
  scaffoldBackgroundColor: Colors.purple[50],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.purple[800],
    foregroundColor: Colors.white,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.cyan[600],
    textTheme: ButtonTextTheme.primary,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(color: Colors.deepPurple),
    headlineMedium: TextStyle(color: Colors.deepPurpleAccent),
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black54),
  ),
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.purple).copyWith(secondary: Colors.cyan[600]),
);
