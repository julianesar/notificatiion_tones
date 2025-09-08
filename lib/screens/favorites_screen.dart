import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/favorites/presentation/providers/favorites_provider.dart';
import '../features/favorites/domain/entities/favorite.dart';
import '../features/tones/presentation/pages/tone_player_page.dart';
import '../features/tones/domain/entities/tone.dart';
import '../core/services/audio_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> 
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, bool> _removingFavorites = {};

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
  void dispose() {
    // Dispose all animation controllers
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    super.dispose();
  }

  AnimationController _getAnimationController(String favoriteId) {
    if (!_animationControllers.containsKey(favoriteId)) {
      _animationControllers[favoriteId] = AnimationController(
        duration: const Duration(milliseconds: 400),
        reverseDuration: const Duration(milliseconds: 300),
        vsync: this,
      )..forward();
    }
    return _animationControllers[favoriteId]!;
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
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Limpiar favoritos',
                onPressed: () => _showClearAllDialog(context),
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
                return _buildAnimatedFavoriteCard(context, favorite, favoritesProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedFavoriteCard(BuildContext context, Favorite favorite, FavoritesProvider favoritesProvider) {
    final animationController = _getAnimationController(favorite.toneId);
    final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticOut),
    );
    final slideAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic),
    );
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeIn),
    );

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final isRemoving = _removingFavorites[favorite.toneId] ?? false;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: isRemoving 
                ? Colors.red.withValues(alpha: 0.05) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: _buildFavoriteCard(context, favorite, favoritesProvider),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteCard(BuildContext context, Favorite favorite, FavoritesProvider favoritesProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Consumer<AudioService>(
        builder: (context, audioService, child) {
          final isPlaying = audioService.isTonePlaying(favorite.toneId);
          final isAudioLoading = audioService.isLoading && audioService.currentlyPlayingId == favorite.toneId;

          return ListTile(
            leading: GestureDetector(
              onTap: () => _toggleAudioPlay(audioService, favorite),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isAudioLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          key: ValueKey(isPlaying ? 'stop' : 'play'),
                          color: Theme.of(context).primaryColor,
                        ),
                ),
              ),
            ),
            title: Text(
              favorite.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Agregado: ${_formatDate(favorite.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _getAnimationController(favorite.toneId),
                  builder: (context, child) {
                    final isRemoving = _removingFavorites[favorite.toneId] ?? false;
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: isRemoving ? 100 : 300),
                      tween: Tween<double>(begin: 0, end: isRemoving ? 1 : 0),
                      builder: (context, shakeValue, child) {
                        final shakeOffset = isRemoving 
                            ? (shakeValue * 2 - 1) * 2 * (1 - (shakeValue * 2 - 1).abs())
                            : 0.0;
                        
                        return Transform.translate(
                          offset: Offset(shakeOffset, 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            transform: Matrix4.identity()..scale(isRemoving ? 1.1 : 1.0),
                            child: IconButton(
                              onPressed: isRemoving ? null : () => _removeFavoriteWithAnimation(context, favorite, favoritesProvider),
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                                child: Icon(
                                  isRemoving ? Icons.favorite_border : Icons.favorite,
                                  key: ValueKey(isRemoving),
                                  color: isRemoving 
                                      ? Colors.orange.withValues(alpha: 0.7) 
                                      : Colors.red,
                                ),
                              ),
                              tooltip: isRemoving ? 'Eliminando...' : 'Quitar de favoritos',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  onPressed: () => _openPlayer(context, favorite),
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Abrir reproductor',
                ),
              ],
            ),
            onTap: () => _openPlayer(context, favorite),
          );
        },
      ),
    );
  }

  Future<void> _toggleAudioPlay(AudioService audioService, Favorite favorite) async {
    try {
      await audioService.toggleTone(favorite.toneId, favorite.url);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Error al reproducir audio: $e');
      }
    }
  }

  void _openPlayer(BuildContext context, Favorite favorite) {
    final tone = Tone(
      id: favorite.toneId,
      title: favorite.title,
      url: favorite.url,
      requiresAttribution: false,
    );

    final favoritesProvider = context.read<FavoritesProvider>();
    final favoritesList = favoritesProvider.favorites.map((fav) => Tone(
      id: fav.toneId,
      title: fav.title,
      url: fav.url,
      requiresAttribution: false,
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

  Future<void> _removeFavoriteWithAnimation(BuildContext context, Favorite favorite, FavoritesProvider favoritesProvider) async {
    // Step 1: Mark as removing and change icon
    setState(() {
      _removingFavorites[favorite.toneId] = true;
    });

    // Step 2: Wait a moment for the visual feedback
    await Future.delayed(const Duration(milliseconds: 600));

    // Step 3: Start slide out animation
    final animationController = _getAnimationController(favorite.toneId);
    await animationController.reverse();

    // Step 4: Actually remove from favorites
    try {
      await favoritesProvider.toggleFavoriteStatus(
        favorite.toneId,
        favorite.title,
        favorite.url,
      );
      
      // Clean up
      _removingFavorites.remove(favorite.toneId);
      _animationControllers.remove(favorite.toneId)?.dispose();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Eliminado de favoritos'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Reset state on error
      setState(() {
        _removingFavorites[favorite.toneId] = false;
      });
      animationController.forward();

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al eliminar favorito: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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