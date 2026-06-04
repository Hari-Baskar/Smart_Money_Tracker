import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/services/local_database_helper.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/category_repository.dart';

class LocalFirstCategoryRepository implements CategoryRepository {
  final FirebaseFirestore _firestore;
  final LocalDatabaseHelper _dbHelper = LocalDatabaseHelper.instance;

  LocalFirstCategoryRepository(this._firestore);

  Future<void> initializeSync(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final syncKey = 'has_completed_initial_category_sync_$userId';
    final hasSynced = prefs.getBool(syncKey) ?? false;

    if (!hasSynced) {
      try {
        print('Starting one-time custom categories migration from Firestore...');
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final categories = snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.data()))
              .toList();
          
          await _dbHelper.saveCategoriesBatch(userId, categories);
        }
        await prefs.setBool(syncKey, true);
        print('Custom categories migration successfully completed.');
      } catch (e) {
        print('Failed to perform initial categories sync: $e');
      }
    }
  }

  @override
  Future<List<CategoryModel>> getCategories(String userId) async {
    await initializeSync(userId);
    return await _dbHelper.getCategories(userId);
  }

  @override
  Future<void> saveCategory(String userId, CategoryModel category) async {
    await _dbHelper.saveCategory(userId, category);
    _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .set(category.toMap())
        .catchError((e) {
          print('Error syncing category write to Firestore: $e');
        });
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    await _dbHelper.deleteCategory(userId, categoryId);
    _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete()
        .catchError((e) {
          print('Error syncing category delete to Firestore: $e');
        });
  }
}
