import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/download_flow_service.dart';
import '../../features/favorites/presentation/providers/favorites_provider.dart';
import '../../features/downloads/presentation/providers/downloads_provider.dart';
import '../../screens/main_screen.dart';

class ToneCardWidget extends StatelessWidget {
  final String toneId;
  final String title;
  final String url;
  final String subtitle;
  final bool? requiresAttribution;
  final String? attributionText;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final bool
  showDeleteButtonInTrailing; // Show delete button directly in trailing instead of favorites

  // Modal options - all configurable
  final bool showOpenPlayerOption;
  final bool showDownloadOption;
  final bool showShareOption;
  final bool showDeleteOption;
  final bool showAttributionOption;
  final VoidCallback? onDelete; // For downloads page

  const ToneCardWidget({
    super.key,
    required this.toneId,
    required this.title,
    required this.url,
    required this.subtitle,
    this.requiresAttribution,
    this.attributionText,
    this.onTap,
    this.showFavoriteButton = true,
    this.showDeleteButtonInTrailing = false,
    this.showOpenPlayerOption = true,
    this.showDownloadOption = true,
    this.showShareOption = true,
    this.showDeleteOption = false,
    this.showAttributionOption = true,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(toneId),
      margin: const EdgeInsets.only(bottom: 8),
      child: Consumer<AudioService>(
        builder: (context, audioService, child) {
          final isPlaying = audioService.isTonePlaying(toneId);
          final isAudioLoading =
              audioService.isLoading &&
              audioService.currentlyPlayingId == toneId;

          return ListTile(
            leading: GestureDetector(
              onTap: () => _toggleAudioPlay(context, audioService),
              child: Container(
                key: ValueKey('${toneId}_button'),
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
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showFavoriteButton && !showDeleteButtonInTrailing)
                  Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFavorite = favoritesProvider.isFavoriteSync(
                        toneId,
                      );
                      return IconButton(
                        onPressed: () => _toggleFavorite(context),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        tooltip: isFavorite
                            ? 'Quitar de favoritos'
                            : 'Agregar a favoritos',
                      );
                    },
                  ),
                if (showDeleteButtonInTrailing && onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete),
                    color: Theme.of(context).colorScheme.error,
                    tooltip: 'Eliminar',
                  ),
                IconButton(
                  onPressed: () => _showOptionsMenu(context),
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Opciones',
                ),
              ],
            ),
            onTap: onTap,
          );
        },
      ),
    );
  }

  Future<void> _toggleAudioPlay(
    BuildContext context,
    AudioService audioService,
  ) async {
    try {
      await audioService.toggleTone(toneId, url);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error al reproducir audio: $e');
      }
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final favoritesProvider = context.read<FavoritesProvider>();

    try {
      final isNowFavorite = await favoritesProvider.toggleFavoriteStatus(
        toneId,
        title,
        url,
        requiresAttribution: requiresAttribution ?? false,
        attributionText: attributionText,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowFavorite ? 'Agregado a favoritos' : 'Eliminado de favoritos',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error al cambiar favorito: $e');
      }
    }
  }

  void _showOptionsMenu(BuildContext context) {
    // Refrescar el estado de descargas antes de mostrar el modal
    context.read<DownloadsProvider>().refreshDownloadedFiles();
    
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
              if (showOpenPlayerOption && onTap != null)
                ListTile(
                  leading: const Icon(Icons.play_arrow),
                  title: const Text('Abrir reproductor'),
                  onTap: () {
                    Navigator.pop(context);
                    onTap!();
                  },
                ),
              if (showDownloadOption)
                Consumer<DownloadsProvider>(
                  builder: (context, downloadsProvider, child) {
                    final isDownloaded = downloadsProvider.isDownloaded(toneId);
                    final isDownloading = downloadsProvider.isDownloading(toneId);
                    
                    return ListTile(
                      leading: Icon(
                        isDownloaded 
                            ? Icons.download_done 
                            : isDownloading 
                                ? Icons.downloading 
                                : Icons.download,
                        color: isDownloaded 
                            ? Colors.green 
                            : isDownloading 
                                ? Colors.blue 
                                : null,
                      ),
                      title: Text(
                        isDownloaded 
                            ? 'Ya descargado' 
                            : isDownloading 
                                ? 'Descargando...' 
                                : 'Descargar',
                      ),
                      subtitle: isDownloaded 
                          ? const Text('Toca para ver descargas') 
                          : null,
                      enabled: !isDownloading,
                      onTap: isDownloaded 
                          ? () {
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainScreen(initialIndex: 2),
                                ),
                                (route) => route.isFirst,
                              );
                            }
                          : isDownloading 
                              ? null
                              : () async {
                                  // Cerrar el modal primero
                                  Navigator.pop(context);
                                  // Usar un pequeño delay para permitir que el modal se cierre completamente
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  if (context.mounted) {
                                    await DownloadFlowService.downloadToneWithPermissions(
                                      context: context,
                                      toneId: toneId,
                                      title: title,
                                      url: url,
                                      requiresAttribution: requiresAttribution,
                                      attributionText: attributionText,
                                    );
                                  }
                                },
                    );
                  },
                ),
              if (showShareOption)
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Compartir'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar(context, 'Compartiendo $title');
                  },
                ),
              if (showDeleteOption && onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Eliminar'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 100));
                    onDelete!();
                  },
                ),
              if (showAttributionOption &&
                  requiresAttribution == true &&
                  attributionText != null)
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Información de atribución'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAttributionDialog(context);
                  },
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAttributionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de atribución'),
        content: Text(attributionText ?? 'Sin información disponible'),
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
