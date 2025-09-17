import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/tone.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/download_flow_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/ringtone_management_service.dart';
import '../../../../core/services/ringtone_configuration_service.dart';
import '../../../../core/services/permissions_service.dart';
import '../../../../core/services/media_store_service.dart';
import '../../../../core/services/filename_service.dart';
import '../../../../shared/widgets/system_settings_permission_dialog.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/icon_colors.dart';
import '../../../../shared/widgets/play_stop_button.dart';
import '../../../downloads/presentation/providers/downloads_provider.dart';
import '../../../downloads/domain/repositories/download_repository.dart';
import '../../../contacts/presentation/widgets/contact_picker_dialog.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

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
    with WidgetsBindingObserver {
  late Tone _currentTone;
  int _currentIndex = 0;
  bool _isLocalLoading = false;
  bool _pendingConfigurationModal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentTone = widget.tone;
    _currentIndex = widget.tones.indexWhere(
      (tone) => tone.id == widget.tone.id,
    );

    // Status bar style is now configured globally

    _initializeFavoriteStatus();
  }

  void _initializeFavoriteStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final favoritesProvider = context.read<FavoritesProvider>();
        favoritesProvider.checkFavoriteStatus(_currentTone.id);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // System UI overlay style is managed globally
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('DEBUG: App lifecycle state changed to: $state');

    if (state == AppLifecycleState.resumed && _pendingConfigurationModal) {
      print('DEBUG: App resumido con modal de configuración pendiente');

      // Mostrar modal con un pequeño delay para que la UI se estabilice
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _pendingConfigurationModal) {
          print('DEBUG: Mostrando modal de configuración pendiente');
          _pendingConfigurationModal = false;
          _showRingtoneConfigurationModal();
        }
      });
    }
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

      // Update favorite status for the new tone
      _initializeFavoriteStatus();

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

      // Update favorite status for the new tone
      _initializeFavoriteStatus();

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
      CustomSnackBar.showError(
        context,
        message: message,
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final favoritesProvider = context.read<FavoritesProvider>();

    try {
      final isNowFavorite = await favoritesProvider.toggleFavoriteStatus(
        _currentTone.id,
        _currentTone.title,
        _currentTone.url,
        requiresAttribution: _currentTone.requiresAttribution,
        attributionText: _currentTone.attributionText,
      );

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: isNowFavorite ? 'Agregado a favoritos' : 'Eliminado de favoritos',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al cambiar favorito: $e');
      }
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
    print('DEBUG: _downloadTone iniciado para: ${_currentTone.title}');
    print('DEBUG: Widget mounted antes de descarga: $mounted');

    await DownloadFlowService.downloadToneWithPermissionsAndConfigure(
      context: context,
      toneId: _currentTone.id,
      title: _currentTone.title,
      url: _currentTone.url,
      requiresAttribution: _currentTone.requiresAttribution,
      attributionText: _currentTone.attributionText,
      onDownloadSuccess: () {
        print(
          'DEBUG: onDownloadSuccess callback ejecutado, widget mounted: $mounted',
        );
        _showRingtoneConfigurationModalSafely();
      },
    );

    print('DEBUG: _downloadTone completado, widget mounted: $mounted');
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
              'Activa "Modificar configuración del sistema" en la configuración de tu dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Regresa cuando esté listo.',
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
                'El permiso "Modificar configuración del sistema" no está activado.',
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
                        'Intenta nuevamente después de activar el permiso.',
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

  void _showRingtoneConfigurationModalSafely() {
    print(
      'DEBUG: _showRingtoneConfigurationModalSafely called, widget mounted: $mounted',
    );

    if (mounted) {
      // Widget está montado - mostrar modal inmediatamente (caso normal)
      print('DEBUG: Widget mounted, mostrando modal inmediatamente');
      _showRingtoneConfigurationModal();
    } else {
      // Widget no está montado - caso muy raro que solo puede pasar con interrupciones de permisos
      print('DEBUG: Widget no mounted, marcando modal como pendiente');
      _pendingConfigurationModal = true;
    }
  }

  void _showRingtoneConfigurationModal() async {
    print('DEBUG: _showRingtoneConfigurationModal called, checking context...');

    if (!mounted) {
      print('DEBUG: Widget no montado, no se puede mostrar modal');
      return;
    }

    // Refresh downloads before showing the modal
    final downloadsProvider = context.read<DownloadsProvider>();
    await downloadsProvider.refreshDownloadedFiles();

    if (!mounted) {
      print('DEBUG: Widget desmontado después de refreshDownloadedFiles');
      return;
    }

    print(
      'DEBUG: Mostrando modal de configuración para: ${_currentTone.title}',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: SingleChildScrollView(
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                  leading: Icon(
                    Icons.notifications,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Tono de notificación'),
                  subtitle: const Text(
                    'Configurar como tono de notificaciones',
                  ),
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

    // Show contact picker dialog
    final selectedContact = await ContactPickerDialog.show(
      context: context,
      title: 'Seleccionar Contacto',
      subtitle:
          'Elige el contacto para asignar el tono "${_currentTone.title}"',
    );

    if (selectedContact == null) return; // User cancelled selection

    // Configure the downloaded ringtone for the selected contact
    await _configureDownloadedRingtone(
      actionName: 'tono de contacto para ${selectedContact.name}',
      configurationFunction: (context, filePath) async {
        final service = sl<RingtoneManagementService>();
        return await service.setAsContactRingtone(
          context,
          filePath,
          _currentTone.title,
          contactId: selectedContact.id,
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
      // Get the downloaded file path directly using the exact storage path
      final filePath = await _getDownloadedFilePath(
        _currentTone.id,
        _currentTone.title,
        _currentTone.url,
      );

      if (filePath == null) {
        _showSnackBar(
          context,
          'Archivo no encontrado. Descarga el archivo primero.',
        );
        return;
      }

      // Verify the file actually exists on disk
      final file = File(filePath);
      if (!await file.exists()) {
        _showSnackBar(
          context,
          'Error: El archivo descargado no existe en el dispositivo. Descarga nuevamente.',
        );
        return;
      }

      print('DEBUG: Using direct file path: $filePath');

      // Configure the ringtone (permission already verified)
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

  // Professional method to get the exact downloaded file path
  Future<String?> _getDownloadedFilePath(
    String toneId,
    String title,
    String url,
  ) async {
    try {
      // Method 1: Use the DownloadRepository's built-in method (most reliable)
      final downloadRepository = sl<DownloadRepository>();
      final repoPath = await downloadRepository.getDownloadedFilePath(toneId);

      if (repoPath != null) {
        final file = File(repoPath);
        if (await file.exists()) {
          print('DEBUG: Found file using repository method: $repoPath');
          return repoPath;
        }
      }

      // Method 2: Construct exact path using same logic as download
      final mediaStoreService = sl<MediaStoreService>();
      final publicAudioDir = await mediaStoreService.getPublicAudioDirectory();

      // Usar el servicio profesional de nomenclatura técnica (mismo que usa el download)
      final filenameService = sl<FilenameService>();
      final fileName = filenameService.generateTechnicalFilename(
        title: title,
        url: url,
        toneId: toneId,
      );
      final exactPath = '$publicAudioDir/Tonos/$fileName';

      print('DEBUG: Checking exact constructed path: $exactPath');

      // Check if file exists at exact location
      final exactFile = File(exactPath);
      if (await exactFile.exists()) {
        print('DEBUG: Found file using exact path construction');
        return exactPath;
      }

      print('DEBUG: File not found for toneId: $toneId');
      return null;
    } catch (e) {
      print('DEBUG: Error getting downloaded file path: $e');
      return null;
    }
  }

  // Método removido - ahora se usa FilenameService para consistencia

  // Professional success message for successful ringtone configuration
  void _showSuccessMessage(String actionName) {
    // Show only success dialog (no duplicate snackbar)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: colorScheme.primary, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('¡Configuración Exitosa!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El tono "${_currentTone.title}" se ha configurado correctamente como $actionName.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los cambios se aplicaron inmediatamente. Ya puedes usar tu nuevo tono personalizado.',
                        style: TextStyle(
                          color: Colors.white,
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
                  color: colorScheme.primary,
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
        title: const Text('Reproduciendo'),
        actions: _currentTone.requiresAttribution == true
            ? [
                IconButton(
                  onPressed: () => _showAttributionDialog(context),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Información de atribución',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Musical Note Icon with background - matching reference image
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = (constraints.maxWidth * 0.7).clamp(
                      200.0,
                      280.0,
                    );
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: context.iconPrimary.withValues(alpha: 0.1),
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
                      child: Center(
                        child: Icon(
                          Icons.notifications_active,
                          size: size * 0.4,
                          color: context.iconPrimary,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Track Title and Category - matching reference image
                Column(
                  children: [
                    Text(
                      _currentTone.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.categoryTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor: colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            thumbColor: colorScheme.primary,
                            overlayColor: colorScheme.primary.withValues(
                              alpha: 0.1,
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

                const SizedBox(height: 16),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous Button
                    IconButton(
                      onPressed: _hasPrevious() ? _playPreviousTone : null,
                      icon: Icon(
                        Icons.skip_previous,
                        size: 32,
                        color: _hasPrevious()
                            ? context.iconSecondary
                            : context.iconDisabled,
                      ),
                    ),

                    // Play/Pause Button
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

                        // Clear local loading when audio starts playing
                        if (isCurrentTonePlaying && _isLocalLoading) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _isLocalLoading = false;
                              });
                            }
                          });
                        }

                        return PlayStopButton(
                          isPlaying: isCurrentTonePlaying,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _togglePlayPause,
                          size: 64,
                          iconSize: 28,
                          borderRadius: 16, // Cuadrado con bordes redondeados
                        );
                      },
                    ),

                    // Next Button
                    IconButton(
                      onPressed: _hasNext() ? _playNextTone : null,
                      icon: Icon(
                        Icons.skip_next,
                        size: 32,
                        color: _hasNext()
                            ? context.iconSecondary
                            : context.iconDisabled,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Favorite Button
                    Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, child) {
                        final isFavorite = favoritesProvider.isFavoriteSync(
                          _currentTone.id,
                        );
                        return IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 28,
                            color: isFavorite
                                ? context.iconFavoriteActive
                                : context.iconSecondary,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 16),

                    // Share Button
                    IconButton(
                      onPressed: () async {
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
                      icon: Icon(
                        Icons.share_outlined,
                        size: 28,
                        color: context.iconSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Set as Ringtone Button
                Container(
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _downloadTone();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Establecer como tono',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Bottom padding for safety
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    CustomSnackBar.show(
      context,
      message: message,
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
