import 'package:flutter/foundation.dart';

@immutable
class Category {
  final String id;
  final String title;
  final String? iconUrl;

  const Category({
    required this.id,
    required this.title,
    this.iconUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, title: $title, iconUrl: $iconUrl)';
}
