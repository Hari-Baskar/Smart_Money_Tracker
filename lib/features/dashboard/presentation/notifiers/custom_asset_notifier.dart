import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import '../providers/custom_asset_provider.dart';

class CustomAssetNotifier extends AsyncNotifier<List<CustomAssetModel>> {
  @override
  Future<List<CustomAssetModel>> build() async {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return [];

    return await ref.read(customAssetRepositoryProvider).getCustomAssets(userId);
  }

  Future<String> addCustomAsset(String name, String type) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return '';

    final prefix = type == 'bank' ? 'cb_' : 'cpm_';
    final id = '$prefix${const Uuid().v4()}';
    final asset = CustomAssetModel(
      id: id,
      name: name,
      type: type,
    );

    await ref.read(customAssetRepositoryProvider).saveCustomAsset(userId, asset);
    ref.invalidateSelf();
    return id;
  }

  Future<void> deleteCustomAsset(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    await ref.read(customAssetRepositoryProvider).deleteCustomAsset(userId, id);
    ref.invalidateSelf();
  }

  Future<void> renameCustomAsset(String id, String newName) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(customAssetRepositoryProvider);
    final assets = await repo.getCustomAssets(userId);
    final index = assets.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updated = CustomAssetModel(
        id: id,
        name: newName,
        type: assets[index].type,
        isArchived: assets[index].isArchived,
      );
      await repo.saveCustomAsset(userId, updated);
      ref.invalidateSelf();
    }
  }

  Future<void> archiveCustomAsset(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(customAssetRepositoryProvider);
    final assets = await repo.getCustomAssets(userId);
    final index = assets.indexWhere((a) => a.id == id);
    if (index != -1) {
      final archived = CustomAssetModel(
        id: id,
        name: assets[index].name,
        type: assets[index].type,
        isArchived: true,
      );
      await repo.saveCustomAsset(userId, archived);
      ref.invalidateSelf();
    }
  }

  Future<void> unarchiveCustomAsset(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(customAssetRepositoryProvider);
    final assets = await repo.getCustomAssets(userId);
    final index = assets.indexWhere((a) => a.id == id);
    if (index != -1) {
      final unarchived = CustomAssetModel(
        id: id,
        name: assets[index].name,
        type: assets[index].type,
        isArchived: false,
      );
      await repo.saveCustomAsset(userId, unarchived);
      ref.invalidateSelf();
    }
  }
}
