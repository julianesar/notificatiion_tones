import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tones_provider.dart';
import 'tone_player_page.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../../shared/widgets/tone_card_widget.dart';

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
                return ToneCardWidget(
                  toneId: tone.id,
                  title: tone.title,
                  url: tone.url,
                  subtitle: widget.title,
                  requiresAttribution: tone.requiresAttribution,
                  attributionText: tone.attributionText,
                  onTap: () => _openPlayer(context, tone),
                  showFavoriteButton: true,
                  showDeleteButtonInTrailing: false,
                );
              },
            ),
          );
        },
      ),
    );
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


}
