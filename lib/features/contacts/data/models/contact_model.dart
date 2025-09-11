import '../../domain/entities/contact.dart';

class ContactModel extends Contact {
  const ContactModel({
    required super.id,
    required super.name,
    super.phoneNumber,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phoneNumber,
    };
  }

  factory ContactModel.fromEntity(Contact contact) {
    return ContactModel(
      id: contact.id,
      name: contact.name,
      phoneNumber: contact.phoneNumber,
    );
  }
}