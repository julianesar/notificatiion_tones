import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/icon_colors.dart';
import 'play_stop_button.dart';
import 'custom_snackbar.dart';

class ToneCardWidget extends StatefulWidget {
  final String toneId;
  final String title;
  final String url;
  final String subtitle;
  final double? duration;
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
    this.duration,
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

  String _formatDuration(double seconds) {
    // Ensure minimum duration of 1 second to avoid showing 00:00
    final adjustedSeconds = seconds < 1 ? 1.0 : seconds;
    final minutes = (adjustedSeconds / 60).floor();
    final remainingSeconds = (adjustedSeconds % 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(widget.toneId),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  PlayStopButton(
                    key: ValueKey('${widget.toneId}_button'),
                    isPlaying: isPlaying,
                    isLoading: isAudioLoading,
                    onPressed: () => _toggleAudioPlay(context, audioService),
                    size: 40,
                    borderRadius: 8,
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.duration != null
                                ? _formatDuration(widget.duration!)
                                : widget.subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
                      icon: const Icon(Icons.delete),
                      tooltip: 'Eliminar',
                      color: context.iconTrashRed,
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
    CustomSnackBar.show(
      context,
      message: message,
    );
  }


  void _showErrorSnackBar(BuildContext context, String message) {
    CustomSnackBar.showError(
      context,
      message: message,
      duration: const Duration(seconds: 3),
    );
  }

}
