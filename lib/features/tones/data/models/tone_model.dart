import 'package:flutter/foundation.dart';
import '../../domain/entities/tone.dart';

@immutable
class ToneModel {
  final String id;
  final String title;
  final String url;
  final bool requiresAttribution;
  final String? attributionText;

  const ToneModel({
    required this.id,
    required this.title,
    required this.url,
    required this.requiresAttribution,
    this.attributionText,
  });

  factory ToneModel.fromJson(Map<String, dynamic> json) {
    return ToneModel(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      requiresAttribution: json['requiresAttribution'] as bool? ?? false,
      attributionText: json['attributionText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'requiresAttribution': requiresAttribution,
      'attributionText': attributionText,
    };
  }

  Tone toEntity() {
    return Tone(
      id: id,
      title: title,
      url: url,
      requiresAttribution: requiresAttribution,
      attributionText: attributionText,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToneModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ToneModel(id: $id, title: $title, url: $url, requiresAttribution: $requiresAttribution, attributionText: $attributionText)';
}
