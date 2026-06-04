import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/core/services/local_database_helper.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/custom_asset_repository.dart';

class LocalFirstCustomAssetRepository implements CustomAssetRepository {
  final FirebaseFirestore _firestore;
  final LocalDatabaseHelper _dbHelper = LocalDatabaseHelper.instance;

  LocalFirstCustomAssetRepository(this._firestore);

  Future<void> initializeSync(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final syncKey = 'has_completed_initial_custom_asset_sync_$userId';
    final hasSynced = prefs.getBool(syncKey) ?? false;

    if (!hasSynced) {
      try {
        print('Starting one-time custom assets migration from Firestore...');
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('custom_assets')
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final asset = CustomAssetModel.fromMap(doc.data());
            await _dbHelper.saveCustomAsset(userId, asset);
          }
        }
        await prefs.setBool(syncKey, true);
        print('Custom assets migration successfully completed.');
      } catch (e) {
        print('Failed to perform initial custom assets sync: $e');
      }
    }
  }

  @override
  Future<List<CustomAssetModel>> getCustomAssets(String userId) async {
    await initializeSync(userId);
    return await _dbHelper.getCustomAssets(userId);
  }

  @override
  Future<void> saveCustomAsset(String userId, CustomAssetModel asset) async {
    await _dbHelper.saveCustomAsset(userId, asset);
    _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_assets')
        .doc(asset.id)
        .set(asset.toMap())
        .catchError((e) {
          print('Error syncing custom asset write to Firestore: $e');
        });
  }

  @override
  Future<void> deleteCustomAsset(String userId, String id) async {
    await _dbHelper.deleteCustomAsset(userId, id);
    _firestore
        .collection('users')
        .doc(userId)
        .collection('custom_assets')
        .doc(id)
        .delete()
        .catchError((e) {
          print('Error syncing custom asset delete to Firestore: $e');
        });
  }
}
