import 'package:flutter/services.dart';
import '../models/contact_model.dart';

abstract class ContactsNativeDataSource {
  Future<bool> hasContactsPermission();
  Future<bool> requestContactsPermission();
  Future<List<ContactModel>> getContacts();
}

class ContactsNativeDataSourceImpl implements ContactsNativeDataSource {
  static const MethodChannel _channel = MethodChannel('com.example.notifications_sounds/ringtone_config');

  @override
  Future<bool> hasContactsPermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasContactsPermission');
      return result;
    } catch (e) {
      print('Error checking contacts permission: $e');
      return false;
    }
  }

  @override
  Future<bool> requestContactsPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestContactsPermission');
      return result;
    } catch (e) {
      print('Error requesting contacts permission: $e');
      return false;
    }
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getContacts');
      return result.map((contact) => ContactModel.fromJson(contact.cast<String, dynamic>())).toList();
    } catch (e) {
      print('Error getting contacts: $e');
      return [];
    }
  }
}