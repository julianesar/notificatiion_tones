import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/icon_colors.dart';

class ToneCardWidget extends StatefulWidget {
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
    this.onDelete,
  });

  @override
  State<ToneCardWidget> createState() => _ToneCardWidgetState();
}

class _ToneCardWidgetState extends State<ToneCardWidget> {
  bool _isLocalLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(widget.toneId),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Consumer<AudioService>(
        builder: (context, audioService, child) {
          final isPlaying = audioService.isTonePlaying(widget.toneId);
          final isAudioLoading = _isLocalLoading ||
              (audioService.isLoading &&
                  audioService.currentlyPlayingId == widget.toneId);

          // Clear local loading when audio starts playing
          if (isPlaying && _isLocalLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLocalLoading = false;
                });
              }
            });
          }

          return InkWell(
            onTap: () => _openFullScreenPlayer(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleAudioPlay(context, audioService),
                    child: Container(
                      key: ValueKey('${widget.toneId}_button'),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.iconPrimary.withValues(alpha: 0.1),
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
                                  color: context.iconPrimary,
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.stop : Icons.play_arrow,
                                key: ValueKey(isPlaying ? 'stop' : 'play'),
                                color: context.iconPrimary,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.showDeleteButtonInTrailing && widget.onDelete != null)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onDelete!();
                      },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Eliminar',
                      color: Theme.of(context).colorScheme.error,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.chevron_right,
                        color: context.iconDisabled,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleAudioPlay(
    BuildContext context,
    AudioService audioService,
  ) async {
    setState(() {
      _isLocalLoading = true;
    });

    try {
      await audioService.toggleTone(widget.toneId, widget.url);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error al reproducir audio: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocalLoading = false;
        });
      }
    }
  }

  void _openFullScreenPlayer(BuildContext context) {
    if (widget.onTap != null) {
      widget.onTap!();
    }
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

}
