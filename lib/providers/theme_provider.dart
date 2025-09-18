import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData get currentTheme {
    return ThemeConfig.appTheme;
  }
}
