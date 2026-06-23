import 'package:smart_money_tracker/core/models/transaction_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories(String userId);
  Future<void> saveCategory(String userId, CategoryModel category);
  Future<void> deleteCategory(String userId, String categoryId);
}
