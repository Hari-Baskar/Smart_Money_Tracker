import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import '../providers/subcategory_provider.dart';

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
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f1', name: 'Restaurant', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f2', name: 'Snacks', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f3', name: 'Groceries', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f4', name: 'Drinks', parentCategoryId: 'Food'),
    SubcategoryModel(id: 'f5', name: 'Delivery', parentCategoryId: 'Food'),
    // Travel
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Travel'),
    SubcategoryModel(id: 't1', name: 'Fuel', parentCategoryId: 'Travel'),
    SubcategoryModel(id: 't2', name: 'Taxi/Uber', parentCategoryId: 'Travel'),
    SubcategoryModel(id: 't3', name: 'Parking', parentCategoryId: 'Travel'),
    SubcategoryModel(id: 't4', name: 'Bus/Train', parentCategoryId: 'Travel'),
    // Shopping
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Shopping'),
    SubcategoryModel(id: 's1', name: 'Clothing', parentCategoryId: 'Shopping'),
    SubcategoryModel(id: 's2', name: 'Electronics', parentCategoryId: 'Shopping'),
    SubcategoryModel(id: 's3', name: 'Home', parentCategoryId: 'Shopping'),
    SubcategoryModel(id: 's4', name: 'Gifts', parentCategoryId: 'Shopping'),
    // Bills
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b1', name: 'Rent', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b2', name: 'Electricity', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b3', name: 'Internet', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b4', name: 'Mobile', parentCategoryId: 'Bills'),
    SubcategoryModel(id: 'b5', name: 'Insurance', parentCategoryId: 'Bills'),
    // Entertainment
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Entertainment'),
    SubcategoryModel(id: 'e1', name: 'Movies', parentCategoryId: 'Entertainment'),
    SubcategoryModel(id: 'e2', name: 'Games', parentCategoryId: 'Entertainment'),
    SubcategoryModel(id: 'e3', name: 'Streaming', parentCategoryId: 'Entertainment'),
    // Health
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Health'),
    SubcategoryModel(id: 'h1', name: 'Doctor', parentCategoryId: 'Health'),
    SubcategoryModel(id: 'h2', name: 'Pharmacy', parentCategoryId: 'Health'),
    SubcategoryModel(id: 'h3', name: 'Fitness', parentCategoryId: 'Health'),
    // Investment
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Investment'),
    SubcategoryModel(id: 'i1', name: 'Stocks', parentCategoryId: 'Investment'),
    SubcategoryModel(id: 'i2', name: 'Mutual Funds', parentCategoryId: 'Investment'),
    SubcategoryModel(id: 'i3', name: 'Gold', parentCategoryId: 'Investment'),
    // Other
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Other'),
    SubcategoryModel(id: 'o2', name: 'Maintenance', parentCategoryId: 'Other'),
    SubcategoryModel(id: 'o3', name: 'Services', parentCategoryId: 'Other'),
    // Salary (Income)
    SubcategoryModel(id: 'General', name: 'General', parentCategoryId: 'Salary', isIncome: true),
  ];

  Future<SubcategoryModel> addSubcategory(String name, String parentCategoryId, {bool isIncome = false}) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    final sub = SubcategoryModel(
      id: 'sub_${const Uuid().v4()}',
      name: name,
      parentCategoryId: parentCategoryId,
      isCustom: true,
      isIncome: isIncome,
    );
    if (userId == null) return sub;

    await ref.read(subcategoryRepositoryProvider).saveSubcategory(userId, sub);
    ref.invalidateSelf();
    return sub;
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
        isArchived: sub.isArchived,
      );
      await repo.saveSubcategory(userId, updated);
      ref.invalidateSelf();
    }
  }

  Future<void> archiveSubcategory(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(subcategoryRepositoryProvider);
    final custom = await repo.getSubcategories(userId);
    final matchIndex = custom.indexWhere((sub) => sub.id == id);
    if (matchIndex != -1) {
      final sub = custom[matchIndex];
      final archived = SubcategoryModel(
        id: sub.id,
        name: sub.name,
        parentCategoryId: sub.parentCategoryId,
        isCustom: sub.isCustom,
        isIncome: sub.isIncome,
        isArchived: true,
      );
      await repo.saveSubcategory(userId, archived);
      ref.invalidateSelf();
    }
  }

  Future<void> unarchiveSubcategory(String id) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.id;
    if (userId == null) return;

    final repo = ref.read(subcategoryRepositoryProvider);
    final custom = await repo.getSubcategories(userId);
    final matchIndex = custom.indexWhere((s) => s.id == id);
    if (matchIndex != -1) {
      final sub = custom[matchIndex];
      final unarchived = SubcategoryModel(
        id: sub.id,
        name: sub.name,
        parentCategoryId: sub.parentCategoryId,
        isCustom: sub.isCustom,
        isIncome: sub.isIncome,
        isArchived: false,
      );
      await repo.saveSubcategory(userId, unarchived);
      ref.invalidateSelf();
    }
  }
}
