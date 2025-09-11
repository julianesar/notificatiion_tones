class Contact {
  final String id;
  final String name;
  final String? phoneNumber;

  const Contact({
    required this.id,
    required this.name,
    this.phoneNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phoneNumber == other.phoneNumber;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ phoneNumber.hashCode;

  @override
  String toString() => 'Contact(id: $id, name: $name, phoneNumber: $phoneNumber)';
}