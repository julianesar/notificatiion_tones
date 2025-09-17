import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../features/downloads/presentation/providers/downloads_provider.dart';
import '../../../features/downloads/domain/entities/download_result.dart';
import '../../../features/tones/domain/entities/tone.dart';
import '../../shared/widgets/permission_explanation_dialog.dart';
import '../../shared/widgets/custom_snackbar.dart';
import '../../config/theme_config.dart';
import 'permissions_service.dart';
import '../navigation/navigation_service.dart';

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
    
    // Verificar si el tono ya está descargado
    if (downloadsProvider.isDownloaded(toneId)) {
      print('DEBUG: Tono ya descargado, mostrando mensaje');
      scaffoldMessenger.showSnackBar(
        CustomSnackBar.info(
          context,
          message: '$title ya está descargado',
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.black,
            onPressed: () {
              print('DownloadFlow: Botón "Ver" presionado, intentando navegar...');
              NavigationService.instance.navigateToDownloads();
            },
          ),
        ),
      );
      return;
    }

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
        context: context,
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
        CustomSnackBar.error(
          context,
          message: 'Error inesperado: $e',
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  static Future<void> _proceedWithDownloadWithRefs({
    required BuildContext context,
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
      CustomSnackBar.download(
        context,
        message: 'Preparando descarga de $title',
        duration: const Duration(seconds: 1),
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
    print('DEBUG: Tone data - id: $toneId, requiresAttribution: ${requiresAttribution ?? false}, attributionText: $attributionText'); // Debug
    try {
      final result = await downloadsProvider.downloadTone(toneForDownload);
      print('DEBUG: Resultado de descarga: ${result.isSuccess}');

      if (result.isSuccess) {
        print('DEBUG: Descarga exitosa, mostrando confirmación');
        HapticFeedback.lightImpact();
        scaffoldMessenger.showSnackBar(
          CustomSnackBar.success(
            context,
            message: '$title descargado exitosamente',
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.black,
              onPressed: () {
                print('DownloadFlow: Segundo botón "Ver" presionado, intentando navegar...');
                NavigationService.instance.navigateToDownloads();
              },
            ),
          ),
        );
      } else {
        print('DEBUG: Descarga falló: ${result.message}');
        
        // Verificar si es un error de descarga duplicada para dar feedback diferente
        if (result.message?.contains('ya está descargado') == true ||
            result.message?.contains('descarga en progreso') == true) {
          // Para archivos ya descargados o en progreso, usar feedback ligero
          HapticFeedback.lightImpact();
          scaffoldMessenger.showSnackBar(
            CustomSnackBar.info(
              context,
              message: result.message ?? 'El archivo ya existe',
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.black,
                onPressed: () {
                  NavigationService.instance.navigateToDownloads();
                },
              ),
            ),
          );
          return;
        }
        
        // Para errores reales, usar feedback fuerte
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
          CustomSnackBar.error(
            context,
            message: errorMessage,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Excepción durante descarga: $e');
      
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        CustomSnackBar.error(
          context,
          message: 'Error durante la descarga: $e',
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
      context: context,
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

    print('DEBUG: Android SDK version: $sdkVersion');

    // Solo mostrar diálogo para Android 9 y anteriores (API 28 y menores)
    if (sdkVersion >= 29) {
      print('DEBUG: Android 10+ detected - no storage permission needed');
      return true; // No se necesita permiso, proceder directamente
    }

    print('DEBUG: Android 9 e inferior detected - storage permission required');
    
    final permissionType = 'Almacenamiento';
    final explanation = 'Necesitamos acceso al almacenamiento para poder guardar los tonos de notificación en tu dispositivo.';

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
        content: Text('Permiso requerido: $message'),
        backgroundColor: ThemeConfig.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Configuración',
          textColor: Colors.black,
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
    
    CustomSnackBar.show(
      context,
      message: 'Permiso requerido: $message',
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: 'Configuración',
        textColor: Colors.black,
        onPressed: () {
          // TODO: Abrir configuración de la app
        },
      ),
    );
  }

  static Future<void> downloadToneWithPermissionsAndConfigure({
    required BuildContext context,
    required String toneId,
    required String title,
    required String url,
    bool? requiresAttribution,
    String? attributionText,
    required VoidCallback onDownloadSuccess,
  }) async {
    print('DEBUG: Iniciando downloadToneWithPermissionsAndConfigure para: $title');
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
    
    // Verificar si el tono ya está descargado
    if (downloadsProvider.isDownloaded(toneId)) {
      print('DEBUG: Tono ya descargado, mostrando modal de configuración');
      onDownloadSuccess();
      return;
    }

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

        // Verificar que el context sigue montado después de la concesión de permisos
        if (!context.mounted) {
          print('DEBUG: Context no mounted después de conceder permisos, cancelando descarga');
          return;
        }
        print('DEBUG: Context verificado como mounted después de permisos');
      }

      // 5. Proceder con la descarga usando referencias guardadas
      await _proceedWithDownloadAndConfigure(
        context: context,
        scaffoldMessenger: scaffoldMessenger,
        navigator: navigator,
        theme: theme,
        downloadsProvider: downloadsProvider,
        toneId: toneId,
        title: title,
        url: url,
        requiresAttribution: requiresAttribution,
        attributionText: attributionText,
        onDownloadSuccess: onDownloadSuccess,
      );

    } catch (e) {
      print('DEBUG: Error inesperado: $e');
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        CustomSnackBar.error(
          context,
          message: 'Error inesperado: $e',
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  static Future<void> _proceedWithDownloadAndConfigure({
    required BuildContext context,
    required ScaffoldMessengerState scaffoldMessenger,
    required NavigatorState navigator,
    required ThemeData theme,
    required DownloadsProvider downloadsProvider,
    required String toneId,
    required String title,
    required String url,
    bool? requiresAttribution,
    String? attributionText,
    required VoidCallback onDownloadSuccess,
  }) async {
    print('DEBUG: Procediendo con la descarga y configuración usando referencias guardadas');
    
    // Mostrar mensaje de "Preparando descarga"
    scaffoldMessenger.showSnackBar(
      CustomSnackBar.download(
        context,
        message: 'Preparando descarga de $title',
        duration: const Duration(seconds: 1),
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

    print('DEBUG: Iniciando descarga para configuración: $title');
    try {
      final result = await downloadsProvider.downloadTone(toneForDownload);
      print('DEBUG: Resultado de descarga para configuración: ${result.isSuccess}');

      if (result.isSuccess) {
        print('DEBUG: Descarga exitosa, mostrando modal de configuración');
        HapticFeedback.lightImpact();

        // Ejecutar callback inmediatamente después de la descarga exitosa
        print('DEBUG: Ejecutando callback inmediatamente después de descarga exitosa');

        // Ejecutar el callback directamente - el widget receptor maneja el estado
        onDownloadSuccess();
        
      } else {
        print('DEBUG: Descarga falló: ${result.message}');
        
        // Verificar si es un error de descarga duplicada
        if (result.message?.contains('ya está descargado') == true ||
            result.message?.contains('descarga en progreso') == true) {
          // Si ya está descargado, mostrar directamente el modal de configuración
          print('DEBUG: Archivo ya descargado, mostrando modal de configuración');
          HapticFeedback.lightImpact();

          // Para archivos ya descargados, ejecutar callback inmediatamente
          print('DEBUG: Ejecutando callback inmediatamente para archivo ya descargado');

          onDownloadSuccess();
          return;
        }
        
        // Para errores reales
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
          CustomSnackBar.error(
            context,
            message: errorMessage,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Excepción durante descarga para configuración: $e');
      
      HapticFeedback.heavyImpact();
      scaffoldMessenger.showSnackBar(
        CustomSnackBar.error(
          context,
          message: 'Error durante la descarga: $e',
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}