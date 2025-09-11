import '../entities/contact.dart';
import '../repositories/contacts_repository.dart';

class GetContacts {
  final ContactsRepository repository;

  GetContacts(this.repository);

  Future<List<Contact>> call() async {
    return await repository.getContacts();
  }
}