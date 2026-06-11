import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import '../providers/subcategory_provider.dart';

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

  Future<CategoryModel> addCategory(String name, {bool isIncome = false}) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return CategoryModel(id: 'cat_${const Uuid().v4()}', name: name, isCustom: true, isIncome: isIncome);

    final cat = CategoryModel(
      id: 'cat_${const Uuid().v4()}',
      name: name,
      isCustom: true,
      isIncome: isIncome,
    );

    await ref.read(categoryRepositoryProvider).saveCategory(userId, cat);
    ref.invalidateSelf();
    return cat;
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
        isArchived: cat.isArchived,
      );
      await repo.saveCategory(userId, updated);
      ref.invalidateSelf();
    }
  }

  Future<void> archiveCategory(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(categoryRepositoryProvider);
    final custom = await repo.getCategories(userId);
    final matchIndex = custom.indexWhere((cat) => cat.id == id);
    if (matchIndex != -1) {
      final cat = custom[matchIndex];
      final archived = CategoryModel(
        id: cat.id,
        name: cat.name,
        isCustom: cat.isCustom,
        isIncome: cat.isIncome,
        isArchived: true,
      );
      await repo.saveCategory(userId, archived);
      ref.invalidateSelf();
    }
  }

  Future<void> unarchiveCategory(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(categoryRepositoryProvider);
    final custom = await repo.getCategories(userId);
    final matchIndex = custom.indexWhere((cat) => cat.id == id);
    if (matchIndex != -1) {
      final cat = custom[matchIndex];
      final unarchived = CategoryModel(
        id: cat.id,
        name: cat.name,
        isCustom: cat.isCustom,
        isIncome: cat.isIncome,
        isArchived: false,
      );
      await repo.saveCategory(userId, unarchived);
      ref.invalidateSelf();
    }
  }
}
