import '../entities/category.dart';

abstract class CategoriesRepository {
  Future<List<Category>> getCategories();
}
