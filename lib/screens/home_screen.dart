import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/categories/presentation/pages/categories_page.dart';
import '../core/theme/icon_colors.dart';
import 'main_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom header with title and settings icon
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large title on the left
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sonidos de',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Notificaciones',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Recent icon on the right
                    IconButton(
                      onPressed: () {
                        // Navigate to recent tab
                        MainScreen.mainScreenKey.currentState?.changeTab(2);
                      },
                      icon: Icon(
                        Icons.history,
                        size: 28,
                        color: context.iconSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Categories content
              const Expanded(
                child: CategoriesPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
