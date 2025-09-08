import '../../../../core/network/api_client.dart';
import '../models/tone_model.dart';

class TonesRemoteDS {
  final ApiClient _apiClient;

  TonesRemoteDS(this._apiClient);

  Future<List<ToneModel>> fetchTones(
    String categoryId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final query = {
      'category': categoryId,
      'limit': '$limit',
      'offset': '$offset',
    };

    final cacheKey =
        '/v1/tones?category=$categoryId&limit=$limit&offset=$offset';

    final json = await _apiClient.getJson(
      '/v1/tones',
      query: query,
      cacheKey: cacheKey,
    );

    final data = json['data'] as List<dynamic>;

    return data
        .map((item) => ToneModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
