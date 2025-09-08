import 'package:flutter/foundation.dart';

@immutable
class Favorite {
  final String toneId;
  final String title;
  final String url;
  final DateTime createdAt;
  final bool requiresAttribution;
  final String? attributionText;

  const Favorite({
    required this.toneId,
    required this.title,
    required this.url,
    required this.createdAt,
    this.requiresAttribution = false,
    this.attributionText,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Favorite &&
          runtimeType == other.runtimeType &&
          toneId == other.toneId;

  @override
  int get hashCode => toneId.hashCode;

  @override
  String toString() =>
      'Favorite(toneId: $toneId, title: $title, url: $url, createdAt: $createdAt, requiresAttribution: $requiresAttribution, attributionText: $attributionText)';
}