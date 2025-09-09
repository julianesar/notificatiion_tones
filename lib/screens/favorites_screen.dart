import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/favorites/presentation/providers/favorites_provider.dart';
import '../features/favorites/domain/entities/favorite.dart';
import '../features/tones/presentation/pages/tone_player_page.dart';
import '../features/tones/domain/entities/tone.dart';
import '../shared/widgets/tone_card_widget.dart';
import '../shared/widgets/share_options_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload favorites when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FavoritesProvider>().loadFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              if (favoritesProvider.favorites.isEmpty) return const SizedBox();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: 'Compartir favoritos',
                    onPressed: () => _showShareFavorites(context, favoritesProvider.favorites),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: 'Limpiar favoritos',
                    onPressed: () => _showClearAllDialog(context),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoritesProvider.errorMessage != null) {
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
                    'Error al cargar favoritos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      favoritesProvider.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => favoritesProvider.loadFavorites(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (favoritesProvider.favorites.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sin favoritos aún',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Los tonos que marques como favoritos aparecerán aquí',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => favoritesProvider.loadFavorites(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoritesProvider.favorites.length,
              itemBuilder: (context, index) {
                final favorite = favoritesProvider.favorites[index];
                return ToneCardWidget(
                  key: ValueKey(favorite.toneId),
                  toneId: favorite.toneId,
                  title: favorite.title,
                  url: favorite.url,
                  subtitle: 'Agregado: ${_formatDate(favorite.createdAt)}',
                  requiresAttribution: favorite.requiresAttribution,
                  attributionText: favorite.attributionText,
                  onTap: () => _openPlayer(context, favorite),
                  showFavoriteButton: true,
                  showDeleteButtonInTrailing: false,
                  showOpenPlayerOption: true,
                  showDownloadOption: true,
                  showShareOption: true,
                  showDeleteOption: false,
                  showAttributionOption: true,
                );
              },
            ),
          );
        },
      ),
    );
  }


  void _openPlayer(BuildContext context, Favorite favorite) {
    final tone = Tone(
      id: favorite.toneId,
      title: favorite.title,
      url: favorite.url,
      requiresAttribution: favorite.requiresAttribution,
      attributionText: favorite.attributionText,
    );

    final favoritesProvider = context.read<FavoritesProvider>();
    final favoritesList = favoritesProvider.favorites.map((fav) => Tone(
      id: fav.toneId,
      title: fav.title,
      url: fav.url,
      requiresAttribution: fav.requiresAttribution,
      attributionText: fav.attributionText,
    )).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TonePlayerPage(
          tone: tone,
          categoryTitle: 'Favoritos',
          tones: favoritesList,
        ),
      ),
    );
  }


  void _showShareFavorites(BuildContext context, List<Favorite> favorites) {
    if (favorites.isEmpty) return;

    // Convert favorites to Tone entities
    final tones = favorites.map((favorite) => Tone(
      id: favorite.toneId,
      title: favorite.title,
      url: favorite.url,
      requiresAttribution: favorite.requiresAttribution,
      attributionText: favorite.attributionText,
    )).toList();

    // Show the share options modal
    context.showShareOptionsModal(
      tones: tones,
      collectionName: 'Mis Favoritos',
      showShareApp: true,
      showShareCollection: true,
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar favoritos'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final favoritesProvider = context.read<FavoritesProvider>();
              
              try {
                await favoritesProvider.clearAllFavorites();
                if (context.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Todos los favoritos eliminados'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  final theme = Theme.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Error al eliminar favoritos: $e')),
                        ],
                      ),
                      backgroundColor: theme.colorScheme.error,
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar todos'),
          ),
        ],
      ),
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Hace un momento';
    }
  }
}