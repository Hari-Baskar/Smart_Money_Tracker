import 'dart:async';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/custom_asset_repository.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../datasources/dashboard_remote_data_source.dart';

class LocalFirstCustomAssetRepository implements CustomAssetRepository {
  final DashboardLocalDataSource _localDataSource;
  final DashboardRemoteDataSource _remoteDataSource;

  LocalFirstCustomAssetRepository(this._localDataSource, this._remoteDataSource);

  Future<void> initializeSync(String userId) async {
    final syncKey = 'has_completed_initial_custom_asset_sync_$userId';
    final hasSynced = await _localDataSource.getBool(syncKey) ?? false;

    if (!hasSynced) {
      try {
        print('Starting one-time custom assets migration from Firestore...');
        final snapshotData = await _remoteDataSource.getCustomAssets(userId);

        if (snapshotData.isNotEmpty) {
          for (final data in snapshotData) {
            final asset = CustomAssetModel.fromMap(data);
            await _localDataSource.saveCustomAsset(userId, asset);
          }
        }
        await _localDataSource.setBool(syncKey, true);
        print('Custom assets migration successfully completed.');
      } catch (e) {
        print('Failed to perform initial custom assets sync: $e');
      }
    }
  }

  @override
  Future<List<CustomAssetModel>> getCustomAssets(String userId) async {
    await initializeSync(userId);
    return await _localDataSource.getCustomAssets(userId);
  }

  @override
  Future<void> saveCustomAsset(String userId, CustomAssetModel asset) async {
    await _localDataSource.saveCustomAsset(userId, asset);
    _remoteDataSource.saveCustomAsset(userId, asset.id, asset.toMap()).catchError((e) {
      print('Error syncing custom asset write to Firestore: $e');
    });
  }

  @override
  Future<void> deleteCustomAsset(String userId, String id) async {
    await _localDataSource.deleteCustomAsset(userId, id);
    _remoteDataSource.deleteCustomAsset(userId, id).catchError((e) {
      print('Error syncing custom asset delete to Firestore: $e');
    });
  }
}
