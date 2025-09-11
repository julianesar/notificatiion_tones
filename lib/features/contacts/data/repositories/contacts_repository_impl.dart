import '../../domain/entities/contact.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../datasources/contacts_native_ds.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final ContactsNativeDataSource nativeDataSource;

  ContactsRepositoryImpl({required this.nativeDataSource});

  @override
  Future<bool> hasContactsPermission() async {
    return await nativeDataSource.hasContactsPermission();
  }

  @override
  Future<bool> requestContactsPermission() async {
    return await nativeDataSource.requestContactsPermission();
  }

  @override
  Future<List<Contact>> getContacts() async {
    final contactModels = await nativeDataSource.getContacts();
    return contactModels.cast<Contact>();
  }
}