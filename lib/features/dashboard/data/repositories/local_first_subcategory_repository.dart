import 'dart:async';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/subcategory_repository.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../datasources/dashboard_remote_data_source.dart';

class LocalFirstSubcategoryRepository implements SubcategoryRepository {
  final DashboardLocalDataSource _localDataSource;
  final DashboardRemoteDataSource _remoteDataSource;

  LocalFirstSubcategoryRepository(this._localDataSource, this._remoteDataSource);

  // One-time initialization/migration of subcategories from Firestore to SQLite
  Future<void> initializeSync(String userId) async {
    final syncKey = 'has_completed_initial_subcategory_sync_$userId';
    final hasSynced = await _localDataSource.getBool(syncKey) ?? false;

    if (!hasSynced) {
      try {
        print('Starting one-time custom subcategories migration from Firestore...');
        final snapshotData = await _remoteDataSource.getSubcategories(userId);

        if (snapshotData.isNotEmpty) {
          final subcategories = snapshotData
              .map((data) => SubcategoryModel.fromMap(data))
              .toList();
          
          await _localDataSource.saveSubcategoriesBatch(userId, subcategories);
        }
        await _localDataSource.setBool(syncKey, true);
        print('Custom subcategories migration successfully completed.');
      } catch (e) {
        print('Failed to perform initial subcategories sync: $e');
      }
    }
  }

  @override
  Future<List<SubcategoryModel>> getSubcategories(String userId) async {
    await initializeSync(userId);
    return await _localDataSource.getSubcategories(userId);
  }

  @override
  Future<void> saveSubcategory(String userId, SubcategoryModel subcategory) async {
    // 1. Save to SQLite database locally
    await _localDataSource.saveSubcategory(userId, subcategory);

    // 2. Sync to Firestore in the background
    _remoteDataSource.saveSubcategory(userId, subcategory.id, subcategory.toMap()).catchError((e) {
      print('Error syncing subcategory write to Firestore: $e');
    });
  }

  @override
  Future<void> deleteSubcategory(String userId, String subcategoryId) async {
    // 1. Delete from SQLite database locally
    await _localDataSource.deleteSubcategory(userId, subcategoryId);

    // 2. Sync delete to Firestore in the background
    _remoteDataSource.deleteSubcategory(userId, subcategoryId).catchError((e) {
      print('Error syncing subcategory delete to Firestore: $e');
    });
  }
}
