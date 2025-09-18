import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeConfig {
  // New Color Scheme
  static const Color primary = Color(0xFFFF7043); // Primary color for buttons and accents
  static const Color backgroundMain = Color(0xFF263238); // Background color for screens
  static const Color cardSurface = Color(0xFF37474F); // Cards and menus color
  static const Color importantText = Color(0xFFECEFF1); // Important texts color

  // Complementary colors
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color primaryDark = Color(0xFFE64A19);
  static const Color secondary = Color(0xFF546E7A);
  static const Color error = Color(0xFFEF4444);
  static const Color snackBar = Color(0xFF171717);

  // Theme Colors (Dark Theme as Default)
  static const Color primaryTheme = primary;
  static const Color primaryVariant = primaryLight;
  static const Color secondaryTheme = secondary;
  static const Color backgroundTheme = backgroundMain;
  static const Color surfaceTheme = cardSurface;
  static const Color errorTheme = Color(0xFFF87171);

  // Text Colors
  static const Color textPrimary = importantText;
  static const Color textSecondary = Color(0xFFB0BEC5);

  // Audio Player Colors
  static const Color audioPlayerPrimary = primary;
  static const Color audioPlayerSecondary = primaryLight;
  static const Color waveformActive = primary;
  static const Color waveformInactive = Color(0xFFE5E7EB);

  static ThemeData get appTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryTheme,
        secondary: secondaryTheme,
        surface: backgroundTheme,
        error: errorTheme,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        iconTheme: IconThemeData(color: textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTheme,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceTheme,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceTheme,
        selectedItemColor: primaryTheme,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

}
