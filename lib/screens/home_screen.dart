import 'package:flutter/material.dart';
import '../features/categories/presentation/pages/categories_page.dart';
import '../core/theme/icon_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonidos de Notificaciones'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings functionality
            },
          ),
        ],
      ),
      body: const CategoriesPage(),
    );
  }
}
