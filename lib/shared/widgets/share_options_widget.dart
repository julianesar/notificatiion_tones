import 'package:flutter/material.dart';
import '../../core/services/share_service.dart';
import '../../features/tones/domain/entities/tone.dart';
import '../../core/theme/icon_colors.dart';

/// Reusable widget for common sharing options
/// Provides consistent sharing UI across the app
class ShareOptionsWidget extends StatelessWidget {
  final List<Tone>? tones;
  final String? collectionName;
  final bool showShareApp;
  final bool showShareCollection;
  final VoidCallback? onShareCompleted;
  
  const ShareOptionsWidget({
    super.key,
    this.tones,
    this.collectionName,
    this.showShareApp = false,
    this.showShareCollection = false,
    this.onShareCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showShareCollection && tones != null && tones!.isNotEmpty) ...[
          ListTile(
            leading: Icon(Icons.share_outlined, color: context.iconSecondary),
            title: Text('Compartir ${collectionName ?? 'colección'} (${tones!.length} tonos)'),
            subtitle: const Text('Comparte todos los tonos de esta colección'),
            onTap: () async {
              try {
                await ShareService.instance.shareMultipleTones(
                  tones: tones!,
                  collectionName: collectionName,
                  sharePositionOrigin: context.sharePositionOrigin,
                );
                
                onShareCompleted?.call();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Compartiendo ${collectionName ?? 'colección'} de ${tones!.length} tonos'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al compartir: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
        ],
        
        if (showShareApp) ...[
          ListTile(
            leading: Icon(Icons.mobile_friendly, color: context.iconSecondary),
            title: const Text('Compartir aplicación'),
            subtitle: const Text('Recomienda Sonidos de Notificaciones a tus amigos'),
            onTap: () async {
              try {
                await ShareService.instance.shareApp(
                  sharePositionOrigin: context.sharePositionOrigin,
                );
                
                onShareCompleted?.call();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Gracias por compartir nuestra app!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al compartir: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ],
    );
  }
}

/// Extension method to show share options modal
extension ShareOptionsModalExtension on BuildContext {
  /// Show a modal with sharing options
  Future<void> showShareOptionsModal({
    List<Tone>? tones,
    String? collectionName,
    bool showShareApp = true,
    bool showShareCollection = true,
  }) async {
    return showModalBottomSheet<void>(
      context: this,
      backgroundColor: Theme.of(this).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  'Opciones para compartir',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Share options
                ShareOptionsWidget(
                  tones: tones,
                  collectionName: collectionName,
                  showShareApp: showShareApp,
                  showShareCollection: showShareCollection && tones != null && tones.isNotEmpty,
                  onShareCompleted: () {
                    Navigator.of(context).pop();
                  },
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}