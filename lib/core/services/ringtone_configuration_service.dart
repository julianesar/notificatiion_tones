import 'dart:io';
import 'package:flutter/services.dart';
import '../constants/method_channels.dart';

enum RingtoneType {
  call,
  notification,
  alarm,
  contact,
}

abstract class RingtoneConfigurationService {
  Future<bool> hasSystemSettingsPermission();
  Future<bool> requestSystemSettingsPermission();
  Future<bool> configureRingtone(String filePath, RingtoneType type, {String? contactId});
  Future<void> openSystemSettings();
}

class RingtoneConfigurationServiceImpl implements RingtoneConfigurationService {
  static const MethodChannel _channel = MethodChannel(MethodChannels.ringtoneConfig);

  @override
  Future<bool> hasSystemSettingsPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final bool hasPermission = await _channel.invokeMethod('hasSystemSettingsPermission');
      print('DEBUG: Native hasSystemSettingsPermission returned: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('Error checking system settings permission: $e');
      return false;
    }
  }

  @override
  Future<bool> requestSystemSettingsPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // This will open the system settings for the user to manually grant permission
      await _channel.invokeMethod('requestSystemSettingsPermission');
      // We don't wait for the result as user will be redirected to settings
      return true;
    } catch (e) {
      print('Error requesting system settings permission: $e');
      return false;
    }
  }

  @override
  Future<void> openSystemSettings() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('openSystemSettings');
    } catch (e) {
      print('Error opening system settings: $e');
    }
  }

  @override
  Future<bool> configureRingtone(String filePath, RingtoneType type, {String? contactId}) async {
    if (!Platform.isAndroid) {
      // iOS implementation would go here
      return false;
    }
    
    try {
      final Map<String, dynamic> arguments = {
        'filePath': filePath,
        'ringtoneType': type.name,
      };
      
      if (contactId != null) {
        arguments['contactId'] = contactId;
      }
      
      final bool success = await _channel.invokeMethod('setRingtone', arguments);
      return success;
    } catch (e) {
      print('Error configuring ringtone: $e');
      return false;
    }
  }
}