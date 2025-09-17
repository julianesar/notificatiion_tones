import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Default to dark theme to match the bell icon style

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode ? ThemeConfig.darkTheme : ThemeConfig.lightTheme;
  }
}
