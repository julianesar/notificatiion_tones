import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class GetCategories {
  final CategoriesRepository _repository;

  GetCategories(this._repository);

  Future<List<Category>> call() async {
    return await _repository.getCategories();
  }
}
