import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/local_first_custom_asset_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/custom_asset_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../notifiers/custom_asset_notifier.dart';

import 'datasource_provider.dart';

final customAssetRepositoryProvider = Provider<CustomAssetRepository>((ref) {
  final local = ref.watch(dashboardLocalDataSourceProvider);
  final remote = ref.watch(dashboardRemoteDataSourceProvider);
  return LocalFirstCustomAssetRepository(local, remote);
});

final customAssetsProvider = AsyncNotifierProvider<CustomAssetNotifier, List<CustomAssetModel>>(() {
  return CustomAssetNotifier();
});
