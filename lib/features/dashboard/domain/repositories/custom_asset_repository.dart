import 'package:smart_money_tracker/core/models/custom_asset_model.dart';

abstract class CustomAssetRepository {
  Future<List<CustomAssetModel>> getCustomAssets(String userId);
  Future<void> saveCustomAsset(String userId, CustomAssetModel asset);
  Future<void> deleteCustomAsset(String userId, String id);
}
