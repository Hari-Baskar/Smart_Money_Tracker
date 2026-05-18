import 'package:smart_money_tracker/core/models/transaction_model.dart';

abstract class SubcategoryRepository {
  Future<List<SubcategoryModel>> getSubcategories(String userId);
  Future<void> saveSubcategory(String userId, SubcategoryModel subcategory);
  Future<void> deleteSubcategory(String userId, String subcategoryId);
}
