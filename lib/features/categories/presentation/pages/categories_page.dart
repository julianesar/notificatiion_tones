import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/categories_provider.dart';
import '../../../tones/presentation/pages/tones_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: Consumer<CategoriesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar las categorías',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.errorMessage ?? 'Error desconocido',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.load,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // ⬇️ Grid de 2 columnas como en code .txt
          return RefreshIndicator(
            onRefresh: () => provider.load(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 items por fila
                crossAxisSpacing: 16, // espacio horizontal
                mainAxisSpacing: 16, // espacio vertical
                childAspectRatio: 1.2, // proporción similar a code .txt
              ),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return _CategoryTile(
                  title: category.title,
                  categoryId: category.id,
                  onTap: () {
                    // Navega a la lista de tonos de la categoría
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TonesPage(
                          categoryId: category.id,
                          title: category.title,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta estilo "card + inkWell" (patrón de code .txt)
class _CategoryTile extends StatelessWidget {
  final String title;
  final String categoryId;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.categoryId,
    required this.onTap,
  });

  IconData _getCategoryIcon() {
    // Mapeo de IDs/títulos de categorías a iconos relevantes
    final titleLower = title.toLowerCase();

    if (titleLower.contains('notificacion') ||
        titleLower.contains('notification')) {
      return Icons.notifications;
    } else if (titleLower.contains('alarm') ||
        titleLower.contains('despertar')) {
      return Icons.alarm;
    } else if (titleLower.contains('llamada') ||
        titleLower.contains('call') ||
        titleLower.contains('ring')) {
      return Icons.phone;
    } else if (titleLower.contains('mensaje') ||
        titleLower.contains('sms') ||
        titleLower.contains('text')) {
      return Icons.message;
    } else if (titleLower.contains('social') || titleLower.contains('red')) {
      return Icons.people;
    } else if (titleLower.contains('clasic') ||
        titleLower.contains('classic') ||
        titleLower.contains('vintage')) {
      return Icons.library_music;
    } else if (titleLower.contains('email') ||
        titleLower.contains('mail') ||
        titleLower.contains('correo')) {
      return Icons.email;
    } else if (titleLower.contains('game') || titleLower.contains('juego')) {
      return Icons.videogame_asset;
    } else if (titleLower.contains('nature') ||
        titleLower.contains('natural')) {
      return Icons.nature;
    } else if (titleLower.contains('electronic') ||
        titleLower.contains('digital')) {
      return Icons.computer;
    } else {
      return Icons.music_note; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getCategoryIcon(),
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
