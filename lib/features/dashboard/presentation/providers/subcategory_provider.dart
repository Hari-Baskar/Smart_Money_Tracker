import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/local_first_subcategory_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/subcategory_repository.dart';
import 'package:smart_money_tracker/features/dashboard/data/repositories/local_first_category_repository.dart';
import 'package:smart_money_tracker/features/dashboard/domain/repositories/category_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

// ── Category Repository & Provider ───────────────────────────────────────────
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return LocalFirstCategoryRepository(FirebaseFirestore.instance);
});

final categoriesProvider = AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(() {
  return CategoryNotifier();
});

class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return [];

    final custom = await ref.read(categoryRepositoryProvider).getCategories(userId);
    return [..._defaultCategories, ...custom];
  }

  static final List<CategoryModel> _defaultCategories = [
    CategoryModel(id: 'Food', name: 'Food'),
    CategoryModel(id: 'Travel', name: 'Travel'),
    CategoryModel(id: 'Shopping', name: 'Shopping'),
    CategoryModel(id: 'Bills', name: 'Bills'),
    CategoryModel(id: 'Entertainment', name: 'Entertainment'),
    CategoryModel(id: 'Health', name: 'Health'),
    CategoryModel(id: 'Investment', name: 'Investment'),
    CategoryModel(id: 'Other', name: 'Other'),
    CategoryModel(id: 'Salary', name: 'Salary', isIncome: true),
  ];

  Future<void> addCategory(String name, {bool isIncome = false}) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final cat = CategoryModel(
      id: 'cat_${const Uuid().v4()}',
      name: name,
      isCustom: true,
      isIncome: isIncome,
    );

    await ref.read(categoryRepositoryProvider).saveCategory(userId, cat);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    // Delete custom subcategories under this category
    final subsAsync = ref.read(subcategoriesProvider);
    final subs = subsAsync.value ?? [];
    final toDelete = subs.where((s) => s.parentCategoryId == id && s.isCustom).toList();
    for (final sub in toDelete) {
      await ref.read(subcategoryRepositoryProvider).deleteSubcategory(userId, sub.id);
    }

    await ref.read(categoryRepositoryProvider).deleteCategory(userId, id);
    ref.invalidateSelf();
    ref.invalidate(subcategoriesProvider);
  }

  Future<void> updateCategory(String id, String newName) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(categoryRepositoryProvider);
    final custom = await repo.getCategories(userId);
    final matchIndex = custom.indexWhere((cat) => cat.id == id);
    if (matchIndex != -1) {
      final cat = custom[matchIndex];
      final updated = CategoryModel(
        id: cat.id,
        name: newName,
        isCustom: cat.isCustom,
        isIncome: cat.isIncome,
      );
      await repo.saveCategory(userId, updated);
      ref.invalidateSelf();
    }
  }
}

// ── Subcategory Repository & Provider ────────────────────────────────────────
final subcategoryRepositoryProvider = Provider<SubcategoryRepository>((ref) {
  return LocalFirstSubcategoryRepository(FirebaseFirestore.instance);
});

final subcategoriesProvider = AsyncNotifierProvider<SubcategoryNotifier, List<SubcategoryModel>>(() {
  return SubcategoryNotifier();
});

class SubcategoryNotifier extends AsyncNotifier<List<SubcategoryModel>> {
  @override
  Future<List<SubcategoryModel>> build() async {
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return [];

    final custom = await ref.read(subcategoryRepositoryProvider).getSubcategories(userId);
    return [..._defaultSubcategories, ...custom];
  }

  static final List<SubcategoryModel> _defaultSubcategories = [
    // Food
    SubcategoryModel(id: 'f1', name: 'Restaurant', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f2', name: 'Snacks', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f3', name: 'Groceries', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f4', name: 'Drinks', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f5', name: 'Delivery', parentCategoryId: 'Food'),
    // Travel
    SubcategoryModel(id: 't1', name: 'Fuel', parentCategoryId: 'Travel'),
    SubcategoryModel(id: 't2', name: 'Taxi/Uber', parentCategoryId: 'Travel'),
    SubcategoryModel(id: 't3', name: 'Parking', parentCategoryId: 'Travel'),
    SubcategoryModel(id: 't4', name: 'Bus/Train', parentCategoryId: 'Travel'),
    // Shopping
    SubcategoryModel(id: 's1', name: 'Clothing', parentCategoryId: 'Shopping'),
    SubcategoryModel(id: 's2', name: 'Electronics', parentCategoryId: 'Shopping'),
    SubcategoryModel(id: 's3', name: 'Home', parentCategoryId: 'Shopping'),
    SubcategoryModel(id: 's4', name: 'Gifts', parentCategoryId: 'Shopping'),
    // Bills
    SubcategoryModel(id: 'b1', name: 'Rent', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b2', name: 'Electricity', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b3', name: 'Internet', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b4', name: 'Mobile', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b5', name: 'Insurance', parentCategoryId: 'Bills'),
    // Entertainment
    SubcategoryModel(id: 'e1', name: 'Movies', parentCategoryId: 'Entertainment'),
    SubcategoryModel(id: 'e2', name: 'Games', parentCategoryId: 'Entertainment'),
    SubcategoryModel(id: 'e3', name: 'Streaming', parentCategoryId: 'Entertainment'),
    // Health
    SubcategoryModel(id: 'h1', name: 'Doctor', parentCategoryId: 'Health'),
    SubcategoryModel(id: 'h2', name: 'Pharmacy', parentCategoryId: 'Health'),
    SubcategoryModel(id: 'h3', name: 'Fitness', parentCategoryId: 'Health'),
    // Investment
    SubcategoryModel(id: 'i1', name: 'Stocks', parentCategoryId: 'Investment'),
    SubcategoryModel(id: 'i2', name: 'Mutual Funds', parentCategoryId: 'Investment'),
    SubcategoryModel(id: 'i3', name: 'Gold', parentCategoryId: 'Investment'),
    // Other
    SubcategoryModel(id: 'o1', name: 'General', parentCategoryId: 'Other'),
    SubcategoryModel(id: 'o2', name: 'Maintenance', parentCategoryId: 'Other'),
    SubcategoryModel(id: 'o3', name: 'Services', parentCategoryId: 'Other'),
    // Salary (Income)
    SubcategoryModel(id: 'sal1', name: 'General', parentCategoryId: 'Salary', isIncome: true),
  ];

  Future<void> addSubcategory(String name, String parentCategoryId, {bool isIncome = false}) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final sub = SubcategoryModel(
      id: 'sub_${const Uuid().v4()}',
      name: name,
      parentCategoryId: parentCategoryId,
      isCustom: true,
      isIncome: isIncome,
    );

    await ref.read(subcategoryRepositoryProvider).saveSubcategory(userId, sub);
    ref.invalidateSelf();
  }

  Future<void> deleteSubcategory(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    await ref.read(subcategoryRepositoryProvider).deleteSubcategory(userId, id);
    ref.invalidateSelf();
  }

  Future<void> updateSubcategory(String id, String newName) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(subcategoryRepositoryProvider);
    final custom = await repo.getSubcategories(userId);
    final matchIndex = custom.indexWhere((sub) => sub.id == id);
    if (matchIndex != -1) {
      final sub = custom[matchIndex];
      final updated = SubcategoryModel(
        id: sub.id,
        name: newName,
        parentCategoryId: sub.parentCategoryId,
        isCustom: sub.isCustom,
        isIncome: sub.isIncome,
      );
      await repo.saveSubcategory(userId, updated);
      ref.invalidateSelf();
    }
  }
}
