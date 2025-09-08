import 'package:flutter/foundation.dart';

@immutable
class Tone {
  final String id;
  final String title;
  final String url;
  final bool requiresAttribution;
  final String? attributionText;

  const Tone({
    required this.id,
    required this.title,
    required this.url,
    required this.requiresAttribution,
    this.attributionText,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Tone(id: $id, title: $title, url: $url, requiresAttribution: $requiresAttribution, attributionText: $attributionText)';
}
