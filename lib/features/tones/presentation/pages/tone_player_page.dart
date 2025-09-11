import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/tone.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/download_flow_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/ringtone_management_service.dart';
import '../../../../core/services/ringtone_configuration_service.dart';
import '../../../../core/services/permissions_service.dart';
import '../../../../shared/widgets/system_settings_permission_dialog.dart';
import '../../../../core/di/service_locator.dart';
import '../../../downloads/presentation/providers/downloads_provider.dart';
import '../../../downloads/domain/entities/download_info.dart';
import '../../../../core/navigation/navigation_service.dart';

class TonePlayerPage extends StatefulWidget {
  final Tone tone;
  final String categoryTitle;
  final List<Tone> tones;
  final bool isFromDownloads;

  const TonePlayerPage({
    super.key,
    required this.tone,
    required this.categoryTitle,
    required this.tones,
    this.isFromDownloads = false,
  });

  @override
  State<TonePlayerPage> createState() => _TonePlayerPageState();
}

class _TonePlayerPageState extends State<TonePlayerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Tone _currentTone;
  int _currentIndex = 0;
  bool _isLocalLoading = false;

  @override
  void initState() {
    super.initState();
    _currentTone = widget.tone;
    _currentIndex = widget.tones.indexWhere(
      (tone) => tone.id == widget.tone.id,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    final audioService = context.read<AudioService>();
    setState(() {
      _isLocalLoading = true;
    });

    try {
      await audioService.toggleTone(_currentTone.id, _currentTone.url);
    } catch (e) {
      _showErrorSnackBar('Error al reproducir audio: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLocalLoading = false;
        });
      }
    }
  }

  void _playPreviousTone() async {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentTone = widget.tones[_currentIndex];
        _isLocalLoading = true;
      });

      final audioService = context.read<AudioService>();
      try {
        await audioService.playTone(_currentTone.id, _currentTone.url);
      } catch (e) {
        _showErrorSnackBar('Error al reproducir audio: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLocalLoading = false;
          });
        }
      }
    }
  }

  void _playNextTone() async {
    if (_currentIndex < widget.tones.length - 1) {
      setState(() {
        _currentIndex++;
        _currentTone = widget.tones[_currentIndex];
        _isLocalLoading = true;
      });

      final audioService = context.read<AudioService>();
      try {
        await audioService.playTone(_currentTone.id, _currentTone.url);
      } catch (e) {
        _showErrorSnackBar('Error al reproducir audio: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLocalLoading = false;
          });
        }
      }
    }
  }

  bool _hasPrevious() {
    return _currentIndex > 0;
  }

  bool _hasNext() {
    return _currentIndex < widget.tones.length - 1;
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _downloadToneWithFeedback() async {
    await DownloadFlowService.downloadToneWithPermissions(
      context: context,
      toneId: _currentTone.id,
      title: _currentTone.title,
      url: _currentTone.url,
      requiresAttribution: _currentTone.requiresAttribution,
      attributionText: _currentTone.attributionText,
    );
  }

  Future<void> _downloadTone() async {
    await DownloadFlowService.downloadToneWithPermissionsAndConfigure(
      context: context,
      toneId: _currentTone.id,
      title: _currentTone.title,
      url: _currentTone.url,
      requiresAttribution: _currentTone.requiresAttribution,
      attributionText: _currentTone.attributionText,
      onDownloadSuccess: _showRingtoneConfigurationModal,
    );
  }

  // Professional method to wait for user to return and verify permission status
  Future<bool> _waitForPermissionAndVerify() async {
    bool permissionGranted = false;
    int attempts = 0;
    const maxAttempts = 15; // Give user more time (15 seconds)

    // Show professional waiting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Configurando Permisos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Esperando que actives el permiso "Modificar configuración del sistema" en la configuración de Android.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Vuelve a la app cuando hayas activado el permiso.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );

    // Monitor permission status while user is in system settings
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      attempts++;

      final hasPermission = await sl<RingtoneConfigurationService>()
          .hasSystemSettingsPermission();
      print(
        'DEBUG: Permission check attempt $attempts/$maxAttempts: $hasPermission',
      );

      if (hasPermission) {
        print(
          'DEBUG: Permission granted! User successfully activated the permission.',
        );
        permissionGranted = true;
        break;
      }
    }

    // Close the waiting dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Handle the result professionally
    if (permissionGranted) {
      print(
        'DEBUG: Permission verification successful - proceeding with configuration',
      );
      _showSnackBar(context, '✓ Permiso activado correctamente');
      return true;
    } else {
      print(
        'DEBUG: Permission verification failed - user did not activate permission',
      );
      await _showPermissionNotActivatedDialog();
      return false;
    }
  }

  // Professional dialog when user returns without activating permission
  Future<void> _showPermissionNotActivatedDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Permiso No Activado'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No se detectó que el permiso "Modificar configuración del sistema" haya sido activado.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Para configurar tonos personalizados necesitas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Ir a Configuración de Android'),
              Text('• Buscar esta aplicación'),
              Text('• Activar "Modificar configuración del sistema"'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Puedes intentar configurar el tono nuevamente después de activar el permiso.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRingtoneConfigurationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Configurar "${_currentTone.title}"',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Selecciona cómo quieres usar este tono',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.phone, color: colorScheme.primary),
                title: const Text('Tono de llamada'),
                subtitle: const Text(
                  'Configurar como tono principal de llamadas',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _configureAsCallRingtone();
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications, color: colorScheme.primary),
                title: const Text('Tono de notificación'),
                subtitle: const Text('Configurar como tono de notificaciones'),
                onTap: () {
                  Navigator.pop(context);
                  _configureAsNotificationRingtone();
                },
              ),
              ListTile(
                leading: Icon(Icons.alarm, color: colorScheme.primary),
                title: const Text('Tono de alarma'),
                subtitle: const Text('Configurar como tono de alarmas'),
                onTap: () {
                  Navigator.pop(context);
                  _configureAsAlarmRingtone();
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: colorScheme.primary),
                title: const Text('Tono de contacto'),
                subtitle: const Text('Asignar a un contacto específico'),
                onTap: () {
                  Navigator.pop(context);
                  _configureAsContactRingtone();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Method to check write settings permission and handle permission flow
  Future<bool> _checkAndRequestWriteSettingsPermission() async {
    final hasPermission = await sl<RingtoneConfigurationService>()
        .hasSystemSettingsPermission();
    print('DEBUG: hasSystemSettingsPermission = $hasPermission');

    if (hasPermission) {
      return true; // Already has permission, proceed with configuration
    }

    // Show permission dialog
    final permissionsService = sl<PermissionsService>();
    final permissionMessage = await permissionsService
        .getSystemSettingsPermissionMessage();

    final bool? userAccepted = await SystemSettingsPermissionDialog.show(
      context: context,
      title: 'Permiso Requerido',
      message: permissionMessage,
      onContinue: () async {
        await sl<RingtoneConfigurationService>()
            .requestSystemSettingsPermission();
      },
    );

    if (userAccepted != true) {
      _showSnackBar(context, 'Se requiere permiso para configurar tonos');
      return false;
    }

    // User accepted - wait for them to return from settings and verify permission
    print('DEBUG: Waiting for user to return from system settings');
    final permissionResult = await _waitForPermissionAndVerify();

    return permissionResult;
  }

  // New separate configure methods that check permissions first
  Future<void> _configureAsCallRingtone() async {
    // First check if we have write settings permission
    final hasPermission = await _checkAndRequestWriteSettingsPermission();
    if (!hasPermission) return; // User denied permission or couldn't grant it

    // If we have permission, proceed to configure the downloaded ringtone
    await _configureDownloadedRingtone(
      actionName: 'tono de llamada',
      configurationFunction: (context, filePath) async {
        final service = sl<RingtoneManagementService>();
        return await service.setAsCallRingtone(
          context,
          filePath,
          _currentTone.title,
        );
      },
    );
  }

  Future<void> _configureAsNotificationRingtone() async {
    // First check if we have write settings permission
    final hasPermission = await _checkAndRequestWriteSettingsPermission();
    if (!hasPermission) return; // User denied permission or couldn't grant it

    // If we have permission, proceed to configure the downloaded ringtone
    await _configureDownloadedRingtone(
      actionName: 'tono de notificación',
      configurationFunction: (context, filePath) async {
        final service = sl<RingtoneManagementService>();
        return await service.setAsNotificationRingtone(
          context,
          filePath,
          _currentTone.title,
        );
      },
    );
  }

  Future<void> _configureAsAlarmRingtone() async {
    // First check if we have write settings permission
    final hasPermission = await _checkAndRequestWriteSettingsPermission();
    if (!hasPermission) return; // User denied permission or couldn't grant it

    // If we have permission, proceed to configure the downloaded ringtone
    await _configureDownloadedRingtone(
      actionName: 'tono de alarma',
      configurationFunction: (context, filePath) async {
        final service = sl<RingtoneManagementService>();
        return await service.setAsAlarmRingtone(
          context,
          filePath,
          _currentTone.title,
        );
      },
    );
  }

  Future<void> _configureAsContactRingtone() async {
    // First check if we have write settings permission
    final hasPermission = await _checkAndRequestWriteSettingsPermission();
    if (!hasPermission) return; // User denied permission or couldn't grant it

    // If we have permission, proceed to configure the downloaded ringtone
    await _configureDownloadedRingtone(
      actionName: 'tono de contacto',
      configurationFunction: (context, filePath) async {
        final service = sl<RingtoneManagementService>();
        return await service.setAsContactRingtone(
          context,
          filePath,
          _currentTone.title,
        );
      },
    );
  }

  // Method to configure downloaded ringtone (assumes permission is already granted)
  Future<void> _configureDownloadedRingtone({
    required String actionName,
    required Future<RingtoneConfigurationResult> Function(BuildContext, String)
    configurationFunction,
  }) async {
    try {
      // Get the downloaded file path directly from the provider
      final downloadsProvider = context.read<DownloadsProvider>();

      // Check if the current tone is downloaded
      if (!downloadsProvider.isDownloaded(_currentTone.id)) {
        _showSnackBar(
          context,
          'Archivo no encontrado. Descarga el archivo primero.',
        );
        return;
      }

      // Debug: Check what's in the downloads map
      print('DEBUG: Looking for tone ID: ${_currentTone.id}');
      print(
        'DEBUG: Available download IDs: ${downloadsProvider.downloads.keys.toList()}',
      );
      print('DEBUG: Downloads map content:');
      downloadsProvider.downloads.forEach((key, value) {
        print(
          '  ID: $key -> fileName: ${value.fileName}, localPath: ${value.localPath}, status: ${value.status}',
        );
      });

      // Get the download info by searching for matching fileName (since download.id != tone.id)
      DownloadInfo? downloadInfo;
      for (final download in downloadsProvider.downloads.values) {
        if (download.fileName.contains(_currentTone.id) && download.status == DownloadStatus.completed) {
          downloadInfo = download;
          break;
        }
      }
      if (downloadInfo == null) {
        _showSnackBar(
          context,
          'Error: No se encontró el archivo descargado para el ID: ${_currentTone.id}',
        );
        return;
      }

      if (downloadInfo.localPath.isEmpty) {
        _showSnackBar(
          context,
          'Error: La ruta del archivo descargado está vacía.',
        );
        return;
      }

      final filePath = downloadInfo.localPath;
      print('DEBUG: Using direct file path: $filePath');

      // Configure the ringtone (permission already verified)
      _showSnackBar(context, 'Configurando $actionName...');
      final result = await configurationFunction(context, filePath);

      if (result.success) {
        _showSuccessMessage(actionName);
      } else if (result.requiresManualConfiguration) {
        _showConfigurationInstructionsDialog(
          result.errorMessage ?? 'Configuración manual requerida',
        );
      } else {
        _showSnackBar(context, 'Error: ${result.errorMessage}');
      }
    } catch (e) {
      _showSnackBar(
        context,
        'Error al configurar $actionName: ${e.toString()}',
      );
    }
  }

  // Professional success message for successful ringtone configuration
  void _showSuccessMessage(String actionName) {
    // Show snackbar first
    _showSnackBar(
      context,
      '✅ ${actionName.substring(0, 1).toUpperCase()}${actionName.substring(1)} configurado exitosamente',
    );

    // Show professional success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('¡Configuración Exitosa!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El tono "${_currentTone.title}" se ha configurado correctamente como $actionName.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los cambios se aplicaron inmediatamente. Ya puedes usar tu nuevo tono personalizado.',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Excelente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfigurationInstructionsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración Manual Requerida'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _seekTo(double value) async {
    final audioService = context.read<AudioService>();
    final duration = audioService.duration;
    if (duration != null) {
      final position = Duration(
        milliseconds: (value * duration.inMilliseconds).round(),
      );
      await audioService.seekTo(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        title: Text(
          'Reproductor',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showOptionsMenu(context),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Album Art / Visualization
              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.8),
                          colorScheme.secondary.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * 3.14159,
                          child: Icon(
                            Icons.audiotrack,
                            size: 120,
                            color: colorScheme.onPrimary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Song Info
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Text(
                      _currentTone.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.categoryTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Progress Bar
              Consumer<AudioService>(
                builder: (context, audioService, child) {
                  final duration = audioService.duration ?? Duration.zero;
                  final position = audioService.position;
                  final progress = audioService.progress;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor:
                              colorScheme.surfaceContainerHighest,
                          thumbColor: colorScheme.primary,
                          overlayColor: colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: duration.inMilliseconds > 0
                              ? _seekTo
                              : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              audioService.formatDuration(position),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              audioService.formatDuration(duration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 30),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _hasPrevious() ? _playPreviousTone : null,
                    icon: Icon(
                      Icons.skip_previous,
                      size: 32,
                      color: _hasPrevious()
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  Consumer<AudioService>(
                    builder: (context, audioService, child) {
                      final isCurrentTonePlaying = audioService.isTonePlaying(
                        _currentTone.id,
                      );
                      final isLoading =
                          _isLocalLoading ||
                          (audioService.isLoading &&
                              audioService.currentlyPlayingId ==
                                  _currentTone.id);

                      // Control animation based on audio service state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          if (isCurrentTonePlaying &&
                              !_rotationController.isAnimating) {
                            _rotationController.repeat();
                            // Clear local loading when audio starts playing
                            if (_isLocalLoading) {
                              setState(() {
                                _isLocalLoading = false;
                              });
                            }
                          } else if (!isCurrentTonePlaying &&
                              _rotationController.isAnimating) {
                            _rotationController.stop();
                          }
                        }
                      });

                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: isLoading ? null : _togglePlayPause,
                          icon: isLoading
                              ? SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  isCurrentTonePlaying
                                      ? Icons.stop
                                      : Icons.play_arrow,
                                  size: 40,
                                  color: colorScheme.onPrimary,
                                ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: _hasNext() ? _playNextTone : null,
                    icon: Icon(
                      Icons.skip_next,
                      size: 32,
                      color: _hasNext()
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Additional Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Favorite Button
                  IconButton(
                    onPressed: () {
                      // TODO: Implement favorite functionality
                    },
                    icon: Icon(
                      Icons.favorite_border,
                      size: 28,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // Configure Sound Button
                  IconButton(
                    onPressed: () async {
                      await _downloadTone();
                    },
                    icon: Icon(
                      Icons.settings,
                      size: 28,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // Share Button
                  IconButton(
                    onPressed: () {
                      // TODO: Implement share functionality
                    },
                    icon: Icon(
                      Icons.share,
                      size: 28,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
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
              if (!widget.isFromDownloads)
                Consumer<DownloadsProvider>(
                  builder: (context, downloadsProvider, child) {
                    final isDownloaded = downloadsProvider.isDownloaded(
                      _currentTone.id,
                    );
                    final isDownloading = downloadsProvider.isDownloading(
                      _currentTone.id,
                    );

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
                              NavigationService.instance.navigateToDownloads();
                            }
                          : isDownloading
                          ? null
                          : () async {
                              Navigator.pop(context);
                              // Usar un pequeño delay para permitir que el modal se cierre completamente
                              await Future.delayed(
                                const Duration(milliseconds: 100),
                              );
                              if (mounted) {
                                await _downloadToneWithFeedback();
                              }
                            },
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartir'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.shareToneEntity(
                      tone: _currentTone,
                      additionalMessage:
                          'Desde la categoría: ${widget.categoryTitle}',
                    );

                    _showSnackBar(
                      context,
                      'Compartiendo "${_currentTone.title}"',
                    );
                  } catch (e) {
                    _showSnackBar(
                      context,
                      'Error al compartir: ${e.toString()}',
                    );
                  }
                },
              ),
              if (_currentTone.requiresAttribution &&
                  _currentTone.attributionText != null) ...[
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Información de atribución'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAttributionDialog(context);
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

  void _showAttributionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de atribución'),
        content: Text(
          _currentTone.attributionText ?? 'Sin información disponible',
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
