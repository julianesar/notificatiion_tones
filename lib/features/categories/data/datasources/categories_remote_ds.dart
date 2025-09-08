import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoriesRemoteDS {
  final ApiClient _apiClient;

  CategoriesRemoteDS(this._apiClient);

  Future<List<CategoryModel>> fetchCategories() async {
    final json = await _apiClient.getJson(
      '/v1/categories',
      cacheKey: '/v1/categories',
    );

    final data = json['data'] as List<dynamic>;

    return data
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
