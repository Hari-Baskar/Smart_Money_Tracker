import 'dart:async';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/category_repository.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../datasources/dashboard_remote_data_source.dart';

class LocalFirstCategoryRepository implements CategoryRepository {
  final DashboardLocalDataSource _localDataSource;
  final DashboardRemoteDataSource _remoteDataSource;

  LocalFirstCategoryRepository(this._localDataSource, this._remoteDataSource);

  Future<void> initializeSync(String userId) async {
    final syncKey = 'has_completed_initial_category_sync_$userId';
    final hasSynced = await _localDataSource.getBool(syncKey) ?? false;

    if (!hasSynced) {
      try {
        print('Starting one-time custom categories migration from Firestore...');
        final snapshotData = await _remoteDataSource.getCategories(userId);

        if (snapshotData.isNotEmpty) {
          final categories = snapshotData
              .map((data) => CategoryModel.fromMap(data))
              .toList();
          
          await _localDataSource.saveCategoriesBatch(userId, categories);
        }
        await _localDataSource.setBool(syncKey, true);
        print('Custom categories migration successfully completed.');
      } catch (e) {
        print('Failed to perform initial categories sync: $e');
      }
    }
  }

  @override
  Future<List<CategoryModel>> getCategories(String userId) async {
    await initializeSync(userId);
    return await _localDataSource.getCategories(userId);
  }

  @override
  Future<void> saveCategory(String userId, CategoryModel category) async {
    await _localDataSource.saveCategory(userId, category);
    _remoteDataSource.saveCategory(userId, category.id, category.toMap()).catchError((e) {
      print('Error syncing category write to Firestore: $e');
    });
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    await _localDataSource.deleteCategory(userId, categoryId);
    _remoteDataSource.deleteCategory(userId, categoryId).catchError((e) {
      print('Error syncing category delete to Firestore: $e');
    });
  }
}
