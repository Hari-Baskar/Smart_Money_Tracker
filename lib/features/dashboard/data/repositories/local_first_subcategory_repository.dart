import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/services/local_database_helper.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/subcategory_repository.dart';

class LocalFirstSubcategoryRepository implements SubcategoryRepository {
  final FirebaseFirestore _firestore;
  final LocalDatabaseHelper _dbHelper = LocalDatabaseHelper.instance;

  LocalFirstSubcategoryRepository(this._firestore);

  // One-time initialization/migration of subcategories from Firestore to SQLite
  Future<void> initializeSync(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final syncKey = 'has_completed_initial_subcategory_sync_$userId';
    final hasSynced = prefs.getBool(syncKey) ?? false;

    if (!hasSynced) {
      try {
        print('Starting one-time custom subcategories migration from Firestore...');
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('subcategories')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final subcategories = snapshot.docs
              .map((doc) => SubcategoryModel.fromMap(doc.data()))
              .toList();
          
          await _dbHelper.saveSubcategoriesBatch(userId, subcategories);
        }
        await prefs.setBool(syncKey, true);
        print('Custom subcategories migration successfully completed.');
      } catch (e) {
        print('Failed to perform initial subcategories sync: $e');
      }
    }
  }

  @override
  Future<List<SubcategoryModel>> getSubcategories(String userId) async {
    await initializeSync(userId);
    return await _dbHelper.getSubcategories(userId);
  }

  @override
  Future<void> saveSubcategory(String userId, SubcategoryModel subcategory) async {
    // 1. Save to SQLite database locally
    await _dbHelper.saveSubcategory(userId, subcategory);

    // 2. Sync to Firestore in the background
    _firestore
        .collection('users')
        .doc(userId)
        .collection('subcategories')
        .doc(subcategory.id)
        .set(subcategory.toMap())
        .catchError((e) {
          print('Error syncing subcategory write to Firestore: $e');
        });
  }

  @override
  Future<void> deleteSubcategory(String userId, String subcategoryId) async {
    // 1. Delete from SQLite database locally
    await _dbHelper.deleteSubcategory(userId, subcategoryId);

    // 2. Sync delete to Firestore in the background
    _firestore
        .collection('users')
        .doc(userId)
        .collection('subcategories')
        .doc(subcategoryId)
        .delete()
        .catchError((e) {
          print('Error syncing subcategory delete to Firestore: $e');
        });
  }
}
