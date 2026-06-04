import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/local_first_custom_asset_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/custom_asset_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

final customAssetRepositoryProvider = Provider<CustomAssetRepository>((ref) {
  return LocalFirstCustomAssetRepository(FirebaseFirestore.instance);
});

final customAssetsProvider = AsyncNotifierProvider<CustomAssetNotifier, List<CustomAssetModel>>(() {
  return CustomAssetNotifier();
});

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
      );
      await repo.saveCustomAsset(userId, updated);
      ref.invalidateSelf();
    }
  }
}
