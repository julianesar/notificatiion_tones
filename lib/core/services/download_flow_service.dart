import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../features/downloads/presentation/providers/downloads_provider.dart';
import '../../../features/downloads/domain/entities/download_result.dart';
import '../../../features/tones/domain/entities/tone.dart';
import '../../../screens/main_screen.dart';
import '../../shared/widgets/permission_explanation_dialog.dart';
import 'permissions_service.dart';

class DownloadFlowService {
  static Future<void> downloadToneWithPermissions({
    required BuildContext context,
    required String toneId,
    required String title,
    required String url,
    bool? requiresAttribution,
    String? attributionText,
  }) async {
    print('DEBUG: Iniciando downloadToneWithPermissions para: $title');
    if (!context.mounted) {
      print('DEBUG: Context no mounted al inicio');
      return;
    }

    // Guardar referencias antes de operaciones asíncronas que pueden invalidar el context
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);
    final downloadsProvider = context.read<DownloadsProvider>();
    final permissionsService = context.read<PermissionsService>();
    print('DEBUG: Providers y referencias obtenidas correctamente');

    try {
      // 1. Verificar primero si ya tenemos los permisos
      print('DEBUG: Verificando permisos existentes...');
      bool hasPermissions = await permissionsService.hasStoragePermissions();
      print('DEBUG: Permisos existentes: $hasPermissions');
      
      if (!hasPermissions) {
        // 2. Mostrar diálogo explicativo antes de solicitar permisos
        print('DEBUG: Mostrando diálogo explicativo...');
        if (!context.mounted) {
          print('DEBUG: Context no mounted antes del diálogo');
          return;
        }
        
        final shouldRequestPermission = await _showPermissionExplanationDialog(
          context,
          permissionsService,
        );
        print('DEBUG: Usuario quiere solicitar permisos: $shouldRequestPermission');
        
        if (!shouldRequestPermission) {
          print('DEBUG: Usuario canceló solicitud de permisos');
          return; // Usuario canceló
        }
        
        // 3. Solicitar permisos del sistema
        print('DEBUG: Solicitando permisos del sistema...');
        hasPermissions = await permissionsService.requestStoragePermissions();
        print('DEBUG: Permisos concedidos: $hasPermissions');
        
        if (!hasPermissions) {
          // 4. Mostrar mensaje si se negaron los permisos
          print('DEBUG: Permisos denegados, mostrando mensaje');
          await _showPermissionDeniedMessageWithRefs(
            scaffoldMessenger, 
            permissionsService,
            theme,
          );
          return;
        }
        
        print('DEBUG: Permisos concedidos exitosamente');
        // Pequeño delay para asegurar que la UI se estabilice después del diálogo de permisos
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // 5. Proceder con la descarga usando referencias guardadas
      await _proceedWithDownloadWithRefs(
        scaffoldMessenger: scaffoldMessenger,
        navigator: navigator,
        theme: theme,
        downloadsProvider: downloadsProvider,
        toneId: toneId,
        title: title,
        url: url,
        requiresAttribution: requiresAttribution,
        attributionText: attributionText,
      );

    } catch (e) {
      print('DEBUG: Error inesperado: $e');
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  static Future<void> _proceedWithDownloadWithRefs({
    required ScaffoldMessengerState scaffoldMessenger,
    required NavigatorState navigator,
    required ThemeData theme,
    required DownloadsProvider downloadsProvider,
    required String toneId,
    required String title,
    required String url,
    bool? requiresAttribution,
    String? attributionText,
  }) async {
    print('DEBUG: Procediendo con la descarga usando referencias guardadas');
    
    // Mostrar mensaje de "Preparando descarga"
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Preparando descarga de $title'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // Pequeño delay para que el usuario vea el mensaje
    await Future.delayed(const Duration(milliseconds: 500));

    // Crear objeto de tono y proceder con la descarga
    final toneForDownload = Tone(
      id: toneId,
      title: title,
      url: url,
      requiresAttribution: requiresAttribution ?? false,
      attributionText: attributionText,
    );

    print('DEBUG: Iniciando descarga para: $title');
    try {
      final result = await downloadsProvider.downloadTone(toneForDownload);
      print('DEBUG: Resultado de descarga: ${result.isSuccess}');

      if (result.isSuccess) {
        print('DEBUG: Descarga exitosa, mostrando confirmación');
        HapticFeedback.lightImpact();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('$title descargado exitosamente'),
            backgroundColor: Colors.green[800],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                navigator.pushAndRemoveUntil(
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
        print('DEBUG: Descarga falló: ${result.message}');
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

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Excepción durante descarga: $e');
      
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error durante la descarga: $e'),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
  
  // Método legacy mantenido para compatibilidad
  static Future<void> _proceedWithDownload({
    required BuildContext context,
    required DownloadsProvider downloadsProvider,
    required String toneId,
    required String title,
    required String url,
    bool? requiresAttribution,
    String? attributionText,
  }) async {
    // Este método ahora redirige al nuevo que usa referencias
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);
    
    await _proceedWithDownloadWithRefs(
      scaffoldMessenger: scaffoldMessenger,
      navigator: navigator,
      theme: theme,
      downloadsProvider: downloadsProvider,
      toneId: toneId,
      title: title,
      url: url,
      requiresAttribution: requiresAttribution,
      attributionText: attributionText,
    );
  }

  static Future<bool> _showPermissionExplanationDialog(
    BuildContext context,
    PermissionsService permissionsService,
  ) async {
    final sdkVersion = await permissionsService.getAndroidSdkVersion();
    final permissionType = sdkVersion >= 33 ? 'Música y audio' : 'Almacenamiento';
    final explanation = sdkVersion >= 33
        ? 'Necesitamos acceso a "Música y audio" para poder guardar los tonos de notificación en tu dispositivo. Esto nos permite crear archivos de audio en la carpeta de descargas.'
        : 'Necesitamos acceso al almacenamiento para poder guardar los tonos de notificación en tu dispositivo.';

    if (!context.mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionExplanationDialog(
        permissionType: permissionType,
        explanation: explanation,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    return result ?? false;
  }

  static Future<void> _showPermissionDeniedMessageWithRefs(
    ScaffoldMessengerState scaffoldMessenger,
    PermissionsService permissionsService,
    ThemeData theme,
  ) async {
    final message = await permissionsService.getRequiredPermissionMessage();
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permiso requerido',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Configuración',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Abrir configuración de la app
          },
        ),
      ),
    );
  }

  static Future<void> _showPermissionDeniedMessage(
    BuildContext context,
    PermissionsService permissionsService,
  ) async {
    final message = await permissionsService.getRequiredPermissionMessage();
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permiso requerido',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Configuración',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Abrir configuración de la app
          },
        ),
      ),
    );
  }
}