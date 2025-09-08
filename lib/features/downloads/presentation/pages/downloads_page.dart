import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/downloads_provider.dart';
import '../../domain/entities/download_info.dart';
import '../../../../shared/widgets/tone_card_widget.dart';
import '../../../tones/domain/entities/tone.dart';
import '../../../tones/presentation/pages/tone_player_page.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadsProvider>().loadDownloads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Descargas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _showStorageInfo(context),
            tooltip: 'Ubicación de archivos',
          ),
        ],
      ),
      body: Consumer<DownloadsProvider>(
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
                    'Error al cargar las descargas',
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
                    onPressed: provider.loadDownloads,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final downloads = provider.downloadsList;
          final activeDownloads = downloads
              .where((d) => 
                  d.status == DownloadStatus.downloading || 
                  d.status == DownloadStatus.waiting)
              .toList();
          final completedDownloads = downloads
              .where((d) => d.status == DownloadStatus.completed)
              .toList();

          if (downloads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined, 
                    size: 64, 
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay descargas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los tonos que descargues aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadDownloads,
            child: CustomScrollView(
              slivers: [
                // Active Downloads Section
                if (activeDownloads.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Descargando (${activeDownloads.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _ActiveDownloadTile(download: activeDownloads[index]),
                      ),
                      childCount: activeDownloads.length,
                    ),
                  ),
                ],
                
                // Completed Downloads Section
                if (completedDownloads.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16, 
                        activeDownloads.isNotEmpty ? 24 : 16, 
                        16, 
                        8
                      ),
                      child: Text(
                        'Completadas (${completedDownloads.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ToneCardWidget(
                          toneId: completedDownloads[index].localPath,
                          title: completedDownloads[index].fileName,
                          url: completedDownloads[index].localPath,
                          subtitle: 'Descargado ${_formatDate(completedDownloads[index].completedAt!)}',
                          requiresAttribution: completedDownloads[index].requiresAttribution,
                          attributionText: completedDownloads[index].attributionText,
                          showFavoriteButton: false,
                          showDeleteButtonInTrailing: true, // Mostrar botón de borrar directo en el trailing
                          // Modal options - mostrar todas las opciones aplicables
                          showOpenPlayerOption: true,
                          showDownloadOption: false, // Ya está descargado
                          showShareOption: true,
                          showDeleteOption: true,
                          showAttributionOption: true,
                          onTap: () => _openLocalPlayer(context, completedDownloads[index]),
                          onDelete: () => _confirmDelete(context, completedDownloads[index]),
                        ),
                      ),
                      childCount: completedDownloads.length,
                    ),
                  ),
                ],
                
                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStorageInfo(BuildContext context) {
    final provider = context.read<DownloadsProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_outlined),
            SizedBox(width: 8),
            Text('Ubicación de Archivos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tus tonos descargados se guardan en:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.storageLocation ?? 'Almacenamiento privado de la app',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Los archivos se guardan en la carpeta de Descargas del dispositivo para que puedas acceder a ellos fácilmente.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DownloadInfo download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Descarga'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${download.fileName}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              HapticFeedback.mediumImpact();
              final provider = context.read<DownloadsProvider>();
              final success = await provider.deleteDownload(download.localPath);
              
              if (mounted) {
                if (success) {
                  HapticFeedback.lightImpact();
                } else {
                  HapticFeedback.heavyImpact();
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? 'Descarga eliminada exitosamente' 
                        : 'Error al eliminar la descarga'
                    ),
                    backgroundColor: success 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'hace un momento';
    }
  }

  void _openLocalPlayer(BuildContext context, DownloadInfo download) {
    // Crear un objeto Tone temporal para el reproductor usando el archivo local
    final localTone = Tone(
      id: download.localPath, // Usar la ruta local como ID
      title: download.fileName,
      url: download.localPath, // URL apunta al archivo local
      requiresAttribution: download.requiresAttribution,
      attributionText: download.attributionText,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TonePlayerPage(
          tone: localTone,
          categoryTitle: 'Mis Descargas',
          tones: [localTone], // Lista con solo este tono
          isFromDownloads: true,
        ),
      ),
    );
  }
}

class _ActiveDownloadTile extends StatelessWidget {
  final DownloadInfo download;

  const _ActiveDownloadTile({required this.download});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  download.status == DownloadStatus.waiting
                      ? Icons.schedule
                      : Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    download.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (download.status == DownloadStatus.downloading)
                  Text(
                    '${(download.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: LinearProgressIndicator(
                value: download.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            if (download.totalBytes != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    download.status == DownloadStatus.waiting
                        ? 'En espera...'
                        : 'Descargando...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatBytes(download.downloadedBytes ?? 0, download.totalBytes!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatBytes(int downloaded, int total) {
    final downloadedMB = (downloaded / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = (total / (1024 * 1024)).toStringAsFixed(1);
    return '$downloadedMB MB / $totalMB MB';
  }
}