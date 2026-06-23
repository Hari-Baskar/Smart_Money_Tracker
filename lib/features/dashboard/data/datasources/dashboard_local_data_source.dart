import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/core/services/local_database_helper.dart';

class DashboardLocalDataSource {
  final LocalDatabaseHelper _dbHelper = LocalDatabaseHelper.instance;

  // ── Database Watch ─────────────────────────────────────────────────────────
  Stream<void> get onChange => _dbHelper.onChange;

  // ── Transactions (SQLite) ──────────────────────────────────────────────────
  Future<List<TransactionModel>> getTransactions(String userId) async {
    return await _dbHelper.getTransactions(userId);
  }

  Future<void> saveTransaction(String userId, TransactionModel transaction) async {
    await _dbHelper.saveTransaction(userId, transaction);
  }

  Future<void> saveTransactionsBatch(String userId, List<TransactionModel> transactions) async {
    await _dbHelper.saveTransactionsBatch(userId, transactions);
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _dbHelper.deleteTransaction(userId, transactionId);
  }

  Future<List<TransactionModel>> getTransactionsInDateRange(
    String userId, 
    DateTime start, 
    DateTime end,
  ) async {
    return await _dbHelper.getTransactionsInDateRange(userId, start, end);
  }

  Future<int> getTransactionCount(String userId) async {
    return await _dbHelper.getTransactionCount(userId);
  }

  Future<DateTime?> getOldestTransactionDate(String userId) async {
    return await _dbHelper.getOldestTransactionDate(userId);
  }

  Future<DateTime?> getNewestTransactionDate(String userId) async {
    return await _dbHelper.getNewestTransactionDate(userId);
  }

  // ── Categories (SQLite) ────────────────────────────────────────────────────
  Future<List<CategoryModel>> getCategories(String userId) async {
    return await _dbHelper.getCategories(userId);
  }

  Future<void> saveCategory(String userId, CategoryModel category) async {
    await _dbHelper.saveCategory(userId, category);
  }

  Future<void> saveCategoriesBatch(String userId, List<CategoryModel> categories) async {
    await _dbHelper.saveCategoriesBatch(userId, categories);
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await _dbHelper.deleteCategory(userId, categoryId);
  }

  // ── Subcategories (SQLite) ─────────────────────────────────────────────────
  Future<List<SubcategoryModel>> getSubcategories(String userId) async {
    return await _dbHelper.getSubcategories(userId);
  }

  Future<void> saveSubcategory(String userId, SubcategoryModel subcategory) async {
    await _dbHelper.saveSubcategory(userId, subcategory);
  }

  Future<void> saveSubcategoriesBatch(String userId, List<SubcategoryModel> subcategories) async {
    await _dbHelper.saveSubcategoriesBatch(userId, subcategories);
  }

  Future<void> deleteSubcategory(String userId, String subcategoryId) async {
    await _dbHelper.deleteSubcategory(userId, subcategoryId);
  }

  // ── Custom Assets (SQLite) ─────────────────────────────────────────────────
  Future<List<CustomAssetModel>> getCustomAssets(String userId) async {
    return await _dbHelper.getCustomAssets(userId);
  }

  Future<void> saveCustomAsset(String userId, CustomAssetModel asset) async {
    await _dbHelper.saveCustomAsset(userId, asset);
  }

  Future<void> deleteCustomAsset(String userId, String id) async {
    await _dbHelper.deleteCustomAsset(userId, id);
  }

  // ── Database Maintenance ───────────────────────────────────────────────────
  Future<void> clearDatabase(String userId) async {
    await _dbHelper.clearDatabase(userId);
  }

  // ── SharedPreferences Caching ──────────────────────────────────────────────
  Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  Future<void> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
