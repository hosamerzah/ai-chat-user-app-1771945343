import 'package:flutter/material.dart';
import 'package:ai_chat_user_app/themes/light_theme.dart';
import 'package:ai_chat_user_app/themes/dark_theme.dart';
import 'package:ai_chat_user_app/themes/brand_a_theme.dart';
import 'package:ai_chat_user_app/themes/brand_b_theme.dart';

enum AppTheme {
  light,
  dark,
  brandA,
  brandB,
}

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = lightTheme;
  AppTheme _currentThemeEnum = AppTheme.light;

  ThemeData get currentTheme => _currentTheme;
  AppTheme get currentThemeEnum => _currentThemeEnum;

  void setTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        _currentTheme = lightTheme;
        break;
      case AppTheme.dark:
        _currentTheme = darkTheme;
        break;
      case AppTheme.brandA:
        _currentTheme = brandATheme;
        break;
      case AppTheme.brandB:
        _currentTheme = brandBTheme;
        break;
    }
    _currentThemeEnum = theme;
    notifyListeners();
  }

  void toggleTheme() {
    if (_currentThemeEnum == AppTheme.light) {
      setTheme(AppTheme.dark);
    } else {
      setTheme(AppTheme.light);
    }
  }
}
