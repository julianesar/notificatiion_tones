import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_remote_ds.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesRemoteDS _remoteDataSource;

  CategoriesRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Category>> getCategories() async {
    final categoryModels = await _remoteDataSource.fetchCategories();
    return categoryModels.map((model) => model.toEntity()).toList();
  }
}
