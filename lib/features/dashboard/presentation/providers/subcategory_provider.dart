import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/category_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/subcategory_repository.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/local_first_category_repository.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/local_first_subcategory_repository.dart';
import '../notifiers/category_notifier.dart';
import '../notifiers/subcategory_notifier.dart';
import 'datasource_provider.dart';

// ── Category Repository & Provider ───────────────────────────────────────────
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final local = ref.watch(dashboardLocalDataSourceProvider);
  final remote = ref.watch(dashboardRemoteDataSourceProvider);
  return LocalFirstCategoryRepository(local, remote);
});

final categoriesProvider =
    AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(() {
      return CategoryNotifier();
    });

// ── Subcategory Repository & Provider ────────────────────────────────────────
final subcategoryRepositoryProvider = Provider<SubcategoryRepository>((ref) {
  final local = ref.watch(dashboardLocalDataSourceProvider);
  final remote = ref.watch(dashboardRemoteDataSourceProvider);
  return LocalFirstSubcategoryRepository(local, remote);
});

final subcategoriesProvider =
    AsyncNotifierProvider<SubcategoryNotifier, List<SubcategoryModel>>(() {
      return SubcategoryNotifier();
    });
