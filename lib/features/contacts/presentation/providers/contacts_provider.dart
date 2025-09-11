import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/contact.dart';
import '../../domain/usecases/get_contacts.dart';
import '../../domain/usecases/request_contacts_permission.dart';

class ContactsProvider extends ChangeNotifier {
  final GetContacts getContacts;
  final RequestContactsPermission requestContactsPermission;

  ContactsProvider({
    required this.getContacts,
    required this.requestContactsPermission,
  });

  List<Contact> _contacts = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;

  Future<void> loadContacts([BuildContext? context]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First check/request permission
      if (context != null) {
        _hasPermission = await requestContactsPermission.callWithDialog(context);
      } else {
        _hasPermission = await requestContactsPermission();
      }
      
      if (_hasPermission) {
        _contacts = await getContacts();
      } else {
        _errorMessage = 'Se requiere permiso para acceder a los contactos';
        _contacts = [];
      }
    } catch (e) {
      _errorMessage = 'Error al cargar contactos: ${e.toString()}';
      _contacts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<Contact> searchContacts(String query) {
    if (query.isEmpty) return _contacts;
    
    final lowerQuery = query.toLowerCase();
    return _contacts.where((contact) {
      return contact.name.toLowerCase().contains(lowerQuery) ||
             (contact.phoneNumber?.contains(query) ?? false);
    }).toList();
  }
}