import '../../domain/entities/favorite.dart';

class FavoriteModel extends Favorite {
  const FavoriteModel({
    required super.toneId,
    required super.title,
    required super.url,
    required super.createdAt,
    super.requiresAttribution = false,
    super.attributionText,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      toneId: map['tone_id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      requiresAttribution: map['requires_attribution'] == 1,
      attributionText: map['attribution_text'] as String?,
    );
  }

  factory FavoriteModel.fromEntity(Favorite favorite) {
    return FavoriteModel(
      toneId: favorite.toneId,
      title: favorite.title,
      url: favorite.url,
      createdAt: favorite.createdAt,
      requiresAttribution: favorite.requiresAttribution,
      attributionText: favorite.attributionText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tone_id': toneId,
      'title': title,
      'url': url,
      'created_at': createdAt.millisecondsSinceEpoch,
      'requires_attribution': requiresAttribution ? 1 : 0,
      'attribution_text': attributionText,
    };
  }

  Favorite toEntity() {
    return Favorite(
      toneId: toneId,
      title: title,
      url: url,
      createdAt: createdAt,
      requiresAttribution: requiresAttribution,
      attributionText: attributionText,
    );
  }
}