import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/system_settings_permission_dialog.dart';
import 'permissions_service.dart';
import 'ringtone_configuration_service.dart';

class RingtoneConfigurationResult {
  final bool success;
  final String? errorMessage;
  final bool requiresManualConfiguration;

  RingtoneConfigurationResult({
    required this.success,
    this.errorMessage,
    this.requiresManualConfiguration = false,
  });

  factory RingtoneConfigurationResult.success() {
    return RingtoneConfigurationResult(success: true);
  }

  factory RingtoneConfigurationResult.error(String message) {
    return RingtoneConfigurationResult(success: false, errorMessage: message);
  }

  factory RingtoneConfigurationResult.requiresManualConfig(String message) {
    return RingtoneConfigurationResult(
      success: false,
      errorMessage: message,
      requiresManualConfiguration: true,
    );
  }
}

abstract class RingtoneManagementService {
  Future<RingtoneConfigurationResult> setAsCallRingtone(BuildContext context, String filePath, String toneName);
  Future<RingtoneConfigurationResult> setAsNotificationRingtone(BuildContext context, String filePath, String toneName);
  Future<RingtoneConfigurationResult> setAsAlarmRingtone(BuildContext context, String filePath, String toneName);
  Future<RingtoneConfigurationResult> setAsContactRingtone(BuildContext context, String filePath, String toneName);
}

class RingtoneManagementServiceImpl implements RingtoneManagementService {
  final PermissionsService _permissionsService;
  final RingtoneConfigurationService _ringtoneConfigurationService;
  
  RingtoneManagementServiceImpl({
    required PermissionsService permissionsService,
    required RingtoneConfigurationService ringtoneConfigurationService,
  }) : _permissionsService = permissionsService,
       _ringtoneConfigurationService = ringtoneConfigurationService;

  Future<RingtoneConfigurationResult> _handleSystemSettingsPermission(
    BuildContext context,
    String actionName,
  ) async {
    // Check if we already have system settings permission using the native method
    bool hasPermission = await _ringtoneConfigurationService.hasSystemSettingsPermission();
    
    print('DEBUG: Initial hasPermission = $hasPermission for $actionName');
    
    if (!hasPermission) {
      // Show explanation dialog
      final permissionMessage = await _permissionsService.getSystemSettingsPermissionMessage();
      
      final bool? userAccepted = await SystemSettingsPermissionDialog.show(
        context: context,
        title: 'Permiso Requerido',
        message: permissionMessage,
        onContinue: () async {
          // Request the permission - this will redirect to settings
          await _ringtoneConfigurationService.requestSystemSettingsPermission();
        },
      );

      if (userAccepted != true) {
        return RingtoneConfigurationResult.error(
          'Se requiere permiso para configurar $actionName',
        );
      }

      // Wait for user to return from settings and check permission
      hasPermission = await _waitForPermissionGrant(context);
      
      if (!hasPermission) {
        return RingtoneConfigurationResult.requiresManualConfig(
          'Para completar la configuración de $actionName:\n\n'
          '1. Ve a Configuración del sistema\n'
          '2. Busca "Sonidos de Notificaciones" o tu app\n'
          '3. Activa "Modificar configuración del sistema"\n'
          '4. Vuelve e intenta de nuevo\n\n'
          'Si ya activaste el permiso, intenta reiniciar la app.',
        );
      }
    }

    return RingtoneConfigurationResult.success();
  }

  Future<bool> _waitForPermissionGrant(BuildContext context) async {
    // Show a waiting dialog while checking for permission
    bool permissionGranted = false;
    int attempts = 0;
    const maxAttempts = 10; // Check for 10 seconds
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Esperando que actives el permiso...\nVuelve a la app cuando esté listo'),
          ],
        ),
      ),
    );

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
      
      final hasPermission = await _ringtoneConfigurationService.hasSystemSettingsPermission();
      print('DEBUG: Attempt $attempts: hasPermission = $hasPermission');
      
      if (hasPermission) {
        permissionGranted = true;
        break;
      }
    }

    // Close the waiting dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    return permissionGranted;
  }

  Future<RingtoneConfigurationResult> _configureRingtone(
    BuildContext context,
    String filePath,
    String toneName,
    RingtoneType ringtoneType,
    String actionName,
  ) async {
    try {
      // First, handle system settings permission
      final permissionResult = await _handleSystemSettingsPermission(context, actionName);
      if (!permissionResult.success) {
        return permissionResult;
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return RingtoneConfigurationResult.error(
          'El archivo de audio no se encuentra en: $filePath',
        );
      }

      // Attempt to configure the ringtone
      final success = await _ringtoneConfigurationService.configureRingtone(
        filePath,
        ringtoneType,
      );

      if (success) {
        return RingtoneConfigurationResult.success();
      } else {
        return RingtoneConfigurationResult.error(
          'No se pudo configurar $actionName. Inténtalo nuevamente.',
        );
      }
    } catch (e) {
      return RingtoneConfigurationResult.error(
        'Error al configurar $actionName: ${e.toString()}',
      );
    }
  }

  @override
  Future<RingtoneConfigurationResult> setAsCallRingtone(
    BuildContext context,
    String filePath,
    String toneName,
  ) async {
    return await _configureRingtone(
      context,
      filePath,
      toneName,
      RingtoneType.call,
      'tono de llamada',
    );
  }

  @override
  Future<RingtoneConfigurationResult> setAsNotificationRingtone(
    BuildContext context,
    String filePath,
    String toneName,
  ) async {
    return await _configureRingtone(
      context,
      filePath,
      toneName,
      RingtoneType.notification,
      'tono de notificación',
    );
  }

  @override
  Future<RingtoneConfigurationResult> setAsAlarmRingtone(
    BuildContext context,
    String filePath,
    String toneName,
  ) async {
    return await _configureRingtone(
      context,
      filePath,
      toneName,
      RingtoneType.alarm,
      'tono de alarma',
    );
  }

  @override
  Future<RingtoneConfigurationResult> setAsContactRingtone(
    BuildContext context,
    String filePath,
    String toneName,
  ) async {
    // For contact ringtone, we might need to handle contact selection
    // This is a simplified implementation
    return await _configureRingtone(
      context,
      filePath,
      toneName,
      RingtoneType.contact,
      'tono de contacto',
    );
  }
}