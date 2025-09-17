import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/category_icon.dart';
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
    return Consumer<CategoriesProvider>(
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
          return Column(
            children: [
              // Título "Categorías" alineado a la izquierda
              Padding(
                padding: const EdgeInsets.only(top: 32, right: 24, left: 24, bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Categorías',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Grid de categorías
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.load(),
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  iconUrl: category.iconUrl,
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
                ),
              ),
            ],
          );
        },
      );
  }
}

/// Tarjeta estilo "card + inkWell" (patrón de code .txt) - shadow dark
class _CategoryTile extends StatelessWidget {
  final String title;
  final String categoryId;
  final String? iconUrl;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.categoryId,
    this.iconUrl,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryIcon(
                iconUrl: iconUrl,
                title: title,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
