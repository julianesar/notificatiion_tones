import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/downloads_provider.dart';
import '../../../tones/domain/entities/tone.dart';

class DownloadButton extends StatefulWidget {
  final Tone tone;
  final VoidCallback? onDownloadStarted;
  final VoidCallback? onDownloadCompleted;
  final VoidCallback? onDownloadError;

  const DownloadButton({
    super.key,
    required this.tone,
    this.onDownloadStarted,
    this.onDownloadCompleted,
    this.onDownloadError,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    final downloadsProvider = context.read<DownloadsProvider>();
    
    // Feedback háptico e inmediato
    HapticFeedback.mediumImpact();
    
    // Animación de presión
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    // Iniciar animación de rotación para el estado de "iniciando"
    _rotationController.repeat();
    
    widget.onDownloadStarted?.call();
    
    try {
      final result = await downloadsProvider.downloadTone(widget.tone);
      
      // Parar rotación cuando la descarga real comience o termine
      _rotationController.stop();
      _rotationController.reset();
      
      if (result.isSuccess) {
        // Feedback háptico de éxito
        HapticFeedback.lightImpact();
        widget.onDownloadCompleted?.call();
      } else {
        // Feedback háptico de error
        HapticFeedback.heavyImpact();
        widget.onDownloadError?.call();
      }
    } catch (e) {
      _rotationController.stop();
      _rotationController.reset();
      HapticFeedback.heavyImpact();
      widget.onDownloadError?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadsProvider>(
      builder: (context, downloadsProvider, child) {
        final isInitiating = downloadsProvider.isInitiatingDownload(widget.tone.id);
        final isDownloading = downloadsProvider.isDownloading(widget.tone.id);
        final isDownloaded = downloadsProvider.isDownloaded(widget.tone.id);
        final progress = downloadsProvider.getDownloadProgress(widget.tone.id);
        
        // Parar rotación si ya no está iniciando y tampoco descargando
        if (!isInitiating && !isDownloading && _rotationController.isAnimating) {
          _rotationController.stop();
          _rotationController.reset();
        }
        
        Widget iconWidget;
        String tooltipText;
        VoidCallback? onTap;
        
        if (isDownloaded) {
          iconWidget = Icon(
            Icons.download_done,
            color: Theme.of(context).colorScheme.primary,
          );
          tooltipText = 'Descargado';
          onTap = null;
        } else if (isDownloading && !isInitiating) {
          // Descarga activa con progreso
          iconWidget = Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (progress > 0)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          );
          tooltipText = 'Descargando... ${(progress * 100).toInt()}%';
          onTap = () => downloadsProvider.cancelDownload(widget.tone.id);
        } else if (isInitiating) {
          // Estado inicial de "preparando descarga"
          iconWidget = AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2.0 * 3.14159,
                child: Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            },
          );
          tooltipText = 'Preparando descarga...';
          onTap = () => downloadsProvider.cancelDownload(widget.tone.id);
        } else {
          // Estado normal - disponible para descarga
          iconWidget = const Icon(Icons.download);
          tooltipText = 'Descargar';
          onTap = _handleDownload;
        }
        
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isDownloaded 
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : (isDownloading || isInitiating)
                          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Tooltip(
                        message: tooltipText,
                        child: iconWidget,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DownloadListTile extends StatelessWidget {
  final Tone tone;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final VoidCallback? onTap;

  const DownloadListTile({
    super.key,
    required this.tone,
    this.leading,
    this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadsProvider>(
      builder: (context, downloadsProvider, child) {
        final isInitiating = downloadsProvider.isInitiatingDownload(tone.id);
        final isDownloading = downloadsProvider.isDownloading(tone.id);
        final isDownloaded = downloadsProvider.isDownloaded(tone.id);
        final progress = downloadsProvider.getDownloadProgress(tone.id);
        
        Widget leadingIcon = leading ?? const Icon(Icons.download);
        String titleText = 'Descargar';
        VoidCallback? tileTap = onTap;
        
        if (isDownloaded) {
          leadingIcon = Icon(
            Icons.download_done,
            color: Theme.of(context).colorScheme.primary,
          );
          titleText = 'Descargado';
          tileTap = null;
        } else if (isDownloading && !isInitiating) {
          leadingIcon = SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (progress > 0)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          );
          titleText = 'Descargando... ${(progress * 100).toInt()}%';
          tileTap = () {
            HapticFeedback.mediumImpact();
            downloadsProvider.cancelDownload(tone.id);
          };
        } else if (isInitiating) {
          leadingIcon = SizedBox(
            width: 24,
            height: 24,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2.0 * 3.14159,
                  child: Icon(
                    Icons.download,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          );
          titleText = 'Preparando descarga...';
          tileTap = () {
            HapticFeedback.mediumImpact();
            downloadsProvider.cancelDownload(tone.id);
          };
        }
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDownloaded 
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1)
                : (isDownloading || isInitiating)
                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: leadingIcon,
            title: title ?? Text(titleText),
            subtitle: subtitle,
            onTap: tileTap != null ? () {
              HapticFeedback.selectionClick();
              tileTap!();
            } : null,
          ),
        );
      },
    );
  }
}