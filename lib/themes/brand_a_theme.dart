import 'package:flutter/material.dart';

final ThemeData brandATheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue[800],
  hintColor: Colors.orange[600],
  scaffoldBackgroundColor: Colors.blue[50],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue[800],
    foregroundColor: Colors.white,
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.orange[600],
    textTheme: ButtonTextTheme.primary,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(color: Colors.blueGrey),
    headlineMedium: TextStyle(color: Colors.blueGrey),
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black54),
  ),
  colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.orange[600]),
);
