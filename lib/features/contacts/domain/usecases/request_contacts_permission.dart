import 'package:flutter/material.dart';
import '../repositories/contacts_repository.dart';
import '../../../../shared/widgets/contacts_permission_dialog.dart';

class RequestContactsPermission {
  final ContactsRepository repository;

  RequestContactsPermission(this.repository);

  Future<bool> call() async {
    if (await repository.hasContactsPermission()) {
      return true;
    }
    return await repository.requestContactsPermission();
  }

  Future<bool> callWithDialog(BuildContext context) async {
    if (await repository.hasContactsPermission()) {
      return true;
    }

    // Show explanatory dialog first
    final bool? userAccepted = await ContactsPermissionDialog.show(
      context: context,
      title: 'Acceso a Contactos',
      message: 'Para asignar tonos personalizados a contactos específicos, necesitamos acceso a tu lista de contactos.\n\nEsto nos permite mostrarte tus contactos para que elijas a cuál asignar el tono.',
      onContinue: () {}, // This will be handled after dialog closes
    );

    if (userAccepted != true) {
      return false;
    }

    // User accepted, now request the native permission
    return await repository.requestContactsPermission();
  }
}