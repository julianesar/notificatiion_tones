import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/tones_provider.dart';
import 'tone_player_page.dart';
import '../../../../core/services/audio_service.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../downloads/presentation/providers/downloads_provider.dart';
import '../../../downloads/domain/entities/download_result.dart';
import '../../../../screens/main_screen.dart';

class TonesPage extends StatefulWidget {
  final String categoryId;
  final String title;

  const TonesPage({super.key, required this.categoryId, required this.title});

  @override
  State<TonesPage> createState() => _TonesPageState();
}

class _TonesPageState extends State<TonesPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TonesProvider>().load(widget.categoryId);
      context.read<FavoritesProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Consumer<TonesProvider>(
        builder: (context, tonesProvider, child) {
          final tones = tonesProvider.getTonesForCategory(widget.categoryId);
          final isLoading = tonesProvider.isCategoryLoading(widget.categoryId);
          final hasError = tonesProvider.hasError;
          

          if (isLoading && tones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hasError && tones.isEmpty) {
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
                    'Error al cargar los tonos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      tonesProvider.errorMessage ?? 'Error desconocido',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => tonesProvider.retry(widget.categoryId),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (tones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay tonos disponibles',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => tonesProvider.load(widget.categoryId),
            child: ListView.builder(
              addAutomaticKeepAlives: false,
              padding: const EdgeInsets.all(16),
              itemCount:
                  tones.length +
                  (tonesProvider.hasMoreTones(widget.categoryId) ? 1 : 0),
              itemBuilder: (context, index) {
                // Mostrar indicador de carga al final si hay más tonos
                if (index == tones.length) {
                  if (isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () => tonesProvider.loadMore(widget.categoryId),
                          child: const Text('Cargar más'),
                        ),
                      ),
                    );
                  }
                }

                final tone = tones[index];
                return Card(
                  key: ValueKey(tone.id), // Add unique key for each card
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Consumer<AudioService>(
                    builder: (context, audioService, child) {
                      final isPlaying = audioService.isTonePlaying(tone.id);
                      final isAudioLoading = audioService.isLoading && audioService.currentlyPlayingId == tone.id;
                      
                      // Debug print
                      print('Card ${tone.id}: isPlaying=$isPlaying, isLoading=$isAudioLoading, currentId=${audioService.currentlyPlayingId}');
                      
                      return ListTile(
                        leading: GestureDetector(
                          onTap: () => _toggleAudioPlay(audioService, tone),
                          child: Container(
                            key: ValueKey('${tone.id}_button'), // Unique key for button
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
                          tone.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Consumer<FavoritesProvider>(
                              builder: (context, favoritesProvider, child) {
                                final isFavorite = favoritesProvider.isFavoriteSync(tone.id);
                                return IconButton(
                                  onPressed: () => _toggleFavorite(tone),
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : null,
                                  ),
                                  tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () => _showOptionsMenu(context, tone),
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Opciones',
                            ),
                          ],
                        ),
                        onTap: () => _openPlayer(context, tone),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleAudioPlay(AudioService audioService, tone) async {
    try {
      await audioService.toggleTone(tone.id, tone.url);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Error al reproducir audio: $e');
      }
    }
  }

  Future<void> _toggleFavorite(tone) async {
    final favoritesProvider = context.read<FavoritesProvider>();
    
    try {
      final isNowFavorite = await favoritesProvider.toggleFavoriteStatus(
        tone.id,
        tone.title,
        tone.url,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowFavorite
                  ? 'Agregado a favoritos'
                  : 'Eliminado de favoritos',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Error al cambiar favorito: $e');
      }
    }
  }

  void _openPlayer(BuildContext context, tone) {
    final tonesProvider = context.read<TonesProvider>();
    final tones = tonesProvider.getTonesForCategory(widget.categoryId);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TonePlayerPage(
          tone: tone,
          categoryTitle: widget.title,
          tones: tones,
        ),
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

  void _showOptionsMenu(BuildContext context, tone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Abrir reproductor'),
                onTap: () {
                  Navigator.pop(context);
                  _openPlayer(context, tone);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Descargar'),
                onTap: () async {
                  Navigator.pop(context);
                  // Usar un pequeño delay para permitir que el modal se cierre completamente
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (mounted) {
                    await _downloadToneWithStandardFeedback(tone);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartir'),
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar(context, 'Compartiendo ${tone.title}');
                },
              ),
              if (tone.requiresAttribution) ...[
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Información de atribución'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAttributionDialog(context, tone);
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _downloadToneWithStandardFeedback(tone) async {
    final downloadsProvider = context.read<DownloadsProvider>();
    
    // Mostrar mensaje inmediato de que la descarga ha comenzado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparando descarga de ${tone.title}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    try {
      final result = await downloadsProvider.downloadTone(tone);
      
      if (!mounted) return;
      
      if (result.isSuccess) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tone.title} descargado exitosamente'),
            backgroundColor: Colors.green[800],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialIndex: 2),
                  ),
                  (route) => route.isFirst,
                );
              },
            ),
          ),
        );
      } else {
        HapticFeedback.heavyImpact();
        String errorMessage = 'Error al descargar el tono';
        
        switch (result.type) {
          case DownloadResultType.networkError:
            errorMessage = 'Error de conexión. Verifica tu internet.';
            break;
          case DownloadResultType.storageError:
            errorMessage = 'Error de almacenamiento. Verifica los permisos.';
            break;
          case DownloadResultType.cancelled:
            errorMessage = 'Descarga cancelada';
            break;
          default:
            errorMessage = result.message ?? 'Error desconocido';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }


  void _showAttributionDialog(BuildContext context, tone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de atribución'),
        content: Text(
          tone.attributionText ?? 'Sin información disponible',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

}
