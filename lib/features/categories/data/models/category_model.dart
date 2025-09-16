import 'package:flutter/foundation.dart';
import '../../domain/entities/category.dart' as domain;

@immutable
class CategoryModel {
  final String id;
  final String title;
  final String? iconUrl;

  const CategoryModel({
    required this.id,
    required this.title,
    this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      iconUrl: json['iconUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconUrl': iconUrl,
    };
  }

  domain.Category toEntity() {
    return domain.Category(
      id: id,
      title: title,
      iconUrl: iconUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryModel(id: $id, title: $title, iconUrl: $iconUrl)';
}
