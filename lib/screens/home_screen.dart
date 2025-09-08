import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../features/categories/presentation/pages/categories_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonidos de Notificaciones'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen
            },
          ),
        ],
      ),
      body: const CategoriesPage(),
    );
  }
}
