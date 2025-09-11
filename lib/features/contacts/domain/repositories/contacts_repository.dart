import '../entities/contact.dart';

abstract class ContactsRepository {
  Future<bool> hasContactsPermission();
  Future<bool> requestContactsPermission();
  Future<List<Contact>> getContacts();
}